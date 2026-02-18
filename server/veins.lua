-----------------------------------------------------------
-- DYNAMIC VEIN MANAGEMENT (Server)
-- Handles vein generation, depletion, regeneration,
-- and serving vein data to clients.
-----------------------------------------------------------

-----------------------------------------------------------
-- STATE
-----------------------------------------------------------

-- In-memory vein cache: veinCache[subZoneName] = { {id, subZone, oreType, coords, totalQuantity, remaining, quality, depletedAt}, ... }
local veinCache = {}

-----------------------------------------------------------
-- HELPERS
-----------------------------------------------------------

--- Looks up a sub-zone config by name.
---@param subZoneName string
---@return table|nil subZone, string|nil zoneName
local function findSubZone(subZoneName)
    for zoneName, zoneData in pairs(Config.Zones) do
        for _, sz in ipairs(zoneData.subZones) do
            if sz.name == subZoneName then
                return sz, zoneName
            end
        end
    end
    return nil, nil
end

--- Rolls an ore type from a sub-zone's ore distribution table.
---@param distribution table<string, number>
---@return string
local function rollOreType(distribution)
    local total = 0
    for _, weight in pairs(distribution) do
        total = total + weight
    end

    local roll = math.random(1, total)
    local cumulative = 0
    for oreType, weight in pairs(distribution) do
        cumulative = cumulative + weight
        if roll <= cumulative then
            return oreType
        end
    end

    -- Fallback
    for oreType in pairs(distribution) do
        return oreType
    end
end

--- Generates a random position within a sub-zone's spawnArea bounds.
---@param spawnArea table {min=vec3, max=vec3}
---@return vec3
local function randomPosition(spawnArea)
    local x = spawnArea.min.x + math.random() * (spawnArea.max.x - spawnArea.min.x)
    local y = spawnArea.min.y + math.random() * (spawnArea.max.y - spawnArea.min.y)
    local z = spawnArea.min.z + math.random() * (spawnArea.max.z - spawnArea.min.z)
    return vec3(x, y, z)
end

--- Checks if a position is far enough from all existing veins in the sub-zone.
---@param pos vec3
---@param existingVeins table[]
---@param minDist number
---@return boolean
local function hasMinSpacing(pos, existingVeins, minDist)
    for _, vein in ipairs(existingVeins) do
        if not vein.depletedAt then
            local dx = pos.x - vein.coords.x
            local dy = pos.y - vein.coords.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < minDist then
                return false
            end
        end
    end
    return true
end

-----------------------------------------------------------
-- VEIN GENERATION
-----------------------------------------------------------

