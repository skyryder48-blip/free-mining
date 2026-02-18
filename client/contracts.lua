-----------------------------------------------------------
-- CONTRACTS CLIENT
-- Handles contract board UI, progress notifications,
-- rare find discovery alerts, and related NPC interaction.
-----------------------------------------------------------

-----------------------------------------------------------
-- CONTRACT BOARD (ox_lib context menu)
-----------------------------------------------------------

--- Opens the contract board showing available and active contracts.
local function openContractBoard()
    local data = lib.callback.await('mining:server:getContractBoard', false)
    if not data then
        lib.notify({ description = 'Could not load contracts.', type = 'error' })
        return
    end

    local options = {}

    -- Section header: Active contracts
    if #data.active > 0 then
        options[#options + 1] = {
            title = 'Active Contracts',
            description = ('%d / %d'):format(#data.active, data.maxActive),
            icon = 'fas fa-clipboard-check',
            disabled = true,
        }

        for _, contract in ipairs(data.active) do
            local pct = math.floor((contract.progress / contract.target) * 100)
            local tierColor = contract.tier == 'easy' and '#4CAF50' or (contract.tier == 'medium' and '#FF9800' or '#F44336')
            local progressBar = ('%d / %d (%d%%)'):format(contract.progress, contract.target, pct)

            options[#options + 1] = {
                title = contract.label,
                description = ('Progress: %s'):format(progressBar),
                icon = 'fas fa-tasks',
                iconColor = tierColor,
                progress = pct,
                disabled = true,
            }
        end

        -- Separator
        options[#options + 1] = {
            title = '---',
            disabled = true,
        }
    end

    -- Section header: Available contracts
    options[#options + 1] = {
        title = 'Available Contracts',
        description = 'Select a contract to accept',
        icon = 'fas fa-scroll',
        disabled = true,
    }

    local canAccept = #data.active < data.maxActive

    for i, contract in ipairs(data.board) do
        local tierLabel = contract.tier:upper()
        local tierColor = contract.tier == 'easy' and '#4CAF50' or (contract.tier == 'medium' and '#FF9800' or '#F44336')

        local rewardStr = ('+%d XP, +$%s'):format(contract.xpReward, contract.cashReward)

        options[#options + 1] = {
            title = ('[%s] %s'):format(tierLabel, contract.label),
            description = ('Reward: %s'):format(rewardStr),
            icon = 'fas fa-file-contract',
            iconColor = tierColor,
            disabled = not canAccept,
            onSelect = function()
                if not canAccept then
                    lib.notify({ description = 'You already have the maximum active contracts.', type = 'error' })
                    return
                end

                local result = lib.callback.await('mining:server:acceptContract', false, {
                    type = contract.type,
                    tier = contract.tier,
                    label = contract.label,
                    target = contract.target,
                    extraData = contract.extraData,
                })

                if result and result.success then
                    lib.notify({
                        title = 'Contract Accepted',
                        description = ('[%s] %s'):format(result.tier:upper(), result.label),
                        type = 'success',
                        duration = 4000,
                    })
                elseif result then
                    lib.notify({ description = result.reason or 'Failed to accept contract', type = 'error' })
                end
            end,
        }
    end

    -- Completion bonus info
    if data.completionBonus then
        options[#options + 1] = {
            title = '---',
            disabled = true,
        }
        local bonusStr = ('+%d XP, +$%s'):format(data.completionBonus.xp, data.completionBonus.cash)
        local completed = data.todayCompleted or 0
        options[#options + 1] = {
            title = ('Daily Bonus (%d/%d completed today)'):format(completed, data.maxActive),
            description = ('Complete all %d contracts: %s'):format(data.maxActive, bonusStr),
            icon = 'fas fa-trophy',
            iconColor = '#FFD700',
            disabled = true,
        }
    end

    lib.registerContext({
        id = 'mining_contract_board',
        title = 'Mining Contract Board',
        options = options,
    })
    lib.showContext('mining_contract_board')
end

-----------------------------------------------------------
-- CONTRACT BOARD NPC INTERACTION
-----------------------------------------------------------

AddEventHandler('mining:client:openContractBoard', function()
    openContractBoard()
end)

-----------------------------------------------------------
-- CONTRACT PROGRESS NOTIFICATION
-----------------------------------------------------------

RegisterNetEvent('mining:client:contractProgress', function(data)
    if not data then return end

    local pct = math.floor((data.progress / data.target) * 100)
    lib.notify({
        title = 'Contract Progress',
        description = ('%s: %d/%d (%d%%)'):format(data.label, data.progress, data.target, pct),
        type = 'inform',
        duration = 3000,
    })
end)

-----------------------------------------------------------
-- CONTRACT COMPLETION NOTIFICATION
-----------------------------------------------------------

RegisterNetEvent('mining:client:contractCompleted', function(data)
    if not data then return end

    PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', false)

    lib.notify({
        title = 'CONTRACT COMPLETE!',
        description = ('%s\n+%d XP | +$%s'):format(data.label, data.xpReward, data.cashReward),
        type = 'success',
        duration = 6000,
    })

    -- Show XP gain and refresh HUD
    if ShowXpGain then ShowXpGain(data.xpReward) end
    if RefreshMiningHud then RefreshMiningHud() end
end)

-----------------------------------------------------------
-- DAILY BONUS COMPLETION NOTIFICATION
-----------------------------------------------------------

RegisterNetEvent('mining:client:contractBonusCompleted', function(data)
    if not data then return end

    PlaySoundFrontend(-1, 'RANK_UP', 'HUD_AWARDS', false)

    lib.notify({
        title = 'DAILY BONUS!',
        description = ('All contracts completed!\n+%d XP | +$%s'):format(data.xpBonus, data.cashBonus),
        type = 'success',
        duration = 8000,
    })

    if ShowXpGain then ShowXpGain(data.xpBonus) end
    if RefreshMiningHud then RefreshMiningHud() end
end)

-----------------------------------------------------------
-- RARE FIND DISCOVERY NOTIFICATION
-----------------------------------------------------------

RegisterNetEvent('mining:client:rareDiscovery', function(data)
    if not data then return end

    if data.isLocal then
        -- The discoverer gets a special notification
        PlaySoundFrontend(-1, 'RANK_UP', 'HUD_AWARDS', false)

        lib.notify({
            title = 'RARE FIND!',
            description = ('You discovered: %s%s!\n+%d XP'):format(data.itemLabel, data.zoneLabel, data.discoveryXp),
            type = 'success',
            duration = 8000,
        })

        if ShowXpGain then ShowXpGain(data.discoveryXp) end
        if RefreshMiningHud then RefreshMiningHud() end
    else
        -- Other players see the announcement
        lib.notify({
            title = 'Discovery!',
            description = ('%s found %s%s!'):format(data.playerName, data.itemLabel, data.zoneLabel),
            type = 'inform',
            duration = 6000,
        })
    end
end)

-----------------------------------------------------------
-- ACTIVE CONTRACTS COMMAND
-----------------------------------------------------------

RegisterCommand('contracts', function()
    local contracts = lib.callback.await('mining:server:getActiveContracts', false)
    if not contracts or #contracts == 0 then
        lib.notify({ description = 'No active contracts. Visit the Contract Board to accept some!', type = 'inform' })
        return
    end

    local options = {}
    for _, contract in ipairs(contracts) do
        local pct = math.floor((contract.progress / contract.target) * 100)
        local tierColor = contract.tier == 'easy' and '#4CAF50' or (contract.tier == 'medium' and '#FF9800' or '#F44336')

        options[#options + 1] = {
            title = contract.label,
            description = ('Progress: %d / %d (%d%%)'):format(contract.progress, contract.target, pct),
            icon = 'fas fa-tasks',
            iconColor = tierColor,
            progress = pct,
            disabled = true,
        }
    end

    lib.registerContext({
        id = 'mining_active_contracts',
        title = 'Active Contracts',
        options = options,
    })
    lib.showContext('mining_active_contracts')
end, false)

TriggerEvent('chat:addSuggestion', '/contracts', 'View your active mining contracts')
