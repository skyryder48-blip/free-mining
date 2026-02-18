-----------------------------------------------------------
-- HAZARD MANAGEMENT (Server)
-- Rolls hazards after mining extractions, manages cave-in,
-- gas leak, and rockslide events, tracks wooden support
-- placements.
-----------------------------------------------------------

local DB = require 'server.database'

-----------------------------------------------------------
-- STATE
-----------------------------------------------------------

-- Active hazard events per sub-zone: activeHazards[subZoneName] = { type, startTime, ... }
local activeHazards = {}

-- Wooden support timers: supports[subZoneName] = expiresAt (os.time)
local supports = {}

-----------------------------------------------------------
-- HELPERS
-----------------------------------------------------------

--- Finds a sub-zone config by name.
---@param subZoneName string
---@return table|nil subZone
local function findSubZone(subZoneName)
    for _, zoneData in pairs(Config.Zones) do
        for _, sz in ipairs(zoneData.subZones) do
            if sz.name == subZoneName then
                return sz
            end
        end
    end
    return nil
end

--- Rolls a hazard type from a weighted types table.
---@param types table<string, number>
---@return string hazardType
local function rollHazardType(types)
    local total = 0
    for _, weight in pairs(types) do
        total = total + weight
    end

    local roll = math.random(1, total)
    local cumulative = 0
    for hazardType, weight in pairs(types) do
        cumulative = cumulative + weight
        if roll <= cumulative then
            return hazardType
        end
    end

    -- Fallback: first type
    for t in pairs(types) do return t end
end

--- Checks if a wooden support is active in a sub-zone.
---@param subZoneName string
---@return boolean
local function hasSupportActive(subZoneName)
    local expiresAt = supports[subZoneName]
    if not expiresAt then return false end
    if os.time() >= expiresAt then
        supports[subZoneName] = nil
        return false
    end
    return true
end

--- Safely updates specific metadata fields without overwriting existing ones.
---@param src number
---@param slotNum number
---@param existingMeta table
---@param updates table
local function updateMetadata(src, slotNum, existingMeta, updates)
    local meta = {}
    if existingMeta then
        for k, v in pairs(existingMeta) do
            meta[k] = v
        end
    end
    for k, v in pairs(updates) do
        meta[k] = v
    end
    exports.ox_inventory:SetMetadata(src, slotNum, meta)
end

-----------------------------------------------------------
-- GLOBAL STATE ACCESS (used by explosives.lua)
-----------------------------------------------------------

--- Checks if a gas leak is currently active in a sub-zone.
---@param subZoneName string
---@return boolean
function IsGasLeakActive(subZoneName)
    local hazard = activeHazards[subZoneName]
    return hazard ~= nil and hazard.type == 'gas_leak'
end

--- Clears an active gas leak in a sub-zone (called by gas explosions).
---@param subZoneName string
function ClearGasLeak(subZoneName)
    local hazard = activeHazards[subZoneName]
    if hazard and hazard.type == 'gas_leak' then
        activeHazards[subZoneName] = nil
        TriggerClientEvent('mining:client:gasLeakEnd', -1, subZoneName)
    end
end

-----------------------------------------------------------
-- HAZARD ROLL (called after extraction)
-----------------------------------------------------------

