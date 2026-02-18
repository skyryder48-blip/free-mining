-----------------------------------------------------------
-- MINING HUD CLIENT
-- Manages the persistent HUD display, stats panel,
-- XP gain notifications, and level-up celebrations.
-----------------------------------------------------------

-----------------------------------------------------------
-- STATE
-----------------------------------------------------------

local hudVisible = false
local statsPanelOpen = false
local cachedStats = nil          -- last known stats from server
local lastRefreshTime = 0        -- GetGameTimer() of last server sync
local previousLevel = nil        -- for detecting level-ups

-----------------------------------------------------------
-- HELPERS
-----------------------------------------------------------

--- Calculates XP progress for a given level and total experience.
---@param level number
---@param totalXp number
---@return number xpIntoCurrentLevel, number xpNeededForLevel, number percent
local function calcXpProgress(level, totalXp)
    local xpPerLevel = Config.Leveling.xpPerLevel
    local maxLevel = Config.Leveling.maxLevel

    if level >= maxLevel then
        return 0, 0, 100
    end

    -- XP needed to reach current level: (level - 1) * xpPerLevel
    local xpForCurrentLevel = (level - 1) * xpPerLevel
    local xpInto = totalXp - xpForCurrentLevel
    local xpNeeded = xpPerLevel

    local percent = math.min(100, (xpInto / xpNeeded) * 100)
    return xpInto, xpNeeded, percent
end

--- Gets a friendly zone display name from the sub-zone and parent zone.
---@return string
local function getZoneDisplayName()
    local subZoneName = GetActiveZone()
    local zoneKey = GetActiveZoneKey()

    if not subZoneName or not zoneKey then
        return '---'
    end

    local zoneData = Config.Zones[zoneKey]
    if not zoneData then return subZoneName end

    -- Find sub-zone label
    for _, sz in ipairs(zoneData.subZones) do
        if sz.name == subZoneName then
            return ('%s - %s'):format(zoneData.label, sz.label)
        end
    end

    return zoneData.label
end

-----------------------------------------------------------
-- HUD DISPLAY
-----------------------------------------------------------

--- Sends HUD data to NUI for display.
local function refreshHudDisplay()
    if not hudVisible then return end
    if not cachedStats then return end

    local level = cachedStats.level or 1
    local totalXp = cachedStats.experience or 0
    local xpInto, xpNeeded, xpPercent = calcXpProgress(level, totalXp)

    SendNUIMessage({
        action = 'updateHud',
        zoneName = getZoneDisplayName(),
        level = level,
        xpCurrent = xpInto,
        xpNeeded = xpNeeded,
        xpPercent = xpPercent,
        totalMined = cachedStats.total_mined or 0,
        totalEarned = cachedStats.total_earned or 0,
        prestige = cachedStats.prestige or 0,
    })
end

--- Shows the mining HUD.
local function showHud()
    if hudVisible then return end
    hudVisible = true

    -- Fetch latest stats
    cachedStats = lib.callback.await('mining:server:getStats', false)

    local level = cachedStats and cachedStats.level or 1
    local totalXp = cachedStats and cachedStats.experience or 0
    local xpInto, xpNeeded, xpPercent = calcXpProgress(level, totalXp)

    previousLevel = level

    -- Convert position format for CSS class
    local position = Config.HUD.position or 'bottom-right'

    SendNUIMessage({
        action = 'showHud',
        position = position,
        compact = Config.HUD.compactMode,
        zoneName = getZoneDisplayName(),
        level = level,
        xpCurrent = xpInto,
        xpNeeded = xpNeeded,
        xpPercent = xpPercent,
        totalMined = cachedStats and cachedStats.total_mined or 0,
        totalEarned = cachedStats and cachedStats.total_earned or 0,
        prestige = cachedStats and cachedStats.prestige or 0,
    })
end

--- Hides the mining HUD.
local function hideHud()
    if not hudVisible then return end
    hudVisible = false

    SendNUIMessage({ action = 'hideHud' })
end

-----------------------------------------------------------
-- STATS PANEL
-----------------------------------------------------------

