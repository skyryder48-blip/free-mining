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

return DB