--- Rolls whether a hazard triggers for the given sub-zone.
--- Returns the hazard type if triggered, nil otherwise.
---@param subZoneName string
---@return string|nil hazardType
function RollHazard(subZoneName)
    -- Don't trigger if a hazard is already active in this zone
    if activeHazards[subZoneName] then return nil end

    local subZone = findSubZone(subZoneName)
    if not subZone then return nil end

    local hazardWeight = subZone.hazardWeight or 1.0
    local hazardMul = GetMultiplier and GetMultiplier('hazardRate') or 1.0
    local chance = Config.Hazards.baseChance * hazardWeight * hazardMul

    local roll = math.random(1, 100)
    if roll > chance then return nil end

    -- Determine hazard table based on zone type (quarry vs underground)
    local zoneName = FindZoneKey(subZoneName)
    local hazardTypes = Config.Hazards.types
    if zoneName == 'quarry' and Config.Hazards.quarryTypes then
        hazardTypes = Config.Hazards.quarryTypes
    end

    -- Roll which hazard type
    local hazardType = rollHazardType(hazardTypes)

    -- Wooden support only reduces cave-in chance (re-roll if cave-in is blocked)
    if hazardType == 'cave_in' and hasSupportActive(subZoneName) then
        -- Support gives a chance to prevent the cave-in
        local supportRoll = math.random()
        if supportRoll < Config.CaveIn.supportReduction then
            return nil -- support prevented the cave-in
        end
    end

    return hazardType
end

-----------------------------------------------------------
-- CAVE-IN EVENT
-----------------------------------------------------------

--- Triggers a cave-in event in a sub-zone.
---@param subZoneName string
function TriggerCaveIn(subZoneName)
    if activeHazards[subZoneName] then return end

    local subZone = findSubZone(subZoneName)
    if not subZone or not subZone.spawnArea then return end

    activeHazards[subZoneName] = {
        type = 'cave_in',
        startTime = os.time(),
        minedBoulders = {}, -- tracks which boulder indices have been mined
    }

    -- Generate random boulder positions within the spawn area
    local boulderPositions = {}
    local center = vec3(
        (subZone.spawnArea.min.x + subZone.spawnArea.max.x) / 2,
        (subZone.spawnArea.min.y + subZone.spawnArea.max.y) / 2,
        subZone.spawnArea.min.z
    )
    local spread = Config.CaveIn.boulderSpreadRadius

    for i = 1, Config.CaveIn.boulderCount do
        local angle = (i / Config.CaveIn.boulderCount) * math.pi * 2
        boulderPositions[i] = {
            x = center.x + math.cos(angle) * spread * (0.5 + math.random() * 0.5),
            y = center.y + math.sin(angle) * spread * (0.5 + math.random() * 0.5),
            z = center.z,
        }
    end

    -- Roll ore type for each boulder (some may yield ore)
    local boulderOres = {}
    for i = 1, Config.CaveIn.boulderCount do
        if math.random(1, 100) <= Config.CaveIn.boulderOreChance then
            local total = 0
            for _, w in pairs(subZone.oreDistribution) do total = total + w end
            local r = math.random(1, total)
            local cum = 0
            for oreType, w in pairs(subZone.oreDistribution) do
                cum = cum + w
                if r <= cum then
                    boulderOres[i] = oreType
                    break
                end
            end
        end
    end

    -- Send warning phase to all clients
    TriggerClientEvent('mining:client:caveInWarning', -1, subZoneName)

    -- After warning, trigger the main collapse
    SetTimeout(Config.CaveIn.warningDuration, function()
        if not activeHazards[subZoneName] then return end

        TriggerClientEvent('mining:client:caveInCollapse', -1, subZoneName, boulderPositions, boulderOres)

        -- Clear event after collapse duration
        SetTimeout(Config.CaveIn.collapseDuration, function()
            activeHazards[subZoneName] = nil
            TriggerClientEvent('mining:client:caveInEnd', -1, subZoneName)
        end)
    end)
end

-----------------------------------------------------------
-- BOULDER MINING CALLBACK
-----------------------------------------------------------

