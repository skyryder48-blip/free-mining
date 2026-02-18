-----------------------------------------------------------
-- SKILLS & SPECIALIZATION SERVER
-- Handles specialization choice, skill tree management,
-- prestige system, and skill effect queries.
-----------------------------------------------------------

local DB = require 'server.database'

-----------------------------------------------------------
-- SKILL EFFECT CACHE (per player, cleared on disconnect)
-----------------------------------------------------------

local playerSkillCache = {} -- playerSkillCache[citizenId] = { skills={}, spec=nil, prestige=0 }

--- Invalidates the skill cache for a player.
---@param citizenId string
local function invalidateCache(citizenId)
    playerSkillCache[citizenId] = nil
end

--- Loads and caches a player's skills.
---@param citizenId string
---@return table cache
local function ensureCache(citizenId)
    if playerSkillCache[citizenId] then
        return playerSkillCache[citizenId]
    end

    local skills = DB.GetSkills(citizenId)
    local stats = DB.GetStats(citizenId)

    local skillSet = {}
    for _, key in ipairs(skills) do
        skillSet[key] = true
    end

    playerSkillCache[citizenId] = {
        skills = skillSet,
        spec = stats and stats.specialization or nil,
        prestige = stats and stats.prestige or 0,
    }

    return playerSkillCache[citizenId]
end

-----------------------------------------------------------
-- GLOBAL SKILL QUERIES (used by other server scripts)
-----------------------------------------------------------

--- Checks if a player has a specific skill unlocked.
---@param citizenId string
---@param skillKey string
---@return boolean
function HasPlayerSkill(citizenId, skillKey)
    local cache = ensureCache(citizenId)
    return cache.skills[skillKey] == true
end

--- Gets the cumulative bonus value for a given effect key from all unlocked skills.
---@param citizenId string
---@param effectKey string
---@return number
function GetPlayerSkillBonus(citizenId, effectKey)
    local cache = ensureCache(citizenId)
    local spec = cache.spec
    if not spec then return 0 end

    local tree = Config.SkillTrees[spec]
    if not tree then return 0 end

    local total = 0
    for _, skillDef in ipairs(tree) do
        if cache.skills[skillDef.key] and skillDef.effect and skillDef.effect[effectKey] then
            local val = skillDef.effect[effectKey]
            if type(val) == 'number' then
                total = total + val
            end
        end
    end

    return total
end

--- Checks if a player has a boolean skill effect active.
---@param citizenId string
---@param effectKey string
---@return boolean
function HasPlayerSkillEffect(citizenId, effectKey)
    local cache = ensureCache(citizenId)
    local spec = cache.spec
    if not spec then return false end

    local tree = Config.SkillTrees[spec]
    if not tree then return false end

    for _, skillDef in ipairs(tree) do
        if cache.skills[skillDef.key] and skillDef.effect and skillDef.effect[effectKey] == true then
            return true
        end
    end

    return false
end

--- Gets a player's prestige level.
---@param citizenId string
---@return number
function GetPlayerPrestige(citizenId)
    local cache = ensureCache(citizenId)
    return cache.prestige or 0
end

--- Gets the XP multiplier from prestige.
---@param citizenId string
---@return number multiplier (1.0 = no bonus)
function GetPrestigeXpMultiplier(citizenId)
    local prestige = GetPlayerPrestige(citizenId)
    return 1.0 + (prestige * (Config.Prestige.xpBonusPerPrestige or 0.10))
end

--- Gets the player's specialization.
---@param citizenId string
---@return string|nil
function GetPlayerSpecialization(citizenId)
    local cache = ensureCache(citizenId)
    return cache.spec
end

-----------------------------------------------------------
-- SPECIALIZATION CALLBACKS
-----------------------------------------------------------

--- Returns specialization and skill data for the client.
lib.callback.register('mining:server:getSpecData', function(src)
    local citizenId = getCitizenId(src)
    if not citizenId then return nil end

    local stats = DB.GetStats(citizenId)
    if not stats then return nil end

    local skills = DB.GetSkills(citizenId)
    local skillSet = {}
    for _, key in ipairs(skills) do
        skillSet[key] = true
    end

    local level = stats.level or 1
    local availablePoints = math.floor(level / (Config.SkillTrees.pointsPerLevels or 2))
    local spentPoints = stats.skill_points_spent or 0
    local remainingPoints = availablePoints - spentPoints

    return {
        specialization = stats.specialization,
        prestige = stats.prestige or 0,
        level = level,
        skills = skillSet,
        availablePoints = availablePoints,
        spentPoints = spentPoints,
        remainingPoints = remainingPoints,
    }
end)

--- Chooses a specialization.
lib.callback.register('mining:server:chooseSpec', function(src, specKey)
    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    local stats = DB.GetStats(citizenId)
    if not stats then return { success = false, reason = 'No stats found' } end

    if stats.specialization then
        return { success = false, reason = 'Already specialized as ' .. stats.specialization }
    end

    if (stats.level or 1) < Config.Specializations.levelRequired then
        return { success = false, reason = ('Requires level %d'):format(Config.Specializations.levelRequired) }
    end

    if not Config.Specializations.specs[specKey] then
        return { success = false, reason = 'Invalid specialization' }
    end

    DB.SetSpecialization(citizenId, specKey)
    invalidateCache(citizenId)

    local specDef = Config.Specializations.specs[specKey]
    return {
        success = true,
        specialization = specKey,
        label = specDef.label,
    }
end)

