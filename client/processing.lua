-----------------------------------------------------------
-- PROCESSING CLIENT
-- Handles furnace (smelting) and cutting bench (gem cutting)
-- interactions, including fuel selection and minigame flow.
-----------------------------------------------------------

-----------------------------------------------------------
-- HELPERS
-----------------------------------------------------------
-- Minigame is provided by PlayMinigame() global from mining.lua

--- Gets smeltable ores the player currently has.
---@return table[] list of {item, label, count}
local function getSmeltableOres()
    local ores = {}
    for oreItem, oreDef in pairs(Config.Ores) do
        if oreDef.processing == 'smelt' then
            local count = exports.ox_inventory:Search('count', oreItem)
            if count and count > 0 then
                ores[#ores + 1] = {
                    item = oreItem,
                    label = oreDef.label,
                    count = count,
                    difficulty = oreDef.difficulty,
                    output = oreDef.output,
                }
            end
        end
    end
    return ores
end

--- Gets cuttable gems the player currently has.
---@return table[] list of {item, label, count}
local function getCuttableGems()
    local gems = {}
    for gemItem, oreDef in pairs(Config.Ores) do
        if oreDef.processing == 'cut' then
            local count = exports.ox_inventory:Search('count', gemItem)
            if count and count > 0 then
                gems[#gems + 1] = {
                    item = gemItem,
                    label = oreDef.label,
                    count = count,
                    difficulty = oreDef.difficulty,
                    output = oreDef.output,
                }
            end
        end
    end
    return gems
end

--- Checks if player has valid fuel for smelting.
---@return string|nil fuelType 'coal' or 'propane_canister'
local function checkFuel()
    local coalCount = exports.ox_inventory:Search('count', 'coal')
    if coalCount and coalCount >= Config.Smelting.coalPerBatch then
        return 'coal'
    end

    local propaneCount = exports.ox_inventory:Search('count', 'propane_canister')
    if propaneCount and propaneCount > 0 then
        return 'propane_canister'
    end

    return nil
end

-----------------------------------------------------------
-- SMELTING
-----------------------------------------------------------

--- Forward declarations
local startSmelting, executeSmelting, startGemCutting

--- Runs the actual smelting process.
---@param ore table
---@param amount number
---@param fuelType string
executeSmelting = function(ore, amount, fuelType)
    local anim = Config.Animations.smelting
    lib.requestAnimDict(anim.dict)

    local duration = Config.Smelting.baseTime + (amount * 2000)

    local completed = lib.progressCircle({
        duration = duration,
        label = ('Smelting %dx %s...'):format(amount, ore.label),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            combat = true,
            car = true,
        },
        anim = {
            dict = anim.dict,
            clip = anim.clip,
            flag = 1,
        },
    })

    if not completed then
        lib.notify({ description = 'Smelting cancelled.', type = 'inform' })
        return
    end

    -- Temperature control minigame
    local minigameResult = PlayMinigame(ore.difficulty)

    -- Send to server
    local result = lib.callback.await('mining:server:smelt', false, {
        oreItem = ore.item,
        amount = amount,
        fuelType = fuelType,
        minigameResult = minigameResult,
    })

    if result and result.success then
        if result.outputAmount > 0 then
            lib.notify({
                description = ('%s Produced %dx %s'):format(result.message, result.outputAmount, result.outputItem),
                type = minigameResult == 'red' and 'error' or 'success',
                duration = 5000,
            })
        else
            lib.notify({
                description = result.message,
                type = 'error',
                duration = 5000,
            })
        end
    elseif result then
        lib.notify({ description = result.reason or 'Smelting failed', type = 'error' })
    end
end

--- Handles fuel selection or skips to smelting if only one fuel available.
---@param ore table
---@param amount number
---@param fuelType string
startSmelting = function(ore, amount, fuelType)
    local coalCount = exports.ox_inventory:Search('count', 'coal')
    local propaneCount = exports.ox_inventory:Search('count', 'propane_canister')

    if coalCount and coalCount >= Config.Smelting.coalPerBatch and propaneCount and propaneCount > 0 then
        local fuelOptions = {
            {
                title = ('Coal (%d available, uses %d)'):format(coalCount, Config.Smelting.coalPerBatch),
                icon = 'fas fa-cube',
                onSelect = function()
                    executeSmelting(ore, amount, 'coal')
                end,
            },
            {
                title = 'Propane Canister (uses 1 charge)',
                icon = 'fas fa-gas-pump',
                onSelect = function()
                    executeSmelting(ore, amount, 'propane_canister')
                end,
            },
        }

        lib.registerContext({
            id = 'mining_fuel_select',
            title = 'Select Fuel',
            menu = 'mining_furnace',
            options = fuelOptions,
        })
        lib.showContext('mining_fuel_select')
    else
        executeSmelting(ore, amount, fuelType)
    end