--- Server callback for mining a cave-in boulder.
lib.callback.register('mining:server:mineBoulder', function(src, data)
    -- data: { subZoneName, boulderIndex, oreType }
    if not checkCooldown(src, 'mining') then
        return { success = false, reason = 'Too fast' }
    end

    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    -- Verify a cave-in is active
    local hazard = activeHazards[data.subZoneName]
    if not hazard or hazard.type ~= 'cave_in' then
        return { success = false, reason = 'No active cave-in' }
    end

    -- Prevent double-mining the same boulder
    if hazard.minedBoulders[data.boulderIndex] then
        return { success = false, reason = 'Already mined' }
    end
    hazard.minedBoulders[data.boulderIndex] = true

    -- Stone yield (check inventory space, track actual amount given)
    local stoneAmount = math.random(Config.CaveIn.boulderStoneYield.min, Config.CaveIn.boulderStoneYield.max)
    local actualStone = 0
    if exports.ox_inventory:CanCarryItem(src, 'stone', stoneAmount) then
        exports.ox_inventory:AddItem(src, 'stone', stoneAmount)
        actualStone = stoneAmount
    end

    -- Possible ore yield
    local oreType = data.oreType
    local oreAmount = 0
    local oreLabel = nil
    if oreType and Config.Ores[oreType] then
        oreLabel = Config.Ores[oreType].label
        if exports.ox_inventory:CanCarryItem(src, oreType, 1) then
            exports.ox_inventory:AddItem(src, oreType, 1)
            oreAmount = 1
        end
    end

    -- Award XP for hazard cleanup
    DB.AddMiningProgress(citizenId, 5, actualStone)

    return {
        success = true,
        stoneAmount = actualStone,
        oreType = oreType,
        oreLabel = oreLabel,
        oreAmount = oreAmount,
    }
end)

-----------------------------------------------------------
-- GAS LEAK EVENT
-----------------------------------------------------------

--- Triggers a gas leak event in a sub-zone.
---@param subZoneName string
function TriggerGasLeak(subZoneName)
    if activeHazards[subZoneName] then return end

    activeHazards[subZoneName] = {
        type = 'gas_leak',
        startTime = os.time(),
    }

    -- Send warning to clients
    TriggerClientEvent('mining:client:gasLeakWarning', -1, subZoneName)

    -- After warning, activate gas
    SetTimeout(Config.GasLeak.warningDuration, function()
        if not activeHazards[subZoneName] then return end

        TriggerClientEvent('mining:client:gasLeakActive', -1, subZoneName)

        -- End gas after active duration
        SetTimeout(Config.GasLeak.activeDuration, function()
            activeHazards[subZoneName] = nil
            TriggerClientEvent('mining:client:gasLeakEnd', -1, subZoneName)
        end)
    end)
end

-----------------------------------------------------------
-- RESPIRATOR CHECK
-----------------------------------------------------------

--- Checks if a player has a working respirator and degrades it.
--- Called once per second during active gas. Drains 1 use per tick.
--- Returns true if protected.
---@param src number
---@return boolean
function CheckRespirator(src)
    local slots = exports.ox_inventory:Search(src, 'slots', 'respirator')
    if not slots then return false end

    for _, slot in ipairs(slots) do
        local uses = slot.metadata and slot.metadata.uses or 0
        if uses > 0 then
            -- Degrade respirator by 1 use per tick
            local newUses = math.max(0, uses - Config.GasLeak.respiratorDrainPerTick)
            local maxUses = Config.Equipment['respirator'].maxUses
            local newDurability = math.floor((newUses / maxUses) * 100 + 0.5)

            if newUses <= 0 then
                exports.ox_inventory:RemoveItem(src, 'respirator', 1, nil, slot.slot)
                TriggerClientEvent('mining:client:equipmentBroken', src, 'Respirator')
            else
                updateMetadata(src, slot.slot, slot.metadata, {
                    uses = newUses,
                    durability = newDurability,
                })
            end

            return true
        end
    end

    return false
end

--- Server callback for gas damage check — client calls this every second during gas.
lib.callback.register('mining:server:gasCheck', function(src, subZoneName)
    if not activeHazards[subZoneName] or activeHazards[subZoneName].type ~= 'gas_leak' then
        return { active = false }
    end

    local protected = CheckRespirator(src)
    return { active = true, protected = protected }
end)

-----------------------------------------------------------
-- ROCKSLIDE EVENT (Phase 4 - quarry hazard)
-----------------------------------------------------------

