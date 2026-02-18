-----------------------------------------------------------
-- SPECIALIZATION & SKILLS CLIENT
-- Handles /specialize, /miningskills, /achievements commands
-- and prestige via NPC interaction.
-----------------------------------------------------------

-----------------------------------------------------------
-- /specialize — Choose a specialization
-----------------------------------------------------------

local function openSpecializationMenu()
    local data = lib.callback.await('mining:server:getSpecData', false)
    if not data then
        lib.notify({ description = 'Could not load data.', type = 'error' })
        return
    end

    -- Already specialized — show info instead
    if data.specialization then
        local specDef = Config.Specializations.specs[data.specialization]
        lib.notify({
            title = 'Specialization',
            description = ('You are specialized as %s'):format(specDef and specDef.label or data.specialization),
            type = 'inform',
            duration = 4000,
        })
        return
    end

    -- Check level requirement
    if data.level < Config.Specializations.levelRequired then
        lib.notify({
            description = ('Requires level %d (you are level %d)'):format(Config.Specializations.levelRequired, data.level),
            type = 'error',
        })
        return
    end

    -- Build menu options
    local options = {}
    for key, spec in pairs(Config.Specializations.specs) do
        options[#options + 1] = {
            title = spec.label,
            description = spec.description,
            icon = spec.icon,
            onSelect = function()
                -- Confirmation dialog
                local confirm = lib.alertDialog({
                    header = 'Choose Specialization',
                    content = ('Are you sure you want to specialize as **%s**?\n\n%s\n\nThis choice is permanent.'):format(spec.label, spec.description),
                    centered = true,
                    cancel = true,
                })

                if confirm == 'confirm' then
                    local result = lib.callback.await('mining:server:chooseSpec', false, key)
                    if result and result.success then
                        lib.notify({
                            title = 'SPECIALIZED!',
                            description = ('You are now a %s specialist!'):format(result.label),
                            type = 'success',
                            duration = 5000,
                        })
                    else
                        lib.notify({ description = result and result.reason or 'Failed', type = 'error' })
                    end
                end
            end,
        }
    end

    lib.registerContext({
        id = 'mining_spec_menu',
        title = 'Choose Specialization',
        options = options,
    })
    lib.showContext('mining_spec_menu')
end

RegisterCommand('specialize', function()
    openSpecializationMenu()
end, false)

TriggerEvent('chat:addSuggestion', '/specialize', 'Choose your mining specialization')

-----------------------------------------------------------
-- /miningskills — Skill tree menu
-----------------------------------------------------------

local function openSkillTreeMenu()
    local data = lib.callback.await('mining:server:getSpecData', false)
    if not data then
        lib.notify({ description = 'Could not load data.', type = 'error' })
        return
    end

    if not data.specialization then
        lib.notify({ description = 'Choose a specialization first (/specialize)', type = 'error' })
        return
    end

    local spec = data.specialization
    local specDef = Config.Specializations.specs[spec]
    local tree = Config.SkillTrees[spec]
    if not tree then
        lib.notify({ description = 'Skill tree not found.', type = 'error' })
        return
    end

    local options = {}

    -- Header: show remaining points
    options[#options + 1] = {
        title = ('%s Skill Tree'):format(specDef and specDef.label or spec),
        description = ('Skill Points: %d available | %d spent | Level %d'):format(
            data.remainingPoints, data.spentPoints, data.level
        ),
        icon = specDef and specDef.icon or 'fas fa-star',
        disabled = true,
    }

    -- Each skill in the tree
    for _, skillDef in ipairs(tree) do
        local unlocked = data.skills[skillDef.key] == true
        local canUnlock = not unlocked
            and data.remainingPoints >= skillDef.cost
            and (not skillDef.requires or data.skills[skillDef.requires] == true)

        local statusIcon = unlocked and 'fas fa-check-circle' or (canUnlock and 'fas fa-lock-open' or 'fas fa-lock')
        local statusColor = unlocked and '#50c878' or (canUnlock and '#e8c84a' or '#888888')

        local prereqText = ''
        if skillDef.requires and not data.skills[skillDef.requires] then
            -- Find the label of the prerequisite
            for _, sd in ipairs(tree) do
                if sd.key == skillDef.requires then
                    prereqText = (' | Requires: %s'):format(sd.label)
                    break
                end
            end
        end

        options[#options + 1] = {
            title = ('%s%s'):format(skillDef.label, unlocked and ' [UNLOCKED]' or ''),
            description = ('%s | Cost: %d pts%s'):format(skillDef.description, skillDef.cost, prereqText),
            icon = statusIcon,
            iconColor = statusColor,
            disabled = unlocked or not canUnlock,
            onSelect = function()
                if unlocked then return end

                local result = lib.callback.await('mining:server:unlockSkill', false, skillDef.key)
                if result and result.success then
                    lib.notify({
                        title = 'SKILL UNLOCKED!',
                        description = ('%s - %s'):format(result.label, skillDef.description),
                        type = 'success',
                        duration = 4000,
                    })
                    -- Re-open the menu to show updated state
                    openSkillTreeMenu()
                else
                    lib.notify({ description = result and result.reason or 'Failed', type = 'error' })
                end
            end,
        }
    end

    lib.registerContext({
        id = 'mining_skills_menu',
        title = 'Mining Skills',
        options = options,
    })
    lib.showContext('mining_skills_menu')
