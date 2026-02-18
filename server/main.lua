local DB = require 'server.database'

-----------------------------------------------------------
-- STATE
-----------------------------------------------------------

local cooldowns = {} -- cooldowns[source][action] = timestamp

-----------------------------------------------------------
-- HELPERS
-----------------------------------------------------------

--- Checks and enforces a cooldown for a player action.
--- Global: shared with processing.lua.
---@param src number
---@param action string
---@return boolean passed
function checkCooldown(src, action)
    local now = GetGameTimer()
    local cd = Config.Cooldowns[action]
    if not cd then return true end

    if not cooldowns[src] then cooldowns[src] = {} end
    if cooldowns[src][action] and (now - cooldowns[src][action]) < cd then
        return false
    end

    cooldowns[src][action] = now
    return true
end

--- Gets the citizenId for a source, or nil.
--- Global: shared with processing.lua.
---@param src number
---@return string|nil
function getCitizenId(src)
    local player = exports.qbx_core:GetPlayer(src)
    return player and player.PlayerData.citizenid or nil
end

--- Finds a usable tool in the player's inventory for the given ore.
--- Returns the item name and inventory slot, or nil.
---@param src number
---@param oreType string
---@return string|nil toolName, table|nil slotData
local function findTool(src, oreType)
    local oreDef = Config.Ores[oreType]
    if not oreDef then return nil, nil end

    -- Determine which tools can mine this ore
    local validTools = {}
    for toolName, toolDef in pairs(Config.Tools) do
        for _, mineable in ipairs(toolDef.canMine) do
            if mineable == oreType then
                validTools[toolName] = true
                break
            end
        end
    end

    -- Search inventory for a valid tool with durability > 0
    for toolName in pairs(validTools) do
        local slots = exports.ox_inventory:Search(src, 'slots', toolName)
        if slots then
            for _, slot in ipairs(slots) do
                local uses = slot.metadata and slot.metadata.uses or 0
                if uses > 0 then
                    return toolName, slot
                end
            end
        end
    end

    return nil, nil
end

--- Degrades a tool's durability by the given amount.
---@param src number
---@param slot table
---@param toolName string
---@param wearAmount number
local function degradeTool(src, slot, toolName, wearAmount)
    local maxDur = Config.Tools[toolName].maxDurability
    local newUses = math.max(0, (slot.metadata.uses or maxDur) - wearAmount)
    local newDurability = math.floor((newUses / maxDur) * 100 + 0.5)

    if newUses <= 0 then
        exports.ox_inventory:RemoveItem(src, toolName, 1, nil, slot.slot)
        TriggerClientEvent('ox_lib:notify', src, { description = ('%s has broken!'):format(Config.Tools[toolName].label), type = 'error' })
    else
        local meta = {}
        if slot.metadata then
            for k, v in pairs(slot.metadata) do meta[k] = v end
        end
        meta.uses = newUses
        meta.durability = newDurability
        exports.ox_inventory:SetMetadata(src, slot.slot, meta)
    end
end

--- Calculates ore yield based on mode, minigame result, and vein quality.
---@param mode string
---@param minigameResult string 'green'|'yellow'|'red'
---@param veinQuality number 0-100
---@return number
local function calculateYield(mode, minigameResult, veinQuality)
    local modeDef = Config.MiningModes[mode]
    local minigameMod = Config.Minigame.yieldMultiplier[minigameResult] or 1.0
    local qualityMod = modeDef and modeDef.qualityMod or 1.0

    -- Vein quality modifier: lerp between qualityYieldMin and qualityYieldMax
    local qNorm = (veinQuality or 50) / 100
    local veinMod = Config.Veins.qualityYieldMin + qNorm * (Config.Veins.qualityYieldMax - Config.Veins.qualityYieldMin)

    local base = math.random(Config.BaseYield.min, Config.BaseYield.max)
    return math.max(1, math.floor(base * qualityMod * minigameMod * veinMod + 0.5))
end

-----------------------------------------------------------
-- PLAYER INIT
-----------------------------------------------------------

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local citizenId = getCitizenId(src)
    if citizenId then
        DB.EnsurePlayer(citizenId)
    end
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)

-----------------------------------------------------------
-- DRILL BIT USABLE ITEM (server-side registration)
-----------------------------------------------------------