--- Opens the full stats panel overlay (with NUI focus).
function OpenStatsPanel()
    if statsPanelOpen then return end

    -- Fetch fresh stats
    cachedStats = lib.callback.await('mining:server:getStatsWithRank', false)
    if not cachedStats then
        lib.notify({ description = 'Could not load stats.', type = 'error' })
        return
    end

    statsPanelOpen = true

    local level = cachedStats.level or 1
    local totalXp = cachedStats.experience or 0
    local xpInto, xpNeeded, xpPercent = calcXpProgress(level, totalXp)
    local xpToNext = math.max(0, xpNeeded - xpInto)

    if level >= Config.Leveling.maxLevel then
        xpToNext = 0
    end

    SetNuiFocus(true, true)

    -- Resolve specialization label
    local specLabel = nil
    if cachedStats.specialization and Config.Specializations then
        local specDef = Config.Specializations.specs[cachedStats.specialization]
        specLabel = specDef and specDef.label or cachedStats.specialization
    end

    SendNUIMessage({
        action = 'showStats',
        level = level,
        xpCurrent = xpInto,
        xpNeeded = xpNeeded,
        xpPercent = xpPercent,
        xpToNext = xpToNext,
        totalMined = cachedStats.total_mined or 0,
        totalEarned = cachedStats.total_earned or 0,
        rank = cachedStats.rank or '--',
        totalXp = totalXp,
        prestige = cachedStats.prestige or 0,
        specialization = specLabel,
        achievementCount = cachedStats.achievementCount or 0,
        achievementTotal = cachedStats.achievementTotal or 0,
    })
end

--- Closes the stats panel.
local function closeStatsPanel()
    if not statsPanelOpen then return end
    statsPanelOpen = false

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideStats' })
end

--- NUI callback when stats panel is closed.
RegisterNUICallback('statsClose', function(_, cb)
    closeStatsPanel()
    cb('ok')
end)

-----------------------------------------------------------
-- XP GAIN NOTIFICATION
-----------------------------------------------------------

--- Shows a floating +XP notification near the HUD.
---@param amount number XP gained
function ShowXpGain(amount)
    if not Config.HUD.showXpGain then return end
    if not hudVisible then return end
    if not amount or amount <= 0 then return end

    SendNUIMessage({
        action = 'xpGain',
        amount = amount,
    })
end

-----------------------------------------------------------
-- LEVEL UP DETECTION & CELEBRATION
-----------------------------------------------------------

--- Called after stats refresh to detect level-ups.
local function checkForLevelUp()
    if not cachedStats then return end

    local currentLevel = cachedStats.level or 1

    if previousLevel and currentLevel > previousLevel then
        -- Level up detected!
        if Config.HUD.levelUpEffect then
            local totalXp = cachedStats.experience or 0
            local xpInto, xpNeeded, xpPercent = calcXpProgress(currentLevel, totalXp)

            SendNUIMessage({
                action = 'levelUp',
                level = currentLevel,
                xpCurrent = xpInto,
                xpNeeded = xpNeeded,
                xpPercent = xpPercent,
                totalMined = cachedStats.total_mined or 0,
                totalEarned = cachedStats.total_earned or 0,
            })
        end

        if Config.HUD.levelUpSound then
            PlaySoundFrontend(-1, 'RANK_UP', 'HUD_AWARDS', false)
        end
    end

    previousLevel = currentLevel
end

-----------------------------------------------------------
-- PERIODIC STATS REFRESH
-----------------------------------------------------------

CreateThread(function()
    while true do
        Wait(Config.HUD.refreshInterval or 15000)

        if hudVisible and not statsPanelOpen then
            local now = GetGameTimer()
            -- Only refresh if enough time has passed
            if (now - lastRefreshTime) >= (Config.HUD.refreshInterval or 15000) then
                lastRefreshTime = now
                cachedStats = lib.callback.await('mining:server:getStats', false)
                checkForLevelUp()
                refreshHudDisplay()
            end
        end
    end
end)

-----------------------------------------------------------
-- ZONE ENTER/EXIT HOOKS
-----------------------------------------------------------

--- Called by zones.lua when entering a mining zone.
function OnMiningZoneEnter()
    if not Config.HUD.enabled then return end
    if not Config.HUD.autoToggle then return end
    showHud()
end

--- Called by zones.lua when exiting a mining zone.
function OnMiningZoneExit()
    if not Config.HUD.autoToggle then return end
    hideHud()
end

-----------------------------------------------------------
-- MANUAL REFRESH (called after mining/selling/etc.)
-----------------------------------------------------------

--- Triggers a quick stats refresh and updates the HUD.
--- Called from mining.lua, processing.lua, etc. after actions.
function RefreshMiningHud()
    if not hudVisible then return end

    CreateThread(function()
        cachedStats = lib.callback.await('mining:server:getStats', false)
        lastRefreshTime = GetGameTimer()
        checkForLevelUp()
        refreshHudDisplay()
    end)
end

-----------------------------------------------------------
-- CHAT COMMAND
-----------------------------------------------------------

RegisterCommand('miningstats', function()
    OpenStatsPanel()
end, false)

TriggerEvent('chat:addSuggestion', '/miningstats', 'View your mining profile and statistics')

-----------------------------------------------------------
-- CLEANUP
-----------------------------------------------------------

function CleanupHud()
    hideHud()
    if statsPanelOpen then
        closeStatsPanel()
    end
    cachedStats = nil
    previousLevel = nil
end
