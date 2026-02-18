-----------------------------------------------------------
-- CONTRACTS & RARE FINDS SERVER
-- Handles contract generation, progress tracking, rewards,
-- and rare find rolls during extraction.
-----------------------------------------------------------

local DB = require 'server.database'

-----------------------------------------------------------
-- CONTRACT GENERATION
-----------------------------------------------------------

--- Generates a random contract from the template pool.
---@param tier string 'easy'|'medium'|'hard'
---@return table contract { type, tier, label, target, extraData }
local function generateContract(tier)
    local templates = Config.Contracts.templates
    local template = templates[math.random(#templates)]

    local target = template.target[tier] or template.target.easy

    -- Build label and extra data based on template type
    local label = template.label
    local extraData = nil

    if template.type == 'mine_specific' and template.ores then
        local ore = template.ores[math.random(#template.ores)]
        local oreDef = Config.Ores[ore]
        local oreLabel = oreDef and oreDef.label or ore
        label = label:format(target, oreLabel)
        extraData = ore
    elseif template.type == 'mine_zone' and template.zones then
        local zone = template.zones[math.random(#template.zones)]
        local zoneData = Config.Zones[zone]
        local zoneLabel = zoneData and zoneData.label or zone
        label = label:format(target, zoneLabel)
        extraData = zone
    elseif template.type == 'earn_cash' then
        label = label:format(target)
    else
        label = label:format(target)
    end

    return {
        type = template.type,
        tier = tier,
        label = label,
        target = target,
        extraData = extraData,
    }
end

--- Gets the expiry timestamp (next midnight or configured reset hour).
---@return string MySQL TIMESTAMP
local function getExpiryTimestamp()
    local resetHour = Config.Contracts.refreshHour or 0
    -- Expire at the next occurrence of resetHour
    return MySQL.scalar.await([[
        SELECT DATE_FORMAT(
            IF(HOUR(NOW()) < ?, CURDATE(), CURDATE() + INTERVAL 1 DAY)
            + INTERVAL ? HOUR,
            '%Y-%m-%d %H:%i:%s'
        )
    ]], { resetHour, resetHour })
end

-----------------------------------------------------------
-- CONTRACT CALLBACKS
-----------------------------------------------------------

--- Returns available contracts for the board (generated fresh).
lib.callback.register('mining:server:getContractBoard', function(src)
    local citizenId = getCitizenId(src)
    if not citizenId then return nil end

    -- Expire stale contracts first
    DB.ExpireContracts(citizenId)

    -- Get current active contracts
    local active = DB.GetActiveContracts(citizenId)
    local todayCompleted = DB.GetTodayCompletedCount(citizenId)

    -- Generate the daily board: mix of tiers
    local board = {}
    local count = Config.Contracts.availableCount or 6

    -- Seed randomization per day so all players see same board
    local daySeed = tonumber(os.date('%Y%m%d'))
    math.randomseed(daySeed)

    local tierPool = { 'easy', 'easy', 'medium', 'medium', 'hard', 'hard' }
    for i = 1, count do
        local tier = tierPool[((i - 1) % #tierPool) + 1]
        local contract = generateContract(tier)

        local tierDef = Config.Contracts.tiers[tier]
        contract.xpReward = tierDef.xpReward
        contract.cashReward = tierDef.cashReward

        board[#board + 1] = contract
    end

    -- Restore normal random seed
    math.randomseed(GetGameTimer())

    return {
        board = board,
        active = active,
        todayCompleted = todayCompleted,
        maxActive = Config.Contracts.maxActive,
        completionBonus = Config.Contracts.completionBonus,
    }
end)

--- Accepts a contract from the board.
lib.callback.register('mining:server:acceptContract', function(src, data)
    -- data: { type, tier, label, target, extraData }
    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    -- Check max active
    local activeCount = DB.CountActiveContracts(citizenId)
    if activeCount >= Config.Contracts.maxActive then
        return { success = false, reason = ('Already have %d active contracts (max %d)'):format(activeCount, Config.Contracts.maxActive) }
    end

    local expiresAt = getExpiryTimestamp()
    if not expiresAt then
        return { success = false, reason = 'Server error' }
    end

    local id = DB.CreateContract(citizenId, data.type, data.tier, data.label, data.target, data.extraData, expiresAt)
    if not id then
        return { success = false, reason = 'Failed to create contract' }
    end

    return {
        success = true,
        contractId = id,
        label = data.label,
        tier = data.tier,
    }
end)

--- Returns player's active contracts with progress.
lib.callback.register('mining:server:getActiveContracts', function(src)
    local citizenId = getCitizenId(src)
    if not citizenId then return {} end

    DB.ExpireContracts(citizenId)
    return DB.GetActiveContracts(citizenId)
end)

-----------------------------------------------------------
-- CONTRACT PROGRESS TRACKING
-----------------------------------------------------------

--- Advances progress on all matching contracts for a player.
--- Called from extraction, processing, selling, and explosives flows.
---@param src number
---@param citizenId string
---@param eventType string contract type to match
---@param amount number progress increment
---@param extraData string|nil optional filter (ore name, zone key, etc.)
function AdvanceContracts(src, citizenId, eventType, amount, extraData)
    local active = DB.GetActiveContracts(citizenId)
    if #active == 0 then return end

    for _, contract in ipairs(active) do
        local matches = false

        if contract.contract_type == eventType then
            -- For specific contracts, check extra_data matches
            if eventType == 'mine_specific' or eventType == 'mine_zone' then
                if contract.extra_data == extraData then
                    matches = true
                end
            else
                matches = true
            end
        end

        -- Generic ore mining also counts for 'mine_ore' contracts
        if contract.contract_type == 'mine_ore' and (eventType == 'mine_ore' or eventType == 'mine_specific' or eventType == 'mine_zone') then
            matches = true
        end

        -- Gems mined count for mine_gems
        if contract.contract_type == 'mine_gems' and eventType == 'mine_gems' then
            matches = true
        end

        if matches then
            local newProgress = DB.AddContractProgress(contract.id, amount)

            if newProgress >= contract.target and contract.status == 'active' then
                -- Contract completed!
                DB.CompleteContract(contract.id)

                local tierDef = Config.Contracts.tiers[contract.tier]
                local xpReward = tierDef and tierDef.xpReward or 50
                local cashReward = tierDef and tierDef.cashReward or 500

                -- Award rewards
                DB.AddMiningProgress(citizenId, xpReward, 0)
                checkLevelUp(src, citizenId)

                local player = exports.qbx_core:GetPlayer(src)
                if player then
                    player.Functions.AddMoney('cash', cashReward, 'mining-contract')
                end

                TriggerClientEvent('mining:client:contractCompleted', src, {
                    label = contract.label,
                    tier = contract.tier,
                    xpReward = xpReward,
                    cashReward = cashReward,
                })

                -- Check if all-complete bonus
                local todayCompleted = DB.GetTodayCompletedCount(citizenId)
                local activeRemaining = DB.CountActiveContracts(citizenId)
                if todayCompleted >= Config.Contracts.maxActive and activeRemaining == 0 then
                    local bonus = Config.Contracts.completionBonus
                    DB.AddMiningProgress(citizenId, bonus.xp, 0)
                    checkLevelUp(src, citizenId)

                    if player then
                        player.Functions.AddMoney('cash', bonus.cash, 'mining-contract-bonus')
                    end

                    TriggerClientEvent('mining:client:contractBonusCompleted', src, {
                        xpBonus = bonus.xp,
                        cashBonus = bonus.cash,
                    })
                end
            else
                -- Notify progress update
                TriggerClientEvent('mining:client:contractProgress', src, {
                    contractId = contract.id,
                    label = contract.label,
                    progress = math.min(newProgress, contract.target),
                    target = contract.target,
                })
            end
        end
    end
end

-----------------------------------------------------------
-- RARE FINDS
-----------------------------------------------------------

--- Rolls for a rare find during extraction.
--- Returns the rare item key if found, or nil.
---@param mode string mining mode key
---@param minigameResult string 'green'|'yellow'|'red'
---@param veinQuality number 0-100
---@return string|nil rareItemKey
function RollRareFind(mode, minigameResult, veinQuality)
    if not Config.RareFinds.enabled then return nil end

    local chance = Config.RareFinds.baseChance

    -- Quality bonus: linear scale from 0 to qualityBonus at quality 100
    local qNorm = (veinQuality or 50) / 100
    chance = chance * (1 + qNorm * Config.RareFinds.qualityBonus)

    -- Precision mode bonus
    if mode == 'precision' then
        chance = chance * Config.RareFinds.precisionBonus
    end

    -- Green minigame bonus
    if minigameResult == 'green' then
        chance = chance * Config.RareFinds.greenBonus
    end

    -- Roll
    if math.random() > chance then
        return nil
    end

    -- Select which rare item based on weights
    local items = Config.RareFinds.items
    local totalWeight = 0
    for _, def in pairs(items) do
        totalWeight = totalWeight + def.weight
    end

    local roll = math.random() * totalWeight
    local cumulative = 0
    for key, def in pairs(items) do
        cumulative = cumulative + def.weight
        if roll <= cumulative then
            return key
        end
    end

    return nil
end

--- Processes a rare find: awards item, records discovery, announces.
---@param src number
---@param citizenId string
---@param rareItemKey string
---@param zoneName string|nil
---@return table|nil result
function ProcessRareFind(src, citizenId, rareItemKey, zoneName)
    local rareDef = Config.RareFinds.items[rareItemKey]
    if not rareDef then return nil end

    -- Check inventory space
    if not exports.ox_inventory:CanCarryItem(src, rareItemKey, 1) then
        -- Still announce but notify can't carry
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'RARE FIND!',
            description = ('Found %s but inventory is full!'):format(rareDef.label),
            type = 'error',
            duration = 6000,
        })
        return nil
    end

    -- Award item
    exports.ox_inventory:AddItem(src, rareItemKey, 1, {
        description = rareDef.description,
        rareFind = true,
    })

    -- Calculate sell bonus expiry
    local bonusDuration = Config.RareFinds.sellBonusDuration or 3600
    local sellBonusUntil = MySQL.scalar.await([[
        SELECT DATE_FORMAT(NOW() + INTERVAL ? SECOND, '%Y-%m-%d %H:%i:%s')
    ]], { bonusDuration })

    -- Record discovery
    DB.RecordDiscovery(citizenId, rareItemKey, zoneName, sellBonusUntil)

    -- Award discovery XP
    local discoveryXp = Config.RareFinds.discoveryXp or 50
    DB.AddMiningProgress(citizenId, discoveryXp, 0)
    checkLevelUp(src, citizenId)

    -- Server-wide announcement
    if Config.RareFinds.announceToServer then
        local player = exports.qbx_core:GetPlayer(src)
        local playerName = player and player.PlayerData.charinfo.firstname or 'A miner'
        local zoneLabel = ''
        if zoneName then
            local zoneData = Config.Zones[zoneName]
            zoneLabel = zoneData and (' in %s'):format(zoneData.label) or ''
        end

        local baseData = {
            playerName = playerName,
            itemLabel = rareDef.label,
            itemKey = rareItemKey,
            zoneLabel = zoneLabel,
            discoveryXp = discoveryXp,
        }

        -- Send to discoverer (local = true)
        baseData.isLocal = true
        TriggerClientEvent('mining:client:rareDiscovery', src, baseData)

        -- Send to everyone else (local = false)
        baseData.isLocal = false
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local pid = tonumber(playerId)
            if pid and pid ~= src then
                TriggerClientEvent('mining:client:rareDiscovery', pid, baseData)
            end
        end
    end

    return {
        itemKey = rareItemKey,
        label = rareDef.label,
        xpGained = discoveryXp,
    }
end

-----------------------------------------------------------
-- SELL BONUS CHECK (called from sell callback)
-----------------------------------------------------------

--- Checks if a player has an active rare find sell bonus for an item.
---@param citizenId string
---@param item string
---@return number multiplier (1.0 = no bonus)
function GetRareSellBonus(citizenId, item)
    -- Check if this is a rare find item with active bonus
    if not Config.RareFinds.items[item] then return 1.0 end

    local bonus = DB.GetActiveSellBonus(citizenId)
    if bonus and bonus.item == item then
        return Config.RareFinds.sellBonusMultiplier or 3.0
    end

    return 1.0
end
