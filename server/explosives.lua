-----------------------------------------------------------
-- EXPLOSIVES SERVER
-- Handles blast mining, demolition charges, quarry blasting,
-- scatter pickup collection, and gas explosion interactions.
-----------------------------------------------------------

local DB = require 'server.database'

-----------------------------------------------------------
-- STATE
-----------------------------------------------------------

-- Active scatter pickups: scatterPickups[pickupId] = { oreType, amount, subZoneName, coords, createdAt, blasterSrc }
local scatterPickups = {}
local nextPickupId = 1

-- Quarry blast site cooldowns: blastSiteCooldowns[siteKey] = expiresAt (os.time)
local blastSiteCooldowns = {}

-- Track active quarry craters: activeCraters[craterKey] = { pickupIds, expiresAt, blasterSrc }
local activeCraters = {}

-----------------------------------------------------------
-- HELPERS
-----------------------------------------------------------

--- Finds a sub-zone config by name.
---@param subZoneName string
---@return table|nil subZone, string|nil zoneName
local function findSubZone(subZoneName)
    for zoneName, zoneData in pairs(Config.Zones) do
        for _, sz in ipairs(zoneData.subZones) do
            if sz.name == subZoneName then
                return sz, zoneName
            end
        end
    end
    return nil, nil
end

--- Rolls an ore type from a distribution table.
---@param distribution table<string, number>
---@return string
local function rollOreFromDistribution(distribution)
    local total = 0
    for _, weight in pairs(distribution) do
        total = total + weight
    end

    local roll = math.random(1, total)
    local cumulative = 0
    for oreType, weight in pairs(distribution) do
        cumulative = cumulative + weight
        if roll <= cumulative then
            return oreType
        end
    end

    for oreType in pairs(distribution) do
        return oreType
    end
end

--- Checks if a player has a detonator with uses remaining. Degrades it by 1.
---@param src number
---@return boolean hasDetonator, table|nil slot
local function useDetonator(src)
    local slots = exports.ox_inventory:Search(src, 'slots', 'detonator')
    if not slots then return false, nil end

    for _, slot in ipairs(slots) do
        local uses = slot.metadata and slot.metadata.uses or 0
        if uses > 0 then
            local maxUses = Config.Explosives.items['detonator'].maxUses
            local newUses = math.max(0, uses - 1)
            local newDurability = math.floor((newUses / maxUses) * 100 + 0.5)

            if newUses <= 0 then
                exports.ox_inventory:RemoveItem(src, 'detonator', 1, nil, slot.slot)
                TriggerClientEvent('ox_lib:notify', src, {
                    description = 'Detonator has broken!',
                    type = 'error',
                })
            else
                local meta = {}
                if slot.metadata then
                    for k, v in pairs(slot.metadata) do meta[k] = v end
                end
                meta.uses = newUses
                meta.durability = newDurability
                exports.ox_inventory:SetMetadata(src, slot.slot, meta)
            end

            return true, slot
        end
    end

    return false, nil
end