end

-----------------------------------------------------------
-- GEM CUTTING
-----------------------------------------------------------

--- Executes the gem cutting workflow: progress -> cut 1 -> cut 2 -> server callback.
---@param gem table
startGemCutting = function(gem)
    local anim = Config.Animations.cutting
    lib.requestAnimDict(anim.dict)

    -- Rough cut phase
    local completed = lib.progressCircle({
        duration = Config.GemCutting.baseTime,
        label = ('Rough cutting %s...'):format(gem.label),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            combat = true,
            car = true,
        },
        anim = {
            dict = anim.dict,
            clip = anim.clip,
            flag = 1,
        },
    })

    if not completed then
        lib.notify({ description = 'Cutting cancelled.', type = 'inform' })
        return
    end

    -- Rough cut minigame
    lib.notify({ description = 'Rough cut — hit the target!', type = 'inform', duration = 2000 })
    Wait(500)
    local cut1Result = PlayMinigame(gem.difficulty)

    -- Fine cut phase
    completed = lib.progressCircle({
        duration = math.floor(Config.GemCutting.baseTime * 0.75),
        label = ('Fine cutting %s...'):format(gem.label),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            combat = true,
            car = true,
        },
        anim = {
            dict = anim.dict,
            clip = anim.clip,
            flag = 1,
        },
    })

    if not completed then
        lib.notify({ description = 'Cutting cancelled. Gem was not consumed.', type = 'inform' })
        return
    end

    -- Fine cut minigame
    lib.notify({ description = 'Fine cut — precision matters!', type = 'inform', duration = 2000 })
    Wait(500)
    local cut2Result = PlayMinigame(gem.difficulty)

    -- Send to server
    local result = lib.callback.await('mining:server:cutGem', false, {
        gemItem = gem.item,
        cut1Result = cut1Result,
        cut2Result = cut2Result,
    })

    if result and result.success then
        lib.notify({
            description = ('%s %s! (%s quality)'):format(result.qualityLabel, result.outputItem, result.quality),
            type = result.quality == 'chipped' and 'error' or 'success',
            duration = 5000,
        })
    elseif result then
        lib.notify({ description = result.reason or 'Cutting failed', type = 'error' })
    end
end

-----------------------------------------------------------
-- EVENT HANDLERS
-----------------------------------------------------------

RegisterNetEvent('mining:client:openFurnace', function()
    local ores = getSmeltableOres()

    if #ores == 0 then
        lib.notify({ description = 'You have no smeltable ore.', type = 'inform' })
        return
    end

    local fuelType = checkFuel()
    if not fuelType then
        lib.notify({ description = 'You need coal (' .. Config.Smelting.coalPerBatch .. ') or a propane canister to smelt.', type = 'error' })
        return
    end

    local options = {}
    for _, ore in ipairs(ores) do
        local maxBatch = math.min(ore.count, Config.Smelting.maxBatch)

        for batch = 1, maxBatch do
            if batch == 1 or batch == maxBatch then
                options[#options + 1] = {
                    title = ('%s x%d'):format(ore.label, batch),
                    description = ('Smelt %d ore -> %s | Fee: $%d | Fuel: %s'):format(
                        batch,
                        ore.output,
                        Config.Smelting.furnaceFee,
                        fuelType == 'coal' and (Config.Smelting.coalPerBatch .. ' coal') or '1 propane use'
                    ),
                    icon = 'fas fa-fire',
                    onSelect = function()
                        startSmelting(ore, batch, fuelType)
                    end,
                }
            end
        end
    end

    lib.registerContext({
        id = 'mining_furnace',
        title = ('Smelting Furnace (Fee: $%d)'):format(Config.Smelting.furnaceFee),
        options = options,
    })
    lib.showContext('mining_furnace')
end)

RegisterNetEvent('mining:client:openCuttingBench', function()
    local gems = getCuttableGems()

    if #gems == 0 then
        lib.notify({ description = 'You have no gems to cut.', type = 'inform' })
        return
    end

    local options = {}
    for _, gem in ipairs(gems) do
        options[#options + 1] = {
            title = ('%s (x%d)'):format(gem.label, gem.count),
            description = ('Cut into %s | Fee: $%d'):format(gem.output, Config.GemCutting.cuttingFee),
            icon = 'fas fa-gem',
            onSelect = function()
                startGemCutting(gem)
            end,
        }
    end

    lib.registerContext({
        id = 'mining_cutting_bench',
        title = ('Gem Cutting Bench (Fee: $%d)'):format(Config.GemCutting.cuttingFee),
        options = options,
    })
    lib.showContext('mining_cutting_bench')
end)
