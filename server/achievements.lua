-----------------------------------------------------------
-- ACHIEVEMENT TRACKING SERVER
-- Checks and awards achievements after various game events.
-----------------------------------------------------------

local DB = require 'server.database'

-----------------------------------------------------------
-- ACHIEVEMENT CHECKER
-----------------------------------------------------------

--- Checks all achievements for a player and awards any newly completed ones.
--- Called after mining, selling, leveling up, processing, etc.
---@param src number
---@param citizenId string
function CheckAchievements(src, citizenId)
    local stats = DB.GetStats(citizenId)
    if not stats then return end

    local unlocked = DB.GetAchievements(citizenId)
    local unlockedSet = {}
    for _, key in ipairs(unlocked) do
        unlockedSet[key] = true
    end

    local counters = nil -- lazy-loaded
    local discoveryCount = nil -- lazy-loaded

    for _, ach in ipairs(Config.Achievements.list) do
        if not unlockedSet[ach.key] then
            local progress = 0
            local target = ach.target or 1

            if ach.check == 'total_mined' then
                progress = stats.total_mined or 0
            elseif ach.check == 'total_earned' then
                progress = stats.total_earned or 0
            elseif ach.check == 'discoveries' then
                if not discoveryCount then
                    discoveryCount = DB.GetDiscoveryCount(citizenId)
                end
                progress = discoveryCount
            elseif ach.check == 'level' then
                progress = stats.level or 1
            elseif ach.check == 'event' then
                if not counters then
                    counters = DB.GetCounters(citizenId)
                end
                progress = counters[ach.event] or 0
            end

            if progress >= target then
                DB.UnlockAchievement(citizenId, ach.key)

                -- Award XP
                if ach.xpReward and ach.xpReward > 0 then
                    DB.AddMiningProgress(citizenId, ach.xpReward, 0)
                    checkLevelUp(src, citizenId)
                end

                TriggerClientEvent('mining:client:achievementUnlocked', src, {
                    key = ach.key,
                    label = ach.label,
                    description = ach.description,
                    xpReward = ach.xpReward,
                })
            end
        end
    end
end

--- Increments an event counter and checks achievements.
--- Call this from other server scripts when trackable events occur.
---@param src number
---@param citizenId string
---@param counterKey string
---@param amount number|nil defaults to 1
function TrackAchievementEvent(src, citizenId, counterKey, amount)
    DB.IncrementCounter(citizenId, counterKey, amount or 1)
    CheckAchievements(src, citizenId)
end