--- Creates scatter pickups around a position and broadcasts to clients.
---@param src number blaster source
---@param subZoneName string
---@param center table {x,y,z}
---@param count number
---@param radius number
---@param oreType string
---@param yieldPerPickup number
---@param persistence number ms
---@param model string prop model
---@param pickupRadius number ox_target radius
---@return table pickupIds
local function createScatterPickups(src, subZoneName, center, count, radius, oreType, yieldPerPickup, persistence, model, pickupRadius)
    local pickupIds = {}

    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local dist = radius * (0.3 + math.random() * 0.7)
        local pos = {
            x = center.x + math.cos(angle) * dist,
            y = center.y + math.sin(angle) * dist,
            z = center.z,
        }

        local id = nextPickupId
        nextPickupId = nextPickupId + 1

        scatterPickups[id] = {
            oreType = oreType,
            amount = yieldPerPickup,
            subZoneName = subZoneName,
            coords = pos,
            createdAt = os.time(),
            blasterSrc = src,
            model = model,
            pickupRadius = pickupRadius,
        }

        pickupIds[#pickupIds + 1] = id
    end

    -- Broadcast to clients
    TriggerClientEvent('mining:client:scatterSpawned', -1, subZoneName, pickupIds, scatterPickups, src, persistence)

    -- Schedule despawn
    SetTimeout(persistence, function()
        local despawned = {}
        for _, pid in ipairs(pickupIds) do
            if scatterPickups[pid] then
                scatterPickups[pid] = nil
                despawned[#despawned + 1] = pid
            end
        end
        if #despawned > 0 then
            TriggerClientEvent('mining:client:scatterDespawned', -1, subZoneName, despawned)
        end
    end)

    return pickupIds
end

--- Creates rubble pickups (for demolition/quarry) with random ore from distribution.
---@param src number blaster source
---@param subZoneName string
---@param center table {x,y,z}
---@param count number
---@param radius number
---@param distribution table ore distribution
---@param stoneYield table {min,max}
---@param oreChance number 0-100
---@param persistence number ms
---@param model string
---@param pickupRadius number
---@return table pickupIds
local function createRubblePickups(src, subZoneName, center, count, radius, distribution, stoneYield, oreChance, persistence, model, pickupRadius)
    local pickupIds = {}

    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local dist = radius * (0.3 + math.random() * 0.7)
        local pos = {
            x = center.x + math.cos(angle) * dist,
            y = center.y + math.sin(angle) * dist,
            z = center.z,
        }

        local id = nextPickupId
        nextPickupId = nextPickupId + 1

        -- Determine loot
        local stoneAmount = math.random(stoneYield.min, stoneYield.max)
        local oreType = nil
        local oreAmount = 0
        if math.random(1, 100) <= oreChance then
            oreType = rollOreFromDistribution(distribution)
            oreAmount = 1
        end

        scatterPickups[id] = {
            oreType = oreType,
            amount = oreAmount,
            stoneAmount = stoneAmount,
            subZoneName = subZoneName,
            coords = pos,
            createdAt = os.time(),
            blasterSrc = src,
            isRubble = true,
            model = model,
            pickupRadius = pickupRadius,
        }

        pickupIds[#pickupIds + 1] = id
    end

    TriggerClientEvent('mining:client:scatterSpawned', -1, subZoneName, pickupIds, scatterPickups, src, persistence)

    SetTimeout(persistence, function()
        local despawned = {}
        for _, pid in ipairs(pickupIds) do
            if scatterPickups[pid] then
                scatterPickups[pid] = nil
                despawned[#despawned + 1] = pid
            end
        end
        if #despawned > 0 then
            TriggerClientEvent('mining:client:scatterDespawned', -1, subZoneName, despawned)
        end
    end)

    return pickupIds
end

--- Checks for active gas leak in a sub-zone and triggers gas explosion if present.
---@param src number
---@param subZoneName string
---@param blastCoords table {x,y,z}
---@return boolean gasExploded
local function checkGasExplosion(src, subZoneName, blastCoords)
    -- Access active hazards from hazards.lua (global in server scope)
    -- We check by trying to query the gas state
    local gasResult = lib.callback.await('mining:server:gasCheck', src, subZoneName)
    -- This won't work since it's a server-to-server call; instead we use the exported state

    -- We'll trigger a client event to check, but actually we need access to activeHazards
    -- Since activeHazards is local to hazards.lua, we expose a check function
    return false -- handled via IsGasLeakActive global
end

-----------------------------------------------------------
-- GAS LEAK STATE ACCESS
-- hazards.lua exposes IsGasLeakActive globally
-----------------------------------------------------------

--- Triggers a devastating gas explosion event.
---@param subZoneName string
---@param blastCoords table {x,y,z}
local function triggerGasExplosion(subZoneName, blastCoords)
    local cfg = Config.Explosives.gasExplosion
    TriggerClientEvent('mining:client:gasExplosion', -1, subZoneName, blastCoords, cfg)

    -- Clear the gas leak via the global from hazards.lua
    if ClearGasLeak then
        ClearGasLeak(subZoneName)
    end
end

-----------------------------------------------------------
-- BLAST MINING CALLBACK (Concept 1)
-----------------------------------------------------------

lib.callback.register('mining:server:blastMine', function(src, data)
    -- data: { veinId, subZoneName }
    if not checkCooldown(src, 'blasting') then
        return { success = false, reason = 'Too fast' }
    end

    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    local cfg = Config.Explosives.blastMining

    -- Validate vein
    local vein = GetVein(data.veinId)
    if not vein or vein.depletedAt or vein.remaining <= 0 then
        return { success = false, reason = 'This vein is depleted' }
    end

    -- Check dynamite
    local dynamiteCount = exports.ox_inventory:Search(src, 'count', 'dynamite')
    if not dynamiteCount or dynamiteCount < cfg.dynamitePerBlast then
        return { success = false, reason = 'You need dynamite' }
    end

    -- Check detonator
    local hasDet = useDetonator(src)
    if not hasDet then
        return { success = false, reason = 'You need a detonator' }
    end

    -- Consume dynamite (Phase 9: Master Blaster may save dynamite)
    local dynamiteSaved = false
    if GetPlayerSkillBonus then
        local saveChance = GetPlayerSkillBonus(citizenId, 'dynamiteSaveChance')
        if saveChance > 0 and math.random() < saveChance then
            dynamiteSaved = true
        end
    end
    if not dynamiteSaved then
        exports.ox_inventory:RemoveItem(src, 'dynamite', cfg.dynamitePerBlast)
    end

    -- Get vein data for yield calculation
    local oreType = vein.oreType
    local oreDef = Config.Ores[oreType]
    if not oreDef then
        return { success = false, reason = 'Ore config error' }
    end

    local subZoneName = data.subZoneName
    local zoneName = FindZoneKey(subZoneName)

    -- Calculate total yield from all remaining extractions (no minigame bonus)
    local veinMod = Config.Veins.qualityYieldMin + (vein.quality / 100) * (Config.Veins.qualityYieldMax - Config.Veins.qualityYieldMin)
    local zoneYieldMod = 1.0
    if zoneName then
        local zoneData = Config.Zones[zoneName]
        if zoneData and zoneData.yieldMod then
            zoneYieldMod = zoneData.yieldMod
        end
    end

    -- Total ore from entire vein (remaining extractions * base yield * modifiers, no minigame)
    local totalOre = 0
    for _ = 1, vein.remaining do
        local base = math.random(Config.BaseYield.min, Config.BaseYield.max)
        totalOre = totalOre + math.max(1, math.floor(base * veinMod * zoneYieldMod + 0.5))
    end

    -- Deplete entire vein
    for _ = 1, vein.remaining do
        DepleteVein(data.veinId)
    end

    -- Determine scatter count (Phase 9: Powder Keg adds extra scatter)
    local scatterCount = math.random(cfg.scatterCount.min, cfg.scatterCount.max)
    if GetPlayerSkillBonus then
        local extraScatter = GetPlayerSkillBonus(citizenId, 'extraScatter')
        if extraScatter > 0 then
            scatterCount = scatterCount + math.floor(extraScatter)
        end
    end
    local yieldPerPickup = math.max(1, math.floor(totalOre / scatterCount + 0.5))

    -- Check for gas explosion
    local gasExploded = false
    if IsGasLeakActive and IsGasLeakActive(subZoneName) then
        gasExploded = true
        triggerGasExplosion(subZoneName, { x = vein.coords.x, y = vein.coords.y, z = vein.coords.z })
    end

    -- Spawn scatter pickups (ore NOT destroyed even during gas explosion)
    local pickupIds = createScatterPickups(
        src, subZoneName,
        { x = vein.coords.x, y = vein.coords.y, z = vein.coords.z },
        scatterCount, cfg.scatterRadius,
        oreType, yieldPerPickup,
        cfg.pickupPersistence,
        cfg.scatterModel, cfg.scatterPickupRadius
    )

    -- Award XP
    DB.AddMiningProgress(citizenId, cfg.xpReward, totalOre)
    checkLevelUp(src, citizenId)

    -- Advance contracts (Phase 7)
    if AdvanceContracts then
        AdvanceContracts(src, citizenId, 'blast_veins', 1, nil)
        AdvanceContracts(src, citizenId, 'mine_ore', totalOre, nil)
    end

    -- Track blast count for achievements (Phase 9)
    if TrackAchievementEvent then
        TrackAchievementEvent(src, citizenId, 'blast_count', 1)
    end

    -- Roll for hazard (with multiplier)
    if not gasExploded then
        local subZone = findSubZone(subZoneName)
        if subZone then
            local hazardWeight = (subZone.hazardWeight or 1.0) * cfg.hazardMultiplier
            local chance = Config.Hazards.baseChance * hazardWeight
            local roll = math.random(1, 100)
            if roll <= chance then
                local hazardTypes = Config.Hazards.types
                if zoneName == 'quarry' and Config.Hazards.quarryTypes then
                    hazardTypes = Config.Hazards.quarryTypes
                end
                local total = 0
                for _, w in pairs(hazardTypes) do total = total + w end
                local hRoll = math.random(1, total)
                local cum = 0
                for hType, w in pairs(hazardTypes) do
                    cum = cum + w
                    if hRoll <= cum then
                        if hType == 'cave_in' then TriggerCaveIn(subZoneName)
                        elseif hType == 'gas_leak' then TriggerGasLeak(subZoneName)
                        elseif hType == 'rockslide' then TriggerRockslide(subZoneName)
                        end
                        break
                    end
                end
            end
        end
    end

    return {
        success = true,
        oreType = oreType,
        oreLabel = oreDef.label,
        totalOre = totalOre,
        scatterCount = scatterCount,
        gasExploded = gasExploded,
        pickupIds = pickupIds,
    }
end)

-----------------------------------------------------------
-- DEMOLITION CHARGE CALLBACK (Concept 3)
-----------------------------------------------------------

lib.callback.register('mining:server:demolitionBlast', function(src, data)
    -- data: { subZoneName, targetType='boulder'|'debris'|'passage', targetIndex, coords }
    if not checkCooldown(src, 'demolition') then
        return { success = false, reason = 'Too fast' }
    end

    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    local cfg = Config.Explosives.demolition
    local subZoneName = data.subZoneName
    local targetType = data.targetType

    -- Determine charge cost (Phase 9: Shaped Charge reduces cost)
    local chargesNeeded = cfg.chargesPerObstacle
    if targetType == 'passage' then
        chargesNeeded = cfg.chargesPerPassage
    end
    if GetPlayerSkillBonus then
        local discount = GetPlayerSkillBonus(citizenId, 'chargeDiscount')
        if discount > 0 then
            chargesNeeded = math.max(1, chargesNeeded - math.floor(discount))
        end
    end

    -- Check blasting charges
    local chargeCount = exports.ox_inventory:Search(src, 'count', 'blasting_charge')
    if not chargeCount or chargeCount < chargesNeeded then
        return { success = false, reason = ('Need %d blasting charge(s)'):format(chargesNeeded) }
    end

    -- Check detonator
    local hasDet = useDetonator(src)
    if not hasDet then
        return { success = false, reason = 'You need a detonator' }
    end

    -- Consume charges
    exports.ox_inventory:RemoveItem(src, 'blasting_charge', chargesNeeded)

    local subZone = findSubZone(subZoneName)
    local zoneName = FindZoneKey(subZoneName)
    local distribution = subZone and subZone.oreDistribution or { stone = 100 }

    -- Check for gas explosion (devastating in all instances)
    local gasExploded = false
    if IsGasLeakActive and IsGasLeakActive(subZoneName) then
        gasExploded = true
        triggerGasExplosion(subZoneName, data.coords)
    end

    -- Determine rubble count and loot
    local rubbleCount
    local stoneYield
    local oreChance

    if targetType == 'passage' then
        -- Sealed passages use cave-in loot rolls
        rubbleCount = math.random(cfg.passageRubbleCount.min, cfg.passageRubbleCount.max)
        stoneYield = Config.CaveIn.boulderStoneYield
        oreChance = Config.CaveIn.boulderOreChance
    else
        -- Regular obstacle demolition (less than manual mining)
        rubbleCount = math.random(cfg.rubbleCount.min, cfg.rubbleCount.max)
        stoneYield = cfg.rubbleStoneYield
        oreChance = cfg.rubbleOreChance
    end

    -- Create rubble pickups
    local pickupIds = createRubblePickups(
        src, subZoneName,
        data.coords, rubbleCount,
        cfg.blastRadius * 0.5,
        distribution, stoneYield, oreChance,
        Config.Explosives.blastMining.pickupPersistence, -- same persistence as blast mining
        cfg.rubbleModel, cfg.rubblePickupRadius
    )

    -- Award XP
    DB.AddMiningProgress(citizenId, cfg.xpReward, 0)

    -- Notify clients to remove the obstacle
    TriggerClientEvent('mining:client:obstacleDestroyed', -1, subZoneName, targetType, data.targetIndex)

    return {
        success = true,
        targetType = targetType,
        rubbleCount = rubbleCount,
        gasExploded = gasExploded,
        pickupIds = pickupIds,
    }
end)

-----------------------------------------------------------
-- QUARRY BLASTING CALLBACK (Concept 4)
-----------------------------------------------------------

lib.callback.register('mining:server:quarryBlast', function(src, data)
    -- data: { subZoneName, siteIndex, placementQualities={slot1,slot2,slot3} }
    if not checkCooldown(src, 'quarryBlast') then
        return { success = false, reason = 'Too fast' }
    end

    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    local cfg = Config.Explosives.quarryBlasting
    local subZoneName = data.subZoneName

    -- Validate zone is quarry
    local zoneName = FindZoneKey(subZoneName)
    if zoneName ~= 'quarry' then
        return { success = false, reason = 'Quarry blasting only works in quarry zones' }
    end

    -- Check blast site cooldown
    local siteKey = subZoneName .. '_' .. data.siteIndex
    local cooldownExpires = blastSiteCooldowns[siteKey]
    if cooldownExpires and os.time() < cooldownExpires then
        local remaining = cooldownExpires - os.time()
        return { success = false, reason = ('Blast site on cooldown (%d min remaining)'):format(math.ceil(remaining / 60)) }
    end

    -- Check blasting charges
    local chargeCount = exports.ox_inventory:Search(src, 'count', 'blasting_charge')
    if not chargeCount or chargeCount < cfg.chargesPerBlast then
        return { success = false, reason = ('Need %d blasting charges'):format(cfg.chargesPerBlast) }
    end

    -- Check detonator wire
    local wireCount = exports.ox_inventory:Search(src, 'count', 'detonator_wire')
    if not wireCount or wireCount < cfg.wiresPerBlast then
        return { success = false, reason = 'Need detonator wire' }
    end

    -- Check detonator
    local hasDet = useDetonator(src)
    if not hasDet then
        return { success = false, reason = 'You need a detonator' }
    end

    -- Consume materials
    exports.ox_inventory:RemoveItem(src, 'blasting_charge', cfg.chargesPerBlast)
    exports.ox_inventory:RemoveItem(src, 'detonator_wire', cfg.wiresPerBlast)

    -- Calculate placement quality modifier
    local qualities = data.placementQualities or { 'yellow', 'yellow', 'yellow' }
    local totalMod = 0
    for _, q in ipairs(qualities) do
        totalMod = totalMod + (cfg.placementQuality[q] or cfg.placementQuality.yellow)
    end
    local avgMod = totalMod / #qualities

    -- Determine rubble count based on placement quality (Phase 9: Chain Reaction bonus)
    local baseCount = math.random(cfg.rubbleCount.min, cfg.rubbleCount.max)
    local rubbleCount = math.max(cfg.rubbleCount.min, math.floor(baseCount * avgMod + 0.5))
    if GetPlayerSkillBonus then
        local rubbleBonus = GetPlayerSkillBonus(citizenId, 'quarryRubbleBonus')
        if rubbleBonus > 0 then
            rubbleCount = math.floor(rubbleCount * (1 + rubbleBonus) + 0.5)
        end
    end

    -- Get sub-zone data for ore distribution
    local subZone = findSubZone(subZoneName)
    local distribution = subZone and subZone.oreDistribution or { limestone = 50, sandstone = 50 }

    -- Find blast site center
    local blastCenter = { x = 0, y = 0, z = 0 }
    if subZone and subZone.blastSites and subZone.blastSites[data.siteIndex] then
        local site = subZone.blastSites[data.siteIndex]
        blastCenter = { x = site.center.x, y = site.center.y, z = site.center.z }
    end

    -- Check for gas explosion (devastating in all instances)
    local gasExploded = false
    if IsGasLeakActive and IsGasLeakActive(subZoneName) then
        gasExploded = true
        triggerGasExplosion(subZoneName, blastCenter)
    end

    -- Create rubble pickups with random quarry ores
    -- Quarry rubble always has ore (100% chance), plus stone
    local pickupIds = createRubblePickups(
        src, subZoneName,
        blastCenter, rubbleCount,
        cfg.blastRadius * 0.6,
        distribution,
        cfg.rubbleStoneYield,
        100, -- 100% ore chance for quarry rubble
        cfg.craterDuration,
        cfg.rubbleModel, cfg.rubblePickupRadius
    )

    -- Track crater
    local craterKey = siteKey .. '_' .. os.time()
    activeCraters[craterKey] = {
        pickupIds = pickupIds,
        expiresAt = os.time() + (cfg.craterDuration / 1000),
        blasterSrc = src,
    }

    -- Set blast site cooldown
    blastSiteCooldowns[siteKey] = os.time() + (cfg.siteCooldown / 1000)

    -- Notify clients about head start
    TriggerClientEvent('mining:client:quarryCraterCreated', -1, subZoneName, data.siteIndex, pickupIds, src, cfg.blasterHeadStart)

    -- Award XP
    DB.AddMiningProgress(citizenId, cfg.xpReward, rubbleCount)
    checkLevelUp(src, citizenId)

    -- Clean up crater after duration
    SetTimeout(cfg.craterDuration, function()
        activeCraters[craterKey] = nil
    end)

    return {
        success = true,
        rubbleCount = rubbleCount,
        avgPlacementQuality = avgMod,
        gasExploded = gasExploded,
    }
end)

-----------------------------------------------------------
-- SCATTER/RUBBLE PICKUP CALLBACK
-----------------------------------------------------------

lib.callback.register('mining:server:collectPickup', function(src, data)
    -- data: { pickupId }
    if not checkCooldown(src, 'pickupScatter') then
        return { success = false, reason = 'Too fast' }
    end

    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    local pickupId = data.pickupId
    local pickup = scatterPickups[pickupId]

    if not pickup then
        return { success = false, reason = 'Pickup no longer available' }
    end

    -- Remove from state immediately (claim it)
    scatterPickups[pickupId] = nil

    local results = { success = true, items = {} }

    -- Handle rubble type (stone + possible ore)
    if pickup.isRubble then
        local stoneAmount = pickup.stoneAmount or 0
        if stoneAmount > 0 and exports.ox_inventory:CanCarryItem(src, 'stone', stoneAmount) then
            exports.ox_inventory:AddItem(src, 'stone', stoneAmount)
            results.items[#results.items + 1] = { item = 'stone', label = 'Stone', amount = stoneAmount }
        end

        if pickup.oreType and pickup.amount and pickup.amount > 0 then
            if exports.ox_inventory:CanCarryItem(src, pickup.oreType, pickup.amount) then
                exports.ox_inventory:AddItem(src, pickup.oreType, pickup.amount)
                local oreLabel = Config.Ores[pickup.oreType] and Config.Ores[pickup.oreType].label or pickup.oreType
                results.items[#results.items + 1] = { item = pickup.oreType, label = oreLabel, amount = pickup.amount }
            end
        end
    else
        -- Regular ore scatter
        if pickup.oreType and pickup.amount and pickup.amount > 0 then
            if exports.ox_inventory:CanCarryItem(src, pickup.oreType, pickup.amount) then
                exports.ox_inventory:AddItem(src, pickup.oreType, pickup.amount)
                local oreLabel = Config.Ores[pickup.oreType] and Config.Ores[pickup.oreType].label or pickup.oreType
                results.items[#results.items + 1] = { item = pickup.oreType, label = oreLabel, amount = pickup.amount }
            else
                -- Put it back if inventory full
                scatterPickups[pickupId] = pickup
                return { success = false, reason = 'Inventory full' }
            end
        end
    end

    -- Award small XP for collection
    DB.AddMiningProgress(citizenId, 2, 0)

    -- Notify all clients to remove this pickup
    TriggerClientEvent('mining:client:pickupCollected', -1, pickupId, pickup.subZoneName)

    return results
end)

-----------------------------------------------------------
-- DETONATOR PURCHASE METADATA (hook into shop)
-----------------------------------------------------------

-- Patch the buyItem callback to handle detonator metadata
-- This is done in main.lua's buyItem callback via the existing
-- metadata builder. We add the detonator case here as an
-- ox_inventory hook instead.

-- No separate hook needed; we'll add to the shop callback metadata
-- in config by ensuring the main.lua buyItem handles it.

-----------------------------------------------------------
-- CLEANUP
-----------------------------------------------------------

AddEventHandler('playerDropped', function()
    -- No per-player state to clean up for explosives
end)
