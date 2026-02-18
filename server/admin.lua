-----------------------------------------------------------
-- ADMIN & ECONOMY SERVER
-- Admin commands for managing economy multipliers,
-- player lookups, stat resets, and server economy overview.
-- Requires ACE permission: mining.admin
-----------------------------------------------------------

local DB = require 'server.database'

-----------------------------------------------------------
-- LIVE ECONOMY MULTIPLIERS (in-memory, adjustable at runtime)
-----------------------------------------------------------

local multipliers = {}

--- Initializes multipliers from config defaults.
local function initMultipliers()
    for key, val in pairs(Config.Admin.defaultMultipliers) do
        multipliers[key] = val
    end
end

--- Gets a live multiplier value.
---@param key string
---@return number
function GetMultiplier(key)
    return multipliers[key] or 1.0
end

--- Sets a live multiplier value.
---@param key string
---@param value number
function SetMultiplier(key, value)
    multipliers[key] = value
end

-----------------------------------------------------------
-- ACE CHECK
-----------------------------------------------------------

---@param src number
---@return boolean
local function isAdmin(src)
    return IsPlayerAceAllowed(tostring(src), Config.Admin.acePermission)
end

-----------------------------------------------------------
-- ADMIN COMMANDS
-----------------------------------------------------------

--- /miningadmin - main admin command hub
RegisterCommand('miningadmin', function(src, args)
    if src > 0 and not isAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { description = 'No permission.', type = 'error' })
        return
    end

    local sub = args[1]
    if not sub then
        local msg = {
            '^3=== Mining Admin Commands ===^0',
            '/miningadmin multipliers         - View current economy multipliers',
            '/miningadmin setmult <key> <val> - Set a multiplier (xp, yield, sellPrice, hazardRate, rareChance)',
            '/miningadmin resetmult           - Reset all multipliers to defaults',
            '/miningadmin lookup <id>         - View a player\'s mining stats',
            '/miningadmin resetstats <id>     - Reset a player\'s stats (level, XP, totals)',
            '/miningadmin economy             - View server economy summary',
            '/miningadmin veins               - View active vein counts per zone',
            '/miningadmin flags               - View flagged players',
        }
        for _, line in ipairs(msg) do
            if src == 0 then
                print(line:gsub('%^%d', ''))
            else
                TriggerClientEvent('chat:addMessage', src, { args = { line } })
            end
        end
        return
    end

    -- MULTIPLIERS: view current
    if sub == 'multipliers' then
        local msg = '^3Economy Multipliers:^0'
        for key, val in pairs(multipliers) do
            msg = msg .. ('\n  %s = %.2f'):format(key, val)
        end
        if src == 0 then
            print(msg:gsub('%^%d', ''))
        else
            TriggerClientEvent('chat:addMessage', src, { args = { msg } })
        end

    -- SETMULT: change a multiplier
    elseif sub == 'setmult' then
        local key = args[2]
        local val = tonumber(args[3])

        if not key or not val then
            local resp = 'Usage: /miningadmin setmult <key> <value>\nKeys: xp, yield, sellPrice, hazardRate, rareChance'
            if src == 0 then print(resp) else TriggerClientEvent('chat:addMessage', src, { args = { resp } }) end
            return
        end

        if multipliers[key] == nil then
            local resp = 'Invalid key: ' .. key
            if src == 0 then print(resp) else TriggerClientEvent('chat:addMessage', src, { args = { resp } }) end
            return
        end

        val = math.max(0, math.min(10.0, val)) -- clamp to 0-10
        multipliers[key] = val
        local resp = ('^2Set multiplier %s = %.2f^0'):format(key, val)
        if src == 0 then print(resp:gsub('%^%d', '')) else TriggerClientEvent('chat:addMessage', src, { args = { resp } }) end

    -- RESETMULT: reset to defaults
    elseif sub == 'resetmult' then
        initMultipliers()
        local resp = '^2All multipliers reset to defaults.^0'
        if src == 0 then print(resp:gsub('%^%d', '')) else TriggerClientEvent('chat:addMessage', src, { args = { resp } }) end

    -- LOOKUP: view player stats
    elseif sub == 'lookup' then
        local targetCid = args[2]
        if not targetCid then
            local resp = 'Usage: /miningadmin lookup <citizenId or serverId>'
            if src == 0 then print(resp) else TriggerClientEvent('chat:addMessage', src, { args = { resp } }) end
            return
        end

        -- If numeric, treat as server ID and resolve to citizenId
        local cid = targetCid
        local serverId = tonumber(targetCid)
        if serverId then
            local resolved = getCitizenId(serverId)
            if resolved then cid = resolved end
        end

        local stats = DB.GetStats(cid)
        if not stats then
            local resp = '^1No stats found for: ' .. cid .. '^0'
            if src == 0 then print(resp:gsub('%^%d', '')) else TriggerClientEvent('chat:addMessage', src, { args = { resp } }) end
            return
        end

        local rank = DB.GetPlayerRank(cid) or '--'
        local msg = ('^3Mining Stats for %s:^0\n  Level: %d | XP: %d\n  Mined: %d | Earned: $%d\n  Rank: #%s'):format(
            cid, stats.level, stats.experience, stats.total_mined, stats.total_earned, tostring(rank)
        )
        if src == 0 then print(msg:gsub('%^%d', '')) else TriggerClientEvent('chat:addMessage', src, { args = { msg } }) end

    -- RESETSTATS: reset a player's stats
    elseif sub == 'resetstats' then
        local targetCid = args[2]
        if not targetCid then
            local resp = 'Usage: /miningadmin resetstats <citizenId or serverId>'
            if src == 0 then print(resp) else TriggerClientEvent('chat:addMessage', src, { args = { resp } }) end
            return
        end

        local cid = targetCid
        local serverId = tonumber(targetCid)
        if serverId then
            local resolved = getCitizenId(serverId)
            if resolved then cid = resolved end
        end

        DB.ResetStats(cid)
        local resp = ('^2Stats reset for %s^0'):format(cid)
        if src == 0 then print(resp:gsub('%^%d', '')) else TriggerClientEvent('chat:addMessage', src, { args = { resp } }) end

    -- ECONOMY: server-wide economy overview
    elseif sub == 'economy' then
        local summary = DB.GetEconomySummary()
        local msg = '^3=== Mining Economy Summary ===^0'
        msg = msg .. ('\n  Total Players: %d'):format(summary.totalPlayers or 0)
        msg = msg .. ('\n  Total Ore Mined: %s'):format(summary.totalMined or 0)
        msg = msg .. ('\n  Total Money Earned: $%s'):format(summary.totalEarned or 0)
        msg = msg .. ('\n  Avg Level: %.1f'):format(summary.avgLevel or 0)
        msg = msg .. ('\n  Total Rare Finds: %d'):format(summary.totalDiscoveries or 0)
        msg = msg .. '\n^3Active Multipliers:^0'
        for key, val in pairs(multipliers) do
            msg = msg .. ('\n  %s = %.2f'):format(key, val)
        end
        if src == 0 then print(msg:gsub('%^%d', '')) else TriggerClientEvent('chat:addMessage', src, { args = { msg } }) end

    -- VEINS: view active vein counts
    elseif sub == 'veins' then
        local veinInfo = GetVeinSummary and GetVeinSummary() or {}
        local msg = '^3=== Active Veins ===^0'
        if #veinInfo == 0 then
            msg = msg .. '\n  No vein data available.'
        else
            for _, info in ipairs(veinInfo) do
                msg = msg .. ('\n  %s: %d active / %d total'):format(info.subZone, info.active, info.total)
            end
        end
        if src == 0 then print(msg:gsub('%^%d', '')) else TriggerClientEvent('chat:addMessage', src, { args = { msg } }) end

    -- FLAGS: view flagged players
    elseif sub == 'flags' then
        local flags = GetAntiCheatFlags and GetAntiCheatFlags() or {}
        local msg = '^3=== Flagged Players ===^0'
        if #flags == 0 then
            msg = msg .. '\n  No flags.'
        else
            for _, flag in ipairs(flags) do
                msg = msg .. ('\n  ^1[%s]^0 %s - %s (count: %d)'):format(
                    flag.severity, flag.citizenId, flag.reason, flag.count
                )
            end
        end
        if src == 0 then print(msg:gsub('%^%d', '')) else TriggerClientEvent('chat:addMessage', src, { args = { msg } }) end

    else
        local resp = 'Unknown subcommand: ' .. sub .. '. Run /miningadmin for help.'
        if src == 0 then print(resp) else TriggerClientEvent('chat:addMessage', src, { args = { resp } }) end
    end
end, false)

-----------------------------------------------------------
-- INIT
-----------------------------------------------------------

CreateThread(function()
    initMultipliers()
    print('[free-mining] Admin module initialized')
end)