--- Creates a single vein in the database and returns its data.
---@param subZoneName string
---@param oreType string
---@param coords vec3
---@return table vein
local function createVeinInDB(subZoneName, oreType, coords)
    local quantity = math.random(Config.Veins.quantityMin, Config.Veins.quantityMax)
    local quality = math.random(Config.Veins.qualityMin, Config.Veins.qualityMax)

    local id = MySQL.insert.await([[
        INSERT INTO mining_veins (sub_zone, ore_type, x, y, z, total_quantity, remaining, quality)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], { subZoneName, oreType, coords.x, coords.y, coords.z, quantity, quantity, quality })

    return {
        id = id,
        subZone = subZoneName,
        oreType = oreType,
        coords = coords,
        totalQuantity = quantity,
        remaining = quantity,
        quality = quality,
        depletedAt = nil,
    }
end

--- Generates veins for a sub-zone up to its veinDensity target.
--- Only creates veins to fill up to the target count of non-depleted veins.
---@param subZone table
local function generateVeinsForSubZone(subZone)
    if not subZone.spawnArea then return end

    local subZoneName = subZone.name
    local existing = veinCache[subZoneName] or {}
    veinCache[subZoneName] = existing

    -- Count active (non-depleted) veins
    local activeCount = 0
    for _, vein in ipairs(existing) do
        if not vein.depletedAt then
            activeCount = activeCount + 1
        end
    end

    local target = subZone.veinDensity or 3
    local needed = target - activeCount
    if needed <= 0 then return end

    local minSpacing = Config.Veins.minSpacing
    local maxAttempts = 20 -- prevent infinite loop on tight spaces

    for _ = 1, needed do
        local oreType = rollOreType(subZone.oreDistribution)
        local placed = false

        for _ = 1, maxAttempts do
            local pos = randomPosition(subZone.spawnArea)
            if hasMinSpacing(pos, existing, minSpacing) then
                local vein = createVeinInDB(subZoneName, oreType, pos)
                existing[#existing + 1] = vein
                placed = true
                break
            end
        end

        if not placed then
            -- Fallback: place anyway at a random position if spacing fails
            local pos = randomPosition(subZone.spawnArea)
            local vein = createVeinInDB(subZoneName, oreType, pos)
            existing[#existing + 1] = vein
        end
    end
end

-----------------------------------------------------------
-- CACHE LOADING
-----------------------------------------------------------

--- Loads all non-regenerated veins from database into memory.
local function loadVeinsFromDB()
    local rows = MySQL.query.await([[
        SELECT id, sub_zone, ore_type, x, y, z, total_quantity, remaining, quality, depleted_at
        FROM mining_veins
    ]])

    veinCache = {}

    if rows then
        for _, row in ipairs(rows) do
            local subZoneName = row.sub_zone
            if not veinCache[subZoneName] then
                veinCache[subZoneName] = {}
            end

            veinCache[subZoneName][#veinCache[subZoneName] + 1] = {
                id = row.id,
                subZone = subZoneName,
                oreType = row.ore_type,
                coords = vec3(row.x, row.y, row.z),
                totalQuantity = row.total_quantity,
                remaining = row.remaining,
                quality = row.quality,
                depletedAt = row.depleted_at,
            }
        end
    end
end

-----------------------------------------------------------
-- VEIN DEPLETION
-----------------------------------------------------------

--- Depletes a vein by 1 extraction. If remaining hits 0, marks as depleted.
--- Returns the updated vein data, or nil if vein not found/already depleted.
---@param veinId number
---@return table|nil vein
function DepleteVein(veinId)
    -- Find vein in cache
    for subZoneName, veins in pairs(veinCache) do
        for i, vein in ipairs(veins) do
            if vein.id == veinId then
                if vein.depletedAt or vein.remaining <= 0 then
                    return nil -- already depleted
                end

                vein.remaining = vein.remaining - 1

                if vein.remaining <= 0 then
                    vein.depletedAt = os.date('%Y-%m-%d %H:%M:%S')
                    MySQL.update.await([[
                        UPDATE mining_veins SET remaining = 0, depleted_at = NOW()
                        WHERE id = ?
                    ]], { veinId })

                    -- Notify all clients in this sub-zone that this vein is gone
                    TriggerClientEvent('mining:client:veinDepleted', -1, veinId, subZoneName)
                else
                    MySQL.update.await([[
                        UPDATE mining_veins SET remaining = ?
                        WHERE id = ?
                    ]], { vein.remaining, veinId })

                    -- Notify clients of updated remaining count
                    TriggerClientEvent('mining:client:veinUpdated', -1, veinId, subZoneName, vein.remaining)
                end

                return vein
            end
        end
    end

    return nil
end

--- Gets a vein by ID from cache.
---@param veinId number
---@return table|nil vein
function GetVein(veinId)
    for _, veins in pairs(veinCache) do
        for _, vein in ipairs(veins) do
            if vein.id == veinId then
                return vein
            end
        end
    end
    return nil
end

-----------------------------------------------------------
-- VEIN REGENERATION
-----------------------------------------------------------

--- Checks for depleted veins past their regen timer, removes them,
--- and generates new veins to fill density targets.
local function regenerateVeins()
    local now = os.time()
    local regenMin = Config.VeinRegeneration.regenMinTime / 1000 -- convert ms to seconds
    local regenMax = Config.VeinRegeneration.regenMaxTime / 1000

    local regenerated = false

    for subZoneName, veins in pairs(veinCache) do
        local i = 1
        while i <= #veins do
            local vein = veins[i]
            if vein.depletedAt then
                -- Parse depleted_at timestamp
                local depletedTime = nil
                if type(vein.depletedAt) == 'string' then
                    local pattern = '(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)'
                    local y, m, d, h, mi, s = vein.depletedAt:match(pattern)
                    if y then
                        depletedTime = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = tonumber(h), min = tonumber(mi), sec = tonumber(s) })
                    end
                end

                if depletedTime then
                    local elapsed = now - depletedTime
                    -- Use a random regen time between min and max for this vein
                    local regenTime = regenMin + math.random() * (regenMax - regenMin)
                    if elapsed >= regenTime then
                        -- Remove from DB and cache
                        MySQL.update.await([[
                            DELETE FROM mining_veins WHERE id = ?
                        ]], { vein.id })
                        table.remove(veins, i)
                        regenerated = true
                        -- Don't increment i since table.remove shifts elements
                    else
                        i = i + 1
                    end
                else
                    i = i + 1
                end
            else
                i = i + 1
            end
        end
    end

    -- Generate new veins to fill density targets
    if regenerated then
        for _, zoneData in pairs(Config.Zones) do
            for _, subZone in ipairs(zoneData.subZones) do
                generateVeinsForSubZone(subZone)
            end
        end

        -- Notify all clients to refresh veins
        TriggerClientEvent('mining:client:veinsRefreshed', -1)
    end
end

-----------------------------------------------------------
-- ADMIN HELPERS
-----------------------------------------------------------

--- Returns a summary of active veins per sub-zone (used by admin commands).
---@return table[] { subZone, active, total }
function GetVeinSummary()
    local summary = {}
    for subZoneName, veins in pairs(veinCache) do
        local active = 0
        for _, vein in ipairs(veins) do
            if not vein.depletedAt and vein.remaining > 0 then
                active = active + 1
            end
        end
        summary[#summary + 1] = {
            subZone = subZoneName,
            active = active,
            total = #veins,
        }
    end
    table.sort(summary, function(a, b) return a.subZone < b.subZone end)
    return summary
end

-----------------------------------------------------------
-- CLIENT DATA CALLBACKS
-----------------------------------------------------------

--- Returns active (non-depleted) veins for a sub-zone.
--- Client calls this when entering a sub-zone or on refresh.
lib.callback.register('mining:server:getVeins', function(src, subZoneName)
    local veins = veinCache[subZoneName]
    if not veins then return {} end

    local result = {}
    for _, vein in ipairs(veins) do
        if not vein.depletedAt and vein.remaining > 0 then
            result[#result + 1] = {
                id = vein.id,
                oreType = vein.oreType,
                x = vein.coords.x,
                y = vein.coords.y,
                z = vein.coords.z,
                remaining = vein.remaining,
                totalQuantity = vein.totalQuantity,
                quality = vein.quality,
            }
        end
    end

    return result
end)

--- Returns basic vein info (ore type, quality) for a single vein.
--- Used by client before starting the mining progress bar.
lib.callback.register('mining:server:getVeinInfo', function(src, veinId)
    local vein = GetVein(veinId)
    if not vein or vein.depletedAt or vein.remaining <= 0 then
        return nil
    end

    return {
        oreType = vein.oreType,
        quality = vein.quality,
        remaining = vein.remaining,
    }
end)

-----------------------------------------------------------
-- INITIALIZATION
-----------------------------------------------------------

CreateThread(function()
    -- Wait for DB to be ready
    Wait(1000)

    -- Load existing veins from database
    loadVeinsFromDB()

    -- Generate missing veins for all sub-zones
    for _, zoneData in pairs(Config.Zones) do
        for _, subZone in ipairs(zoneData.subZones) do
            generateVeinsForSubZone(subZone)
        end
    end

    print('[free-mining] Dynamic veins initialized')

    -- Regeneration loop
    while true do
        Wait(Config.VeinRegeneration.checkInterval)
        regenerateVeins()
    end
end)
