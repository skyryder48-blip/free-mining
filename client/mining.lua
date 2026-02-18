-----------------------------------------------------------
-- MINING CLIENT
-- Handles mode selection, progress bar, minigame, and
-- server communication for ore extraction.
-----------------------------------------------------------

-----------------------------------------------------------
-- STATE
-----------------------------------------------------------

local isMining = false
local minigameActive = false
local minigamePromise = nil

-----------------------------------------------------------
-- MINIGAME NUI
-----------------------------------------------------------

--- Opens the target zone minigame NUI and returns the result.
--- Global so processing.lua can call it too.
---@param difficulty string 'easy'|'medium'|'hard'|'expert'
---@return string result 'green'|'yellow'|'red'
function PlayMinigame(difficulty)
    local diffConfig = Config.Minigame.difficulty[difficulty] or Config.Minigame.difficulty.medium

    minigameActive = true
    minigamePromise = promise.new()

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'startMinigame',
        greenZone = diffConfig.greenZone,
        yellowZone = diffConfig.yellowZone,
        speed = diffConfig.speed,
    })

    local result = Citizen.Await(minigamePromise)
    minigamePromise = nil
    minigameActive = false

    return result
end

--- Handles minigame result from NUI.
RegisterNUICallback('minigameResult', function(data, cb)
    SetNuiFocus(false, false)
    if minigamePromise then
        minigamePromise:resolve(data.result)
    end
    cb('ok')
end)

--- Handles minigame close/cancel from NUI.
RegisterNUICallback('minigameClose', function(_, cb)
    SetNuiFocus(false, false)
    if minigamePromise then
        minigamePromise:resolve('red')
    end
    cb('ok')
end)

-----------------------------------------------------------
-- MODE SELECTION
-----------------------------------------------------------

--- Shows mining mode context menu and returns selected mode key.
---@return string|nil mode
local function selectMiningMode()
    local modeResult = nil
    local order = { 'aggressive', 'balanced', 'precision' }
    local options = {}

    for _, key in ipairs(order) do
        local mode = Config.MiningModes[key]
        options[#options + 1] = {
            title = mode.label,
            description = mode.description,
            icon = mode.icon,
            onSelect = function()
                modeResult = key
            end,
        }
    end

    lib.registerContext({
        id = 'mining_mode_select',
        title = 'Select Mining Mode',
        options = options,
    })
    lib.showContext('mining_mode_select')

    -- Poll until the context menu closes (selection or manual close)
    while lib.getOpenContextMenu() == 'mining_mode_select' do
        Wait(50)
    end

    return modeResult -- nil if closed without selection, mode key if selected
end

-----------------------------------------------------------
-- MINING FLOW
-----------------------------------------------------------