exports.ox_inventory:registerHook('usingItem', function(payload)
    if payload.item.name ~= 'drill_bit' then return true end

    local src = payload.source
    if not checkCooldown(src, 'drillBit') then
        TriggerClientEvent('mining:client:useDrillBit', src, { success = false, reason = 'Too fast' })
        return false
    end

    -- Find rock_drill with durability < max
    local drillSlots = exports.ox_inventory:Search(src, 'slots', 'rock_drill')
    local targetSlot = nil
    if drillSlots then
        for _, slot in ipairs(drillSlots) do
            local uses = slot.metadata and slot.metadata.uses or 0
            if uses > 0 and uses < Config.Tools['rock_drill'].maxDurability then
                targetSlot = slot
                break
            end
        end
    end

    if not targetSlot then
        TriggerClientEvent('mining:client:useDrillBit', src, { success = false, reason = 'No drill that needs repair' })
        return false
    end

    -- Restore uses
    local maxDur = Config.Tools['rock_drill'].maxDurability
    local newUses = math.min(maxDur, (targetSlot.metadata.uses or 0) + Config.DrillBit.restoreAmount)
    local newDurability = math.floor((newUses / maxDur) * 100 + 0.5)

    local meta = {}
    if targetSlot.metadata then
        for k, v in pairs(targetSlot.metadata) do meta[k] = v end
    end
    meta.uses = newUses
    meta.durability = newDurability
    exports.ox_inventory:SetMetadata(src, targetSlot.slot, meta)

    TriggerClientEvent('mining:client:useDrillBit', src, {
        success = true,
        newUses = newUses,
        newDurability = newDurability,
    })

    return true -- consume the drill_bit
end, { itemFilter = { drill_bit = true } })

-----------------------------------------------------------
-- MINING CALLBACK
-----------------------------------------------------------

lib.callback.register('mining:server:extract', function(src, data)
    -- data: { veinId, subZoneName, mode, minigameResult }
    if not checkCooldown(src, 'mining') then
        return { success = false, reason = 'Too fast' }
    end

    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    local mode = data.mode
    local minigameResult = data.minigameResult
    local veinId = data.veinId

    -- Validate mode
    if not Config.MiningModes[mode] then
        return { success = false, reason = 'Invalid mode' }
    end

    -- Validate minigame result
    if minigameResult ~= 'green' and minigameResult ~= 'yellow' and minigameResult ~= 'red' then
        return { success = false, reason = 'Invalid minigame result' }
    end

    -- Validate vein exists and is not depleted
    local vein = GetVein(veinId)
    if not vein or vein.depletedAt or vein.remaining <= 0 then
        return { success = false, reason = 'This vein is depleted' }
    end

    -- Get ore definition from vein's ore type
    local oreType = vein.oreType
    local oreDef = Config.Ores[oreType]
    if not oreDef then
        return { success = false, reason = 'Ore config error' }
    end

    -- Find a valid tool
    local toolName, toolSlot = findTool(src, oreType)
    if not toolName then
        return { success = false, reason = 'No suitable tool', requiredTool = oreDef.tool }
    end

    -- Calculate yield (now includes vein quality)
    local amount = calculateYield(mode, minigameResult, vein.quality)

    -- Check inventory space
    if not exports.ox_inventory:CanCarryItem(src, oreType, amount) then
        return { success = false, reason = 'Inventory full' }
    end

    -- Degrade tool (base wear of 3 uses, modified by mode)
    local modeDef = Config.MiningModes[mode]
    local baseWear = 3
    local wearAmount = math.max(1, math.floor(baseWear * modeDef.wearMod + 0.5))
    degradeTool(src, toolSlot, toolName, wearAmount)

    -- Deplete vein by 1 extraction
    DepleteVein(veinId)

    -- Award ore
    exports.ox_inventory:AddItem(src, oreType, amount)

    -- Track stats
    DB.AddMiningProgress(citizenId, 10, amount)

    -- Roll for hazard after successful extraction
    local subZoneName = data.subZoneName
    local hazardType = RollHazard(subZoneName)
    if hazardType == 'cave_in' then
        TriggerCaveIn(subZoneName)
    elseif hazardType == 'gas_leak' then
        TriggerGasLeak(subZoneName)
    end

    return {
        success = true,
        oreType = oreType,
        oreLabel = oreDef.label,
        amount = amount,
        minigameResult = minigameResult,
        veinQuality = vein.quality,
        veinRemaining = math.max(0, vein.remaining - 1),
    }
end)

-----------------------------------------------------------
-- SELL CALLBACK
-----------------------------------------------------------

