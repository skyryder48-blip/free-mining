local DB = {}

--- Ensures a player has a mining_stats row. Creates one if missing.
---@param citizenId string
function DB.EnsurePlayer(citizenId)
    MySQL.insert.await([[
        INSERT IGNORE INTO mining_stats (player_id) VALUES (?)
    ]], { citizenId })
end

--- Fetches a player's mining stats.
---@param citizenId string
---@return table|nil
function DB.GetStats(citizenId)
    return MySQL.single.await([[
        SELECT * FROM mining_stats WHERE player_id = ?
    ]], { citizenId })
end

--- Awards experience and increments total_mined.
---@param citizenId string
---@param xp number
---@param oreMined number
function DB.AddMiningProgress(citizenId, xp, oreMined)
    MySQL.update.await([[
        UPDATE mining_stats
        SET experience = experience + ?,
            total_mined = total_mined + ?
        WHERE player_id = ?
    ]], { xp, oreMined, citizenId })
end

--- Adds to total_earned.
---@param citizenId string
---@param amount number
function DB.AddEarnings(citizenId, amount)
    MySQL.update.await([[
        UPDATE mining_stats
        SET total_earned = total_earned + ?
        WHERE player_id = ?
    ]], { amount, citizenId })
end

--- Gets a player's rank based on total_earned (1 = highest earner).
---@param citizenId string
---@return number|nil rank
function DB.GetPlayerRank(citizenId)
    local result = MySQL.scalar.await([[
        SELECT ranking FROM (
            SELECT player_id,
                   ROW_NUMBER() OVER (ORDER BY total_earned DESC) AS ranking
            FROM mining_stats
        ) ranked
        WHERE player_id = ?
    ]], { citizenId })
    return result
end

--- Sets player level and experience directly (used on level-up recalculation).
---@param citizenId string
---@param level number
---@param experience number
function DB.SetLevel(citizenId, level, experience)
    MySQL.update.await([[
        UPDATE mining_stats
        SET level = ?, experience = ?
        WHERE player_id = ?
    ]], { level, experience, citizenId })
end

-----------------------------------------------------------
-- ADMIN (Phase 8)
-----------------------------------------------------------

--- Resets a player's mining stats to defaults.
---@param citizenId string
function DB.ResetStats(citizenId)
    MySQL.update.await([[
        UPDATE mining_stats
        SET level = 1, experience = 0, total_mined = 0, total_earned = 0
        WHERE player_id = ?
    ]], { citizenId })
end

--- Gets a server-wide economy summary.
---@return table
function DB.GetEconomySummary()
    local result = MySQL.single.await([[
        SELECT
            COUNT(*) AS totalPlayers,
            COALESCE(SUM(total_mined), 0) AS totalMined,
            COALESCE(SUM(total_earned), 0) AS totalEarned,
            COALESCE(AVG(level), 1) AS avgLevel
        FROM mining_stats
    ]])

    local discoveries = MySQL.scalar.await([[
        SELECT COUNT(*) FROM mining_discoveries
    ]]) or 0

    return {
        totalPlayers = result and result.totalPlayers or 0,
        totalMined = result and result.totalMined or 0,
        totalEarned = result and result.totalEarned or 0,
        avgLevel = result and result.avgLevel or 1,
        totalDiscoveries = discoveries,
    }
end

-----------------------------------------------------------
-- CONTRACTS (Phase 7)
-----------------------------------------------------------

--- Gets a player's active contracts.
---@param citizenId string
---@return table[]
function DB.GetActiveContracts(citizenId)
    return MySQL.query.await([[
        SELECT * FROM mining_contracts
        WHERE player_id = ? AND status = 'active' AND expires_at > NOW()
        ORDER BY accepted_at ASC
    ]], { citizenId }) or {}
end

