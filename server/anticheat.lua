-----------------------------------------------------------
-- ANTI-CHEAT MODULE
-- Rate limiting, hourly stat tracking, and flag management
-- for detecting and preventing mining exploits.
-----------------------------------------------------------

-----------------------------------------------------------
-- STATE
-----------------------------------------------------------

-- Rate limit tracking: rateLimits[citizenId][action] = { timestamps[] }
local rateLimits = {}

-- Hourly stats: hourlyStats[citizenId] = { mined, earned, windowStart }
local hourlyStats = {}

-- Flags: flags[] = { citizenId, reason, severity, count, lastSeen }
local flags = {}

-----------------------------------------------------------
-- RATE LIMITING
-----------------------------------------------------------

--- Records an action and checks rate limits.
--- Returns true if allowed, false if rate-limited.
---@param citizenId string
---@param action string
---@return boolean allowed
function RecordAction(citizenId, action)
    if not Config.AntiCheat or not Config.AntiCheat.enabled then return true end

    local limits = Config.AntiCheat.rateLimits[action]
    if not limits then return true end

    local now = os.time()
    local window = limits.window
    local maxActions = limits.max

    if not rateLimits[citizenId] then rateLimits[citizenId] = {} end
    if not rateLimits[citizenId][action] then rateLimits[citizenId][action] = {} end

    local timestamps = rateLimits[citizenId][action]

    -- Prune timestamps outside the window
    local pruned = {}
    for _, ts in ipairs(timestamps) do
        if (now - ts) < window then
            pruned[#pruned + 1] = ts
        end
    end

    -- Check if over limit
    if #pruned >= maxActions then
        rateLimits[citizenId][action] = pruned
        FlagPlayer(citizenId, 'rate_limit', ('Exceeded %s rate limit: %d/%d in %ds'):format(action, #pruned, maxActions, window))
        return false
    end

    -- Record this action
    pruned[#pruned + 1] = now
    rateLimits[citizenId][action] = pruned
    return true
end

-----------------------------------------------------------
-- HOURLY STAT TRACKING
-----------------------------------------------------------

--- Tracks hourly mining/earning stats for anomaly detection.
---@param citizenId string
---@param oreMined number
---@param cashEarned number
function TrackHourlyStats(citizenId, oreMined, cashEarned)
    if not Config.AntiCheat or not Config.AntiCheat.enabled then return end

    local now = os.time()

    if not hourlyStats[citizenId] then
        hourlyStats[citizenId] = { mined = 0, earned = 0, windowStart = now }
    end

    local stats = hourlyStats[citizenId]

    -- Reset window if older than 1 hour
    if (now - stats.windowStart) >= 3600 then
        stats.mined = 0
        stats.earned = 0
        stats.windowStart = now
    end

    stats.mined = stats.mined + oreMined
    stats.earned = stats.earned + cashEarned

    -- Check thresholds
    local thresholds = Config.AntiCheat.flags
    if thresholds then
        if stats.earned > thresholds.hourlyEarningsThreshold then
            FlagPlayer(citizenId, 'earnings', ('Hourly earnings: $%d (threshold: $%d)'):format(stats.earned, thresholds.hourlyEarningsThreshold))
        end
        if stats.mined > thresholds.hourlyMiningThreshold then
            FlagPlayer(citizenId, 'mining_volume', ('Hourly ore mined: %d (threshold: %d)'):format(stats.mined, thresholds.hourlyMiningThreshold))
        end
    end
end

-----------------------------------------------------------
-- FLAG MANAGEMENT
-----------------------------------------------------------

--- Flags a player for suspicious activity.
---@param citizenId string
---@param reason string short category
---@param detail string full description
function FlagPlayer(citizenId, reason, detail)
    -- Check if this player already has a flag for this reason
    for _, flag in ipairs(flags) do
        if flag.citizenId == citizenId and flag.reason == reason then
            flag.count = flag.count + 1
            flag.lastSeen = os.date('%Y-%m-%d %H:%M:%S')
            flag.detail = detail
            -- Escalate severity based on count
            if flag.count >= 10 then
                flag.severity = 'HIGH'
            elseif flag.count >= 5 then
                flag.severity = 'MEDIUM'
            end
            print(('[free-mining] ^1ANTICHEAT^0 [%s] %s - %s (x%d)'):format(flag.severity, citizenId, detail, flag.count))
            return
        end
    end

    -- New flag
    local flag = {
        citizenId = citizenId,
        reason = reason,
        detail = detail,
        severity = 'LOW',
        count = 1,
        firstSeen = os.date('%Y-%m-%d %H:%M:%S'),
        lastSeen = os.date('%Y-%m-%d %H:%M:%S'),
    }
    flags[#flags + 1] = flag
    print(('[free-mining] ^1ANTICHEAT^0 [LOW] %s - %s'):format(citizenId, detail))
end

--- Returns all current flags (used by admin command).
---@return table[]
function GetAntiCheatFlags()
    return flags
end

--- Clears all flags (admin command).
function ClearAntiCheatFlags()
    flags = {}
end

-----------------------------------------------------------
-- CLEANUP ON PLAYER DROP
-----------------------------------------------------------

AddEventHandler('playerDropped', function()
    local src = source
    local citizenId = getCitizenId(src)
    if citizenId then
        rateLimits[citizenId] = nil
        hourlyStats[citizenId] = nil
    end
end)