--- Triggers a rockslide event in a sub-zone.
---@param subZoneName string
function TriggerRockslide(subZoneName)
    if activeHazards[subZoneName] then return end

    local subZone = findSubZone(subZoneName)
    if not subZone or not subZone.spawnArea then return end

    activeHazards[subZoneName] = {
        type = 'rockslide',
        startTime = os.time(),
        minedDebris = {}, -- tracks which debris indices have been mined
    }

    -- Generate random debris positions within the spawn area
    local debrisPositions = {}
    local center = vec3(
        (subZone.spawnArea.min.x + subZone.spawnArea.max.x) / 2,
        (subZone.spawnArea.min.y + subZone.spawnArea.max.y) / 2,
        subZone.spawnArea.min.z
    )
    local spread = Config.Rockslide.debrisSpreadRadius

    for i = 1, Config.Rockslide.debrisCount do
        local angle = (i / Config.Rockslide.debrisCount) * math.pi * 2
        debrisPositions[i] = {
            x = center.x + math.cos(angle) * spread * (0.5 + math.random() * 0.5),
            y = center.y + math.sin(angle) * spread * (0.5 + math.random() * 0.5),
            z = center.z,
        }
    end

    -- Send warning phase to all clients
    TriggerClientEvent('mining:client:rockslideWarning', -1, subZoneName)

    -- After warning, trigger the slide
    SetTimeout(Config.Rockslide.warningDuration, function()
        if not activeHazards[subZoneName] then return end

        TriggerClientEvent('mining:client:rockslideCollapse', -1, subZoneName, debrisPositions)

        -- Clear event after slide duration
        SetTimeout(Config.Rockslide.slideDuration, function()
            activeHazards[subZoneName] = nil
            TriggerClientEvent('mining:client:rockslideEnd', -1, subZoneName)
        end)
    end)
end

-----------------------------------------------------------
-- ROCKSLIDE DEBRIS MINING CALLBACK
-----------------------------------------------------------

--- Server callback for mining rockslide debris.
lib.callback.register('mining:server:mineDebris', function(src, data)
    -- data: { subZoneName, debrisIndex }
    if not checkCooldown(src, 'mining') then
        return { success = false, reason = 'Too fast' }
    end

    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    -- Verify a rockslide is active
    local hazard = activeHazards[data.subZoneName]
    if not hazard or hazard.type ~= 'rockslide' then
        return { success = false, reason = 'No active rockslide' }
    end

    -- Prevent double-mining the same debris
    if hazard.minedDebris[data.debrisIndex] then
        return { success = false, reason = 'Already mined' }
    end
    hazard.minedDebris[data.debrisIndex] = true

    -- Stone yield
    local stoneAmount = math.random(Config.Rockslide.debrisStoneYield.min, Config.Rockslide.debrisStoneYield.max)
    local actualStone = 0
    if exports.ox_inventory:CanCarryItem(src, 'stone', stoneAmount) then
        exports.ox_inventory:AddItem(src, 'stone', stoneAmount)
        actualStone = stoneAmount
    end

    -- Award XP for hazard cleanup
    DB.AddMiningProgress(citizenId, 5, actualStone)

    return {
        success = true,
        stoneAmount = actualStone,
    }
end)

-----------------------------------------------------------
-- WOODEN SUPPORT PLACEMENT
-----------------------------------------------------------

--- Server callback for placing a wooden support.
lib.callback.register('mining:server:placeSupport', function(src, subZoneName)
    if not checkCooldown(src, 'mining') then
        return { success = false, reason = 'Too fast' }
    end

    -- Check player has wooden_support
    local count = exports.ox_inventory:Search(src, 'count', 'wooden_support')
    if not count or count < 1 then
        return { success = false, reason = 'No wooden supports' }
    end

    -- Remove the support item
    exports.ox_inventory:RemoveItem(src, 'wooden_support', 1)

    -- Activate support protection
    local duration = Config.CaveIn.supportDuration / 1000 -- convert ms to seconds
    supports[subZoneName] = os.time() + duration

    -- Notify players in the zone
    TriggerClientEvent('mining:client:supportPlaced', -1, subZoneName, Config.CaveIn.supportDuration)

    return {
        success = true,
        duration = Config.CaveIn.supportDuration,
    }
end)