--- Gets a player's completed contracts count for today.
---@param citizenId string
---@return number
function DB.GetTodayCompletedCount(citizenId)
    return MySQL.scalar.await([[
        SELECT COUNT(*) FROM mining_contracts
        WHERE player_id = ? AND status = 'completed'
          AND DATE(completed_at) = CURDATE()
    ]], { citizenId }) or 0
end

--- Creates a new contract for a player.
---@param citizenId string
---@param contractType string
---@param tier string
---@param label string
---@param target number
---@param extraData string|nil
---@param expiresAt string MySQL TIMESTAMP string
---@return number|nil insertId
function DB.CreateContract(citizenId, contractType, tier, label, target, extraData, expiresAt)
    return MySQL.insert.await([[
        INSERT INTO mining_contracts (player_id, contract_type, tier, label, target, extra_data, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { citizenId, contractType, tier, label, target, extraData, expiresAt })
end

--- Updates progress on a contract.
---@param contractId number
---@param amount number amount to add
---@return number newProgress
function DB.AddContractProgress(contractId, amount)
    MySQL.update.await([[
        UPDATE mining_contracts
        SET progress = progress + ?
        WHERE id = ? AND status = 'active'
    ]], { amount, contractId })

    return MySQL.scalar.await([[
        SELECT progress FROM mining_contracts WHERE id = ?
    ]], { contractId }) or 0
end

--- Marks a contract as completed.
---@param contractId number
function DB.CompleteContract(contractId)
    MySQL.update.await([[
        UPDATE mining_contracts
        SET status = 'completed', completed_at = NOW()
        WHERE id = ?
    ]], { contractId })
end

--- Expires old contracts that passed their deadline.
---@param citizenId string
function DB.ExpireContracts(citizenId)
    MySQL.update.await([[
        UPDATE mining_contracts
        SET status = 'expired'
        WHERE player_id = ? AND status = 'active' AND expires_at <= NOW()
    ]], { citizenId })
end

--- Gets a count of active contracts for a player.
---@param citizenId string
---@return number
function DB.CountActiveContracts(citizenId)
    return MySQL.scalar.await([[
        SELECT COUNT(*) FROM mining_contracts
        WHERE player_id = ? AND status = 'active' AND expires_at > NOW()
    ]], { citizenId }) or 0
end

-----------------------------------------------------------
-- RARE FINDS / DISCOVERIES (Phase 7)
-----------------------------------------------------------

--- Records a rare find discovery.
---@param citizenId string
---@param item string
---@param zone string|nil
---@param sellBonusUntil string|nil MySQL TIMESTAMP
---@return number|nil insertId
function DB.RecordDiscovery(citizenId, item, zone, sellBonusUntil)
    return MySQL.insert.await([[
        INSERT INTO mining_discoveries (player_id, item, zone, sell_bonus_until)
        VALUES (?, ?, ?, ?)
    ]], { citizenId, item, zone, sellBonusUntil })
end

--- Gets a player's active sell bonus (if any).
---@param citizenId string
---@return table|nil { item, sell_bonus_until }
function DB.GetActiveSellBonus(citizenId)
    return MySQL.single.await([[
        SELECT item, sell_bonus_until FROM mining_discoveries
        WHERE player_id = ? AND sell_bonus_until > NOW()
        ORDER BY sell_bonus_until DESC
        LIMIT 1
    ]], { citizenId })
end

--- Gets the most recent server-wide discoveries.
---@param limit number
---@return table[]
function DB.GetRecentDiscoveries(limit)
    return MySQL.query.await([[
        SELECT player_id, item, zone, discovered_at
        FROM mining_discoveries
        ORDER BY discovered_at DESC
        LIMIT ?
    ]], { limit or 5 }) or {}
end

--- Gets total discovery count for a player.
---@param citizenId string
---@return number
function DB.GetDiscoveryCount(citizenId)
    return MySQL.scalar.await([[
        SELECT COUNT(*) FROM mining_discoveries WHERE player_id = ?
    ]], { citizenId }) or 0
end

return DB