lib.callback.register('mining:server:sell', function(src, data)
    -- data: { item, amount }
    if not checkCooldown(src, 'selling') then
        return { success = false, reason = 'Too fast' }
    end

    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    local item = data.item
    local amount = data.amount

    if type(amount) ~= 'number' or amount < 1 then
        return { success = false, reason = 'Invalid amount' }
    end
    amount = math.floor(amount)

    local price = Config.SellPrices[item]
    if not price then
        return { success = false, reason = 'Item not sellable' }
    end

    -- Check for cut gem quality metadata
    local qualityMul = 1.0
    local gemQualities = Config.GemCutting.qualityMultiplier
    if item == 'cut_quartz' or item == 'cut_emerald' or item == 'cut_diamond' then
        -- For gems, sell one at a time using slot-specific metadata
        -- This simplified path sells at base (good) price for stacked sells
        -- Quality-based pricing is handled per-slot in client sell flow
        qualityMul = data.qualityMultiplier or 1.0
    end

    -- Verify player has the items
    local count = exports.ox_inventory:Search(src, 'count', item)
    if not count or count < amount then
        return { success = false, reason = 'Not enough items' }
    end

    -- Remove items and pay
    local removed = exports.ox_inventory:RemoveItem(src, item, amount)
    if not removed then
        return { success = false, reason = 'Failed to remove items' }
    end

    local total = math.floor(price * amount * qualityMul)
    local player = exports.qbx_core:GetPlayer(src)
    if player then
        player.Functions.AddMoney('cash', total, 'mining-sale')
    end

    DB.AddEarnings(citizenId, total)

    return {
        success = true,
        item = item,
        amount = amount,
        total = total,
    }
end)

-----------------------------------------------------------
-- SHOP CALLBACK
-----------------------------------------------------------

lib.callback.register('mining:server:buyItem', function(src, data)
    -- data: { item, amount }
    if not checkCooldown(src, 'purchase') then
        return { success = false, reason = 'Too fast' }
    end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return { success = false, reason = 'Player not loaded' } end

    local itemName = data.item
    local amount = math.max(1, math.floor(data.amount or 1))

    -- Find item in shop config
    local shopItem = nil
    for _, entry in ipairs(Config.Shop.items) do
        if entry.item == itemName then
            shopItem = entry
            break
        end
    end

    if not shopItem then
        return { success = false, reason = 'Item not in shop' }
    end

    local totalCost = shopItem.price * amount

    -- Check money
    local cash = player.PlayerData.money.cash
    if cash < totalCost then
        return { success = false, reason = 'Not enough money' }
    end

    -- Check carry capacity
    if not exports.ox_inventory:CanCarryItem(src, itemName, amount) then
        return { success = false, reason = 'Inventory full' }
    end

    -- Process purchase
    player.Functions.RemoveMoney('cash', totalCost, 'mining-shop')

    -- Build metadata based on item type
    local metadata = nil
    if Config.Tools[itemName] then
        metadata = {
            uses = Config.Tools[itemName].maxDurability,
            durability = 100,
        }
    elseif itemName == 'propane_canister' then
        metadata = { uses = Config.Smelting.propaneUsesPerCanister }
    elseif itemName == 'mining_helmet' then
        metadata = {
            battery = Config.Equipment['mining_helmet'].maxBattery,
            durability = 100,
        }
    elseif itemName == 'respirator' then
        metadata = {
            uses = Config.Equipment['respirator'].maxUses,
            durability = 100,
        }
    end

    for _ = 1, amount do
        exports.ox_inventory:AddItem(src, itemName, 1, metadata)
    end

    return {
        success = true,
        item = itemName,
        amount = amount,
        cost = totalCost,
    }
end)

-----------------------------------------------------------
-- DATA CALLBACKS
-----------------------------------------------------------

--- Returns ore distribution data for a sub-zone.
lib.callback.register('mining:server:getSubZoneData', function(src, subZoneName)
    for _, zoneData in pairs(Config.Zones) do
        for _, sz in ipairs(zoneData.subZones) do
            if sz.name == subZoneName then
                return {
                    oreDistribution = sz.oreDistribution,
                }
            end
        end
    end
    return nil
end)

--- Returns player mining stats.
lib.callback.register('mining:server:getStats', function(src)
    local citizenId = getCitizenId(src)
    if not citizenId then return nil end
    return DB.GetStats(citizenId)
end)
