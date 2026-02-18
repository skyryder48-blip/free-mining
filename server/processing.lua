local DB = require 'server.database'

-- Shared helpers imported from main.lua globals
-- checkCooldown() and getCitizenId() are defined in server/main.lua

-----------------------------------------------------------
-- SMELTING
-----------------------------------------------------------

lib.callback.register('mining:server:smelt', function(src, data)
    -- data: { oreItem, amount, fuelType, minigameResult }
    if not checkCooldown(src, 'smelting') then
        return { success = false, reason = 'Too fast' }
    end

    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return { success = false, reason = 'Player not loaded' } end

    local oreItem = data.oreItem
    local amount = data.amount
    local fuelType = data.fuelType -- 'coal' or 'propane_canister'
    local minigameResult = data.minigameResult -- 'green', 'yellow', 'red'

    -- Validate ore is smeltable
    local oreDef = Config.Ores[oreItem]
    if not oreDef or oreDef.processing ~= 'smelt' then
        return { success = false, reason = 'Item cannot be smelted' }
    end

    -- Validate amount
    if type(amount) ~= 'number' or amount < 1 or amount > Config.Smelting.maxBatch then
        return { success = false, reason = 'Invalid batch size (1-' .. Config.Smelting.maxBatch .. ')' }
    end
    amount = math.floor(amount)

    -- Validate minigame result
    if minigameResult ~= 'green' and minigameResult ~= 'yellow' and minigameResult ~= 'red' then
        return { success = false, reason = 'Invalid minigame result' }
    end

    -- Check furnace fee
    if player.PlayerData.money.cash < Config.Smelting.furnaceFee then
        return { success = false, reason = 'Cannot afford furnace fee ($' .. Config.Smelting.furnaceFee .. ')' }
    end

    -- Check ore count
    local oreCount = exports.ox_inventory:Search(src, 'count', oreItem)
    if not oreCount or oreCount < amount then
        return { success = false, reason = 'Not enough ore' }
    end

    -- Check fuel
    if fuelType == 'coal' then
        local coalNeeded = Config.Smelting.coalPerBatch
        local coalCount = exports.ox_inventory:Search(src, 'count', 'coal')
        if not coalCount or coalCount < coalNeeded then
            return { success = false, reason = 'Need ' .. coalNeeded .. ' coal' }
        end
    elseif fuelType == 'propane_canister' then
        local propaneSlots = exports.ox_inventory:Search(src, 'slots', 'propane_canister')
        local foundSlot = nil
        if propaneSlots then
            for _, slot in ipairs(propaneSlots) do
                local uses = slot.metadata and slot.metadata.uses or 0
                if uses > 0 then
                    foundSlot = slot
                    break
                end
            end
        end
        if not foundSlot then
            return { success = false, reason = 'No propane with fuel remaining' }
        end
    else
        return { success = false, reason = 'Invalid fuel type' }
    end

    -- Calculate output based on minigame
    local outputItem = oreDef.output
    local outputAmount = 0
    local oreConsumed = amount
    local message = ''

    if minigameResult == 'green' then
        -- Perfect: 1:1 ore to ingot
        outputAmount = amount
        message = 'Perfect smelt!'
    elseif minigameResult == 'yellow' then
        -- Partial: lose 1 ore from batch
        outputAmount = math.max(1, amount - 1)
        message = 'Decent smelt. Lost 1 ore to impurities.'
    else
        -- Failed: batch ruined
        outputAmount = 0
        message = 'Temperature control failed! Batch ruined.'
    end

    -- Check carry capacity for output
    if outputAmount > 0 and not exports.ox_inventory:CanCarryItem(src, outputItem, outputAmount) then
        return { success = false, reason = 'Inventory too full for ingots' }
    end

    -- Deduct furnace fee
    player.Functions.RemoveMoney('cash', Config.Smelting.furnaceFee, 'mining-smelt-fee')

    -- Consume ore
    exports.ox_inventory:RemoveItem(src, oreItem, oreConsumed)

    -- Consume fuel
    if fuelType == 'coal' then
        exports.ox_inventory:RemoveItem(src, 'coal', Config.Smelting.coalPerBatch)
    elseif fuelType == 'propane_canister' then
        local propaneSlots = exports.ox_inventory:Search(src, 'slots', 'propane_canister')
        if propaneSlots then
            for _, slot in ipairs(propaneSlots) do
                local uses = slot.metadata and slot.metadata.uses or 0
                if uses > 0 then
                    local newUses = uses - 1
                    if newUses <= 0 then
                        exports.ox_inventory:RemoveItem(src, 'propane_canister', 1, nil, slot.slot)
                    else
                        local meta = {}
                        if slot.metadata then
                            for k, v in pairs(slot.metadata) do meta[k] = v end
                        end
                        meta.uses = newUses
                        exports.ox_inventory:SetMetadata(src, slot.slot, meta)
                    end
                    break
                end
            end
        end
    end

    -- Award output
    if outputAmount > 0 then
        exports.ox_inventory:AddItem(src, outputItem, outputAmount)
    end

    -- Track stats and check level-up
    if outputAmount > 0 then
        DB.AddMiningProgress(citizenId, 15, 0) -- 15 XP for smelting, 0 additional ore mined
        checkLevelUp(src, citizenId)
    end

    return {
        success = true,
        outputItem = outputItem,
        outputAmount = outputAmount,
        oreConsumed = oreConsumed,
        minigameResult = minigameResult,
        message = message,
        xpGained = outputAmount > 0 and 15 or 0,
    }
end)