--- Main mining event triggered by vein interaction.
---@param subZoneName string
---@param veinId number
AddEventHandler('mining:client:startMining', function(subZoneName, veinId)
    if isMining then return end
    if minigameActive then return end

    isMining = true
    LocalPlayer.state:set('isMining', true, false)

    -- Mode selection via context menu
    local mode = selectMiningMode()
    if not mode then
        isMining = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    local modeDef = Config.MiningModes[mode]

    -- Determine which tool the player has (client-side pre-check for UX)
    local toolName = nil
    local toolDef = nil

    for name, def in pairs(Config.Tools) do
        local count = exports.ox_inventory:Search('count', name)
        if count and count > 0 then
            -- Prefer rock_drill if available (it's faster)
            if not toolName or def.speed > (toolDef and toolDef.speed or 0) then
                toolName = name
                toolDef = def
            end
        end
    end

    if not toolName then
        lib.notify({ description = 'You need a pickaxe or rock drill to mine.', type = 'error' })
        isMining = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    -- Get the vein's ore type for timing and difficulty
    local veinData = lib.callback.await('mining:server:getVeinInfo', false, veinId)
    if not veinData then
        lib.notify({ description = 'This vein is no longer available.', type = 'error' })
        isMining = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    local oreDef = Config.Ores[veinData.oreType]
    local mineTime = (oreDef and oreDef.mineTime or 6000)

    -- Apply tool speed and mode modifier
    mineTime = math.floor(mineTime / toolDef.speed / modeDef.speedMod)

    -- Apply zone speed modifier (Phase 4)
    local zoneSpeedMod = GetActiveZoneSpeedMod()
    if zoneSpeedMod and zoneSpeedMod ~= 1.0 then
        mineTime = math.floor(mineTime / zoneSpeedMod)
    end

    -- Load animation
    local anim = toolDef.anim
    lib.requestAnimDict(anim.dict)

    -- Progress circle with animation
    local oreLabel = oreDef and oreDef.label or veinData.oreType
    local completed = lib.progressCircle({
        duration = mineTime,
        label = ('Mining %s...'):format(oreLabel),
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
        lib.notify({ description = 'Mining cancelled.', type = 'inform' })
        isMining = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    -- Use the vein's ore difficulty for minigame
    local difficulty = oreDef and oreDef.difficulty or 'medium'

    -- Play minigame
    local minigameResult = PlayMinigame(difficulty)

    -- Send to server for validation and reward
    local result = lib.callback.await('mining:server:extract', false, {
        veinId = veinId,
        subZoneName = subZoneName,
        mode = mode,
        minigameResult = minigameResult,
    })

    if result and result.success then
        local resultLabel = minigameResult == 'green' and 'Perfect!' or (minigameResult == 'yellow' and 'Good' or 'Poor')
        local qualityStr = ''
        if result.veinQuality then
            qualityStr = (' (Vein: %d%%)'):format(result.veinQuality)
        end
        lib.notify({
            description = ('%s - Mined %dx %s%s'):format(resultLabel, result.amount, result.oreLabel, qualityStr),
            type = minigameResult == 'red' and 'error' or 'success',
            duration = 4000,
        })
    elseif result then
        lib.notify({ description = result.reason or 'Mining failed', type = 'error' })
    end

    isMining = false
    LocalPlayer.state:set('isMining', false, false)
end)

-----------------------------------------------------------
-- SHOP
-----------------------------------------------------------

AddEventHandler('mining:client:openShop', function()
    local options = {}

    for _, shopItem in ipairs(Config.Shop.items) do
        -- Build item label from tools, equipment, or item name
        local itemLabel = shopItem.item
        if Config.Tools[shopItem.item] then
            itemLabel = Config.Tools[shopItem.item].label
        elseif Config.Equipment[shopItem.item] then
            itemLabel = Config.Equipment[shopItem.item].label
        end

        local desc = ('Buy for $%s'):format(shopItem.price)
        if shopItem.levelRequired then
            desc = ('Buy for $%s (Requires Level %d)'):format(shopItem.price, shopItem.levelRequired)
        end

        options[#options + 1] = {
            title = ('%s - $%s'):format(itemLabel, shopItem.price),
            description = desc,
            icon = 'fas fa-shopping-cart',
            onSelect = function()
                local result = lib.callback.await('mining:server:buyItem', false, {
                    item = shopItem.item,
                    amount = 1,
                })
                if result and result.success then
                    lib.notify({ description = ('Purchased %s for $%s'):format(itemLabel, result.cost), type = 'success' })
                elseif result then
                    lib.notify({ description = result.reason or 'Purchase failed', type = 'error' })
                end
            end,
        }
    end

    lib.registerContext({
        id = 'mining_shop',
        title = Config.Shop.label,
        options = options,
    })
    lib.showContext('mining_shop')
end)

-----------------------------------------------------------
-- BUYER (Sell Items)
-----------------------------------------------------------

AddEventHandler('mining:client:openBuyer', function()
    local options = {}

    for item, price in pairs(Config.SellPrices) do
        local count = exports.ox_inventory:Search('count', item)
        if count and count > 0 then
            options[#options + 1] = {
                title = ('%s x%d - $%s each'):format(item, count, price),
                description = ('Sell all for $%s'):format(price * count),
                icon = 'fas fa-coins',
                onSelect = function()
                    local result = lib.callback.await('mining:server:sell', false, {
                        item = item,
                        amount = count,
                    })
                    if result and result.success then
                        lib.notify({
                            description = ('Sold %dx %s for $%s'):format(result.amount, result.item, result.total),
                            type = 'success',
                        })
                    elseif result then
                        lib.notify({ description = result.reason or 'Sale failed', type = 'error' })
                    end
                end,
            }
        end
    end

    if #options == 0 then
        lib.notify({ description = 'You have nothing to sell.', type = 'inform' })
        return
    end

    lib.registerContext({
        id = 'mining_buyer',
        title = 'Sell Mining Materials',
        options = options,
    })
    lib.showContext('mining_buyer')
end)

-----------------------------------------------------------
-- DRILL BIT USAGE (client handler for server-registered usable item)
-----------------------------------------------------------

RegisterNetEvent('mining:client:useDrillBit', function(data)
    if data.success then
        lib.notify({
            description = ('Drill restored to %d%% durability'):format(data.newDurability),
            type = 'success',
        })
    else
        lib.notify({ description = data.reason or 'Cannot use drill bit', type = 'error' })
    end
end)