end

RegisterCommand('miningskills', function()
    openSkillTreeMenu()
end, false)

TriggerEvent('chat:addSuggestion', '/miningskills', 'View and unlock mining skills')

-----------------------------------------------------------
-- /achievements — Achievement list
-----------------------------------------------------------

local function openAchievementsMenu()
    local achievements = lib.callback.await('mining:server:getAchievements', false)
    if not achievements then
        lib.notify({ description = 'Could not load achievements.', type = 'error' })
        return
    end

    local unlockedCount = 0
    for _, ach in ipairs(achievements) do
        if ach.unlocked then unlockedCount = unlockedCount + 1 end
    end

    local options = {}

    -- Header
    options[#options + 1] = {
        title = ('Achievements (%d / %d)'):format(unlockedCount, #achievements),
        description = 'Complete milestones to earn XP rewards.',
        icon = 'fas fa-trophy',
        iconColor = '#e8c84a',
        disabled = true,
    }

    for _, ach in ipairs(achievements) do
        local progressText = ''
        if ach.target > 1 then
            progressText = (' (%d/%d)'):format(ach.progress, ach.target)
        end

        options[#options + 1] = {
            title = ('%s%s%s'):format(ach.label, ach.unlocked and ' [DONE]' or '', progressText),
            description = ('%s | +%d XP'):format(ach.description, ach.xpReward),
            icon = ach.unlocked and 'fas fa-trophy' or 'fas fa-circle',
            iconColor = ach.unlocked and '#e8c84a' or '#555555',
            disabled = true,
        }
    end

    lib.registerContext({
        id = 'mining_achievements_menu',
        title = 'Mining Achievements',
        options = options,
    })
    lib.showContext('mining_achievements_menu')
end

RegisterCommand('achievements', function()
    openAchievementsMenu()
end, false)

TriggerEvent('chat:addSuggestion', '/achievements', 'View mining achievements')

-----------------------------------------------------------
-- PRESTIGE VIA NPC (no command)
-----------------------------------------------------------

--- Opens the prestige confirmation dialog.
--- Called from shop NPC ox_target option in zones.lua.
function OpenPrestigeMenu()
    local data = lib.callback.await('mining:server:getSpecData', false)
    if not data then
        lib.notify({ description = 'Could not load data.', type = 'error' })
        return
    end

    local currentPrestige = data.prestige or 0
    local maxPrestige = Config.Prestige.maxPrestige or 5

    if currentPrestige >= maxPrestige then
        lib.notify({ description = 'Already at max prestige!', type = 'inform' })
        return
    end

    if data.level < (Config.Prestige.levelRequired or 20) then
        lib.notify({
            description = ('Requires level %d to prestige (you are level %d)'):format(Config.Prestige.levelRequired, data.level),
            type = 'error',
        })
        return
    end

    local nextPrestige = currentPrestige + 1
    local xpBonus = nextPrestige * (Config.Prestige.xpBonusPerPrestige or 0.10) * 100

    local confirm = lib.alertDialog({
        header = ('Prestige %d'):format(nextPrestige),
        content = ('**Are you sure you want to prestige?**\n\nThis will:\n- Reset your level to 1\n- Reset your XP to 0\n- Reset all unlocked skills\n\nYou will keep:\n- Your specialization\n- Your achievements\n- Your lifetime stats\n\n**Reward: +%.0f%% XP bonus permanently**'):format(xpBonus),
        centered = true,
        cancel = true,
    })

    if confirm == 'confirm' then
        local result = lib.callback.await('mining:server:prestige', false)
        if result and result.success then
            lib.notify({
                title = ('PRESTIGE %d!'):format(result.prestige),
                description = ('+%.0f%% XP bonus active!'):format(result.xpBonus),
                type = 'success',
                duration = 6000,
            })
            -- Refresh HUD
            if RefreshMiningHud then RefreshMiningHud() end
        else
            lib.notify({ description = result and result.reason or 'Failed', type = 'error' })
        end
    end
end

-----------------------------------------------------------
-- ACHIEVEMENT NOTIFICATION HANDLER
-----------------------------------------------------------

RegisterNetEvent('mining:client:achievementUnlocked', function(data)
    lib.notify({
        title = 'ACHIEVEMENT UNLOCKED!',
        description = ('%s - %s (+%d XP)'):format(data.label, data.description, data.xpReward or 0),
        type = 'success',
        duration = 6000,
    })

    -- Play sound
    PlaySoundFrontend(-1, 'RANK_UP', 'HUD_AWARDS', false)

    -- Refresh HUD to show updated XP
    if RefreshMiningHud then RefreshMiningHud() end
end)