-----------------------------------------------------------
-- GEM CUTTING
-----------------------------------------------------------

lib.callback.register('mining:server:cutGem', function(src, data)
    -- data: { gemItem, cut1Result, cut2Result }
    if not checkCooldown(src, 'cutting') then
        return { success = false, reason = 'Too fast' }
    end

    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return { success = false, reason = 'Player not loaded' } end

    local gemItem = data.gemItem
    local cut1 = data.cut1Result -- 'green', 'yellow', 'red'
    local cut2 = data.cut2Result -- 'green', 'yellow', 'red'

    -- Validate gem is cuttable
    local oreDef = Config.Ores[gemItem]
    if not oreDef or oreDef.processing ~= 'cut' then
        return { success = false, reason = 'Item cannot be cut' }
    end

    -- Validate cut results
    local validResults = { green = true, yellow = true, red = true }
    if not validResults[cut1] or not validResults[cut2] then
        return { success = false, reason = 'Invalid cut result' }
    end

    -- Check cutting fee
    if player.PlayerData.money.cash < Config.GemCutting.cuttingFee then
        return { success = false, reason = 'Cannot afford cutting fee ($' .. Config.GemCutting.cuttingFee .. ')' }
    end

    -- Check player has the gem
    local gemCount = exports.ox_inventory:Search(src, 'count', gemItem)
    if not gemCount or gemCount < 1 then
        return { success = false, reason = 'No gem to cut' }
    end

    -- Determine quality based on both cuts
    local quality = 'chipped'
    local qualityLabel = 'Chipped'
    if cut1 == 'green' and cut2 == 'green' then
        quality = 'flawless'
        qualityLabel = 'Flawless'
    elseif cut1 ~= 'red' and cut2 ~= 'red' then
        quality = 'good'
        qualityLabel = 'Good'
    end

    local qualityMul = Config.GemCutting.qualityMultiplier[quality]
    local outputItem = oreDef.output

    -- Check carry capacity
    if not exports.ox_inventory:CanCarryItem(src, outputItem, 1) then
        return { success = false, reason = 'Inventory too full' }
    end

    -- Deduct fee
    player.Functions.RemoveMoney('cash', Config.GemCutting.cuttingFee, 'mining-cut-fee')

    -- Consume raw gem
    exports.ox_inventory:RemoveItem(src, gemItem, 1)

    -- Award cut gem with quality metadata
    exports.ox_inventory:AddItem(src, outputItem, 1, {
        quality = quality,
        qualityLabel = qualityLabel,
        qualityMultiplier = qualityMul,
        description = qualityLabel .. ' quality',
    })

    -- Track stats and check level-up
    DB.AddMiningProgress(citizenId, 20, 0) -- 20 XP for cutting
    checkLevelUp(src, citizenId)

    return {
        success = true,
        outputItem = outputItem,
        quality = quality,
        qualityLabel = qualityLabel,
        qualityMultiplier = qualityMul,
        xpGained = 20,
    }
end)