-----------------------------------------------------------
-- WOODEN SUPPORT USABLE ITEM (server-side hook)
-----------------------------------------------------------

exports.ox_inventory:registerHook('usingItem', function(payload)
    if payload.item.name ~= 'wooden_support' then return true end

    local src = payload.source
    -- Trigger client-side placement flow (progress bar, then server callback)
    TriggerClientEvent('mining:client:placeSupport', src)
    return false -- don't consume yet; the server callback handles removal
end, { itemFilter = { wooden_support = true } })

-----------------------------------------------------------
-- HELMET BATTERY USAGE (server-side usable item hook)
-----------------------------------------------------------

exports.ox_inventory:registerHook('usingItem', function(payload)
    if payload.item.name ~= 'helmet_battery' then return true end

    local src = payload.source
    if not checkCooldown(src, 'helmetBattery') then
        TriggerClientEvent('mining:client:equipmentNotify', src, { success = false, reason = 'Too fast' })
        return false
    end

    -- Find mining_helmet with battery < max
    local helmetSlots = exports.ox_inventory:Search(src, 'slots', 'mining_helmet')
    local targetSlot = nil
    if helmetSlots then
        for _, slot in ipairs(helmetSlots) do
            local battery = slot.metadata and slot.metadata.battery or 0
            if battery < Config.Equipment['mining_helmet'].maxBattery then
                targetSlot = slot
                break
            end
        end
    end

    if not targetSlot then
        TriggerClientEvent('mining:client:equipmentNotify', src, { success = false, reason = 'No helmet that needs charging' })
        return false
    end

    -- Restore battery
    local maxBattery = Config.Equipment['mining_helmet'].maxBattery
    local newBattery = math.min(maxBattery, (targetSlot.metadata.battery or 0) + Config.Equipment['helmet_battery'].restoreAmount)
    local newDurability = math.floor((newBattery / maxBattery) * 100 + 0.5)

    updateMetadata(src, targetSlot.slot, targetSlot.metadata, {
        battery = newBattery,
        durability = newDurability,
    })

    TriggerClientEvent('mining:client:equipmentNotify', src, {
        success = true,
        message = ('Helmet charged to %d%%'):format(newDurability),
    })

    return true -- consume the battery
end, { itemFilter = { helmet_battery = true } })

-----------------------------------------------------------
-- HELMET BATTERY CHECK
-----------------------------------------------------------

--- Called by client to check/drain helmet battery.
lib.callback.register('mining:server:drainHelmetBattery', function(src, drainAmount)
    local slots = exports.ox_inventory:Search(src, 'slots', 'mining_helmet')
    if not slots then return { hasHelmet = false, battery = 0 } end

    for _, slot in ipairs(slots) do
        local battery = slot.metadata and slot.metadata.battery or 0
        if battery > 0 then
            local maxBattery = Config.Equipment['mining_helmet'].maxBattery
            local newBattery = math.max(0, battery - (drainAmount or Config.Equipment['mining_helmet'].drainRate))
            local newDurability = math.floor((newBattery / maxBattery) * 100 + 0.5)

            updateMetadata(src, slot.slot, slot.metadata, {
                battery = newBattery,
                durability = newDurability,
            })

            if newBattery <= 0 then
                TriggerClientEvent('mining:client:equipmentNotify', src, {
                    success = false,
                    reason = 'Helmet battery dead!',
                })
            end

            return { hasHelmet = true, battery = newBattery }
        end
    end

    return { hasHelmet = true, battery = 0 }
end)