--- Unlocks a skill from the player's skill tree.
lib.callback.register('mining:server:unlockSkill', function(src, skillKey)
    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    local stats = DB.GetStats(citizenId)
    if not stats then return { success = false, reason = 'No stats found' } end

    local spec = stats.specialization
    if not spec then
        return { success = false, reason = 'Choose a specialization first' }
    end

    local tree = Config.SkillTrees[spec]
    if not tree then
        return { success = false, reason = 'Invalid skill tree' }
    end

    -- Find the skill definition
    local skillDef = nil
    for _, def in ipairs(tree) do
        if def.key == skillKey then
            skillDef = def
            break
        end
    end

    if not skillDef then
        return { success = false, reason = 'Skill not found in your tree' }
    end

    if DB.HasSkill(citizenId, skillKey) then
        return { success = false, reason = 'Already unlocked' }
    end

    -- Check prerequisite
    if skillDef.requires then
        if not DB.HasSkill(citizenId, skillDef.requires) then
            return { success = false, reason = 'Missing prerequisite skill' }
        end
    end

    -- Check available skill points
    local level = stats.level or 1
    local availablePoints = math.floor(level / (Config.SkillTrees.pointsPerLevels or 2))
    local spentPoints = stats.skill_points_spent or 0
    local remainingPoints = availablePoints - spentPoints

    if remainingPoints < skillDef.cost then
        return { success = false, reason = ('Need %d skill points (have %d)'):format(skillDef.cost, remainingPoints) }
    end

    DB.UnlockSkill(citizenId, skillKey)
    DB.SpendSkillPoints(citizenId, skillDef.cost)
    invalidateCache(citizenId)

    return {
        success = true,
        skillKey = skillKey,
        label = skillDef.label,
        cost = skillDef.cost,
    }
end)

-----------------------------------------------------------
-- PRESTIGE CALLBACK (NPC only, no command)
-----------------------------------------------------------

lib.callback.register('mining:server:prestige', function(src)
    local citizenId = getCitizenId(src)
    if not citizenId then return { success = false, reason = 'Player not loaded' } end

    local stats = DB.GetStats(citizenId)
    if not stats then return { success = false, reason = 'No stats found' } end

    local currentPrestige = stats.prestige or 0
    local maxPrestige = Config.Prestige.maxPrestige or 5

    if currentPrestige >= maxPrestige then
        return { success = false, reason = ('Already at max prestige (%d)'):format(maxPrestige) }
    end

    local requiredLevel = Config.Prestige.levelRequired or 20
    if (stats.level or 1) < requiredLevel then
        return { success = false, reason = ('Must be level %d to prestige'):format(requiredLevel) }
    end

    local newPrestige = currentPrestige + 1
    DB.DoPrestige(citizenId, newPrestige)
    invalidateCache(citizenId)

    local xpBonus = newPrestige * (Config.Prestige.xpBonusPerPrestige or 0.10) * 100

    return {
        success = true,
        prestige = newPrestige,
        xpBonus = xpBonus,
    }
end)

-----------------------------------------------------------
-- ACHIEVEMENTS QUERY CALLBACK
-----------------------------------------------------------

lib.callback.register('mining:server:getAchievements', function(src)
    local citizenId = getCitizenId(src)
    if not citizenId then return nil end

    local unlocked = DB.GetAchievements(citizenId)
    local unlockedSet = {}
    for _, key in ipairs(unlocked) do
        unlockedSet[key] = true
    end

    local counters = DB.GetCounters(citizenId)
    local stats = DB.GetStats(citizenId)
    local discoveryCount = DB.GetDiscoveryCount(citizenId)

    local achievements = {}
    for _, ach in ipairs(Config.Achievements.list) do
        local progress = 0
        local target = ach.target or 1

        if ach.check == 'total_mined' then
            progress = stats and stats.total_mined or 0
        elseif ach.check == 'total_earned' then
            progress = stats and stats.total_earned or 0
        elseif ach.check == 'discoveries' then
            progress = discoveryCount
        elseif ach.check == 'level' then
            progress = stats and stats.level or 1
        elseif ach.check == 'event' then
            progress = counters[ach.event] or 0
        end

        achievements[#achievements + 1] = {
            key = ach.key,
            label = ach.label,
            description = ach.description,
            xpReward = ach.xpReward,
            progress = math.min(progress, target),
            target = target,
            unlocked = unlockedSet[ach.key] == true,
        }
    end

    return achievements
end)

-----------------------------------------------------------
-- CLEANUP
-----------------------------------------------------------

AddEventHandler('playerDropped', function()
    local src = source
    local citizenId = getCitizenId(src)
    if citizenId then
        invalidateCache(citizenId)
    end
end)
