-----------------------------------------------------------
-- HAZARDS CLIENT
-- Handles cave-in visual/audio effects, gas leak effects,
-- rockslide effects, boulder/debris mining, helmet light,
-- and wooden support placement.
-----------------------------------------------------------

-----------------------------------------------------------
-- STATE
-----------------------------------------------------------

local activeCaveIn = nil       -- { subZoneName, boulders={entity,...}, boulderOres={}, phase='warning'|'collapse' }
local activeGasLeak = nil      -- { subZoneName, phase='warning'|'active' }
local activeRockslide = nil    -- { subZoneName, debris={entity,...}, debrisTargets={}, phase='warning'|'slide' }
local gasLoopRunning = false   -- guard against duplicate gas damage loops
local helmetLightActive = false
local helmetLightHandle = nil
local isDarkZone = false
local darkScreenFx = false
local supportNotifyActive = false

-- Forward declarations
local startBoulderTargets, removeBoulderTargets
local startDebrisTargets, removeDebrisTargets

-----------------------------------------------------------
-- HELPERS
-----------------------------------------------------------

--- Finds the sub-zone config the player is currently in.
---@return table|nil subZone, string|nil zoneName
local function getCurrentSubZoneConfig()
    local currentZone = GetActiveZone()
    if not currentZone then return nil, nil end

    for zoneName, zoneData in pairs(Config.Zones) do
        for _, sz in ipairs(zoneData.subZones) do
            if sz.name == currentZone then
                return sz, zoneName
            end
        end
    end
    return nil, nil
end

--- Checks if player has a mining helmet with battery > 0.
---@return boolean hasLight, number battery
local function checkHelmet()
    local count = exports.ox_inventory:Search('count', 'mining_helmet')
    if not count or count < 1 then return false, 0 end

    local slots = exports.ox_inventory:Search('slots', 'mining_helmet')
    if not slots then return false, 0 end

    for _, slot in ipairs(slots) do
        local battery = slot.metadata and slot.metadata.battery or 0
        if battery > 0 then
            return true, battery
        end
    end

    return true, 0 -- has helmet but dead battery
end

-----------------------------------------------------------
-- CAVE-IN: WARNING PHASE
-----------------------------------------------------------

RegisterNetEvent('mining:client:caveInWarning', function(subZoneName)
    local currentZone = GetActiveZone()
    if currentZone ~= subZoneName then return end

    activeCaveIn = {
        subZoneName = subZoneName,
        boulders = {},
        boulderOres = {},
        boulderTargets = {},
        phase = 'warning',
    }

    -- Warning notification
    lib.notify({
        title = 'CAVE-IN WARNING',
        description = 'The ground is shaking! A cave-in is imminent!',
        type = 'error',
        duration = Config.CaveIn.warningDuration,
    })

    -- Periodic screen shake during warning
    CreateThread(function()
        local endTime = GetGameTimer() + Config.CaveIn.warningDuration
        while activeCaveIn and activeCaveIn.phase == 'warning' and GetGameTimer() < endTime do
            ShakeGameplayCam('ROAD_VIBRATION_SHAKE', Config.CaveIn.warningShakeAmplitude)
            Wait(500)
        end
    end)
end)

-----------------------------------------------------------
-- CAVE-IN: COLLAPSE PHASE
-----------------------------------------------------------

RegisterNetEvent('mining:client:caveInCollapse', function(subZoneName, boulderPositions, boulderOres)
    local currentZone = GetActiveZone()
    if currentZone ~= subZoneName then return end

    if not activeCaveIn then
        activeCaveIn = {
            subZoneName = subZoneName,
            boulders = {},
            boulderOres = {},
            boulderTargets = {},
            phase = 'collapse',
        }
    end

    activeCaveIn.phase = 'collapse'
    activeCaveIn.boulderOres = boulderOres or {}

    -- Heavy screen shake
    ShakeGameplayCam('MEDIUM_EXPLOSION_SHAKE', Config.CaveIn.collapseShakeAmplitude)

    -- Screen flash effect
    AnimpostfxPlay('FocusOut', 0, false)
    SetTimeout(500, function()
        AnimpostfxStop('FocusOut')
    end)

    -- Spawn boulder props
    local model = joaat(Config.CaveIn.boulderModel)
    lib.requestModel(model)

    for i, pos in ipairs(boulderPositions) do
        local boulder = CreateObject(model, pos.x, pos.y, pos.z - 1.0, false, true, false)
        if boulder and boulder ~= 0 then
            PlaceObjectOnGroundProperly(boulder)
            FreezeEntityPosition(boulder, true)
            activeCaveIn.boulders[i] = boulder
        end
    end

    SetModelAsNoLongerNeeded(model)

    -- Create ox_target interactions on boulders
    startBoulderTargets(boulderPositions, boulderOres)

    -- Collapse damage thread (first few seconds)
    CreateThread(function()
        local damageEnd = GetGameTimer() + Config.CaveIn.collapseDamageDuration
        local ped = PlayerPedId()
        while activeCaveIn and activeCaveIn.phase == 'collapse' and GetGameTimer() < damageEnd do
            local health = GetEntityHealth(ped)
            if health > 0 then
                SetEntityHealth(ped, math.max(1, health - Config.CaveIn.collapseDamage))
            end
            Wait(1000)
        end
    end)

    -- Notification
    lib.notify({
        title = 'CAVE-IN!',
        description = 'Rocks are falling! Mine through the boulders to escape!',
        type = 'error',
        duration = 8000,
    })
end)

-----------------------------------------------------------
-- CAVE-IN: BOULDER TARGETS
-----------------------------------------------------------

startBoulderTargets = function(boulderPositions, boulderOres)
    if not activeCaveIn then return end

    for i, pos in ipairs(boulderPositions) do
        local boulderIndex = i
        local oreType = boulderOres[i]
        local oreLabel = oreType and Config.Ores[oreType] and Config.Ores[oreType].label or nil
        local label = 'Mine Boulder'
        if oreLabel then
            label = ('Mine Boulder (%s inside)'):format(oreLabel)
        end

        local targetId = exports.ox_target:addSphereZone({
            coords = vec3(pos.x, pos.y, pos.z),
            radius = 1.5,
            debug = false,
            options = {
                {
                    name = 'mine_boulder_' .. boulderIndex,
                    label = label,
                    icon = 'fas fa-mountain',
                    distance = 2.5,
                    onSelect = function()
                        TriggerEvent('mining:client:mineBoulder', boulderIndex, oreType)
                    end,
                    canInteract = function()
                        return activeCaveIn and activeCaveIn.phase == 'collapse'
                            and activeCaveIn.boulders[boulderIndex]
                            and not LocalPlayer.state.isMining
                    end,
                },
            },
        })

        activeCaveIn.boulderTargets[i] = targetId
    end
end

removeBoulderTargets = function()
    if not activeCaveIn then return end
    for _, targetId in pairs(activeCaveIn.boulderTargets) do
        if targetId then
            exports.ox_target:removeZone(targetId)
        end
    end
    activeCaveIn.boulderTargets = {}
end

-----------------------------------------------------------
-- CAVE-IN: MINE BOULDER EVENT
-----------------------------------------------------------

AddEventHandler('mining:client:mineBoulder', function(boulderIndex, oreType)
    if not activeCaveIn or activeCaveIn.phase ~= 'collapse' then return end
    if LocalPlayer.state.isMining then return end

    LocalPlayer.state:set('isMining', true, false)

    -- Progress bar for mining boulder
    local animDict = 'melee@hatchet@streamed_core'
    lib.requestAnimDict(animDict)

    local completed = lib.progressCircle({
        duration = Config.CaveIn.boulderMineTime,
        label = 'Mining boulder...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = animDict, clip = 'plyr_shoot_2h', flag = 1 },
    })

    if not completed then
        lib.notify({ description = 'Cancelled.', type = 'inform' })
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    -- Server validation and reward
    local result = lib.callback.await('mining:server:mineBoulder', false, {
        subZoneName = activeCaveIn.subZoneName,
        boulderIndex = boulderIndex,
        oreType = oreType,
    })

    if result and result.success then
        local msg = ('%dx Stone'):format(result.stoneAmount)
        if result.oreAmount and result.oreAmount > 0 then
            msg = msg .. (' + %dx %s'):format(result.oreAmount, result.oreLabel)
        end
        lib.notify({ description = 'Boulder cleared! ' .. msg, type = 'success' })

        -- Remove the boulder prop and target
        if activeCaveIn and activeCaveIn.boulders[boulderIndex] then
            local boulder = activeCaveIn.boulders[boulderIndex]
            if DoesEntityExist(boulder) then
                DeleteEntity(boulder)
            end
            activeCaveIn.boulders[boulderIndex] = nil
        end

        if activeCaveIn and activeCaveIn.boulderTargets[boulderIndex] then
            exports.ox_target:removeZone(activeCaveIn.boulderTargets[boulderIndex])
            activeCaveIn.boulderTargets[boulderIndex] = nil
        end
    elseif result then
        lib.notify({ description = result.reason or 'Failed', type = 'error' })
    end

    LocalPlayer.state:set('isMining', false, false)
end)

-----------------------------------------------------------
-- CAVE-IN: END
-----------------------------------------------------------

RegisterNetEvent('mining:client:caveInEnd', function(subZoneName)
    if not activeCaveIn or activeCaveIn.subZoneName ~= subZoneName then return end

    -- Clean up remaining boulders
    for _, boulder in pairs(activeCaveIn.boulders) do
        if boulder and DoesEntityExist(boulder) then
            DeleteEntity(boulder)
        end
    end

    removeBoulderTargets()
    StopGameplayCamShaking(true)
    activeCaveIn = nil

    lib.notify({
        description = 'The cave-in has settled. Area is clear.',
        type = 'inform',
        duration = 5000,
    })
end)

-----------------------------------------------------------
-- GAS LEAK: WARNING
-----------------------------------------------------------

RegisterNetEvent('mining:client:gasLeakWarning', function(subZoneName)
    local currentZone = GetActiveZone()
    if currentZone ~= subZoneName then return end

    activeGasLeak = {
        subZoneName = subZoneName,
        phase = 'warning',
    }

    lib.notify({
        title = 'GAS DETECTED',
        description = 'Toxic gas detected! Equip your respirator!',
        type = 'error',
        duration = Config.GasLeak.warningDuration,
    })
end)

-----------------------------------------------------------
-- GAS LEAK: ACTIVE
-----------------------------------------------------------

RegisterNetEvent('mining:client:gasLeakActive', function(subZoneName)
    local currentZone = GetActiveZone()
    if currentZone ~= subZoneName then return end

    if not activeGasLeak then
        activeGasLeak = { subZoneName = subZoneName }
    end
    activeGasLeak.phase = 'active'

    -- Start gas visual effect
    AnimpostfxPlay('DrugsMichaelAliensFightIn', 0, true)

    -- Gas damage loop (guard against duplicates from re-entry)
    if not gasLoopRunning then
        gasLoopRunning = true
        CreateThread(function()
            while activeGasLeak and activeGasLeak.phase == 'active' do
                local currentZoneCheck = GetActiveZone()
                if currentZoneCheck == subZoneName then
                    -- Check respirator server-side
                    local gasResult = lib.callback.await('mining:server:gasCheck', false, subZoneName)
                    if not gasResult or not gasResult.active then
                        break -- gas ended
                    end

                    if not gasResult.protected then
                        local ped = PlayerPedId()
                        local health = GetEntityHealth(ped)
                        if health > 0 then
                            SetEntityHealth(ped, math.max(1, health - Config.GasLeak.damagePerSecond))
                        end
                    end
                end
                Wait(1000)
            end
            gasLoopRunning = false
        end)
    end
end)

-----------------------------------------------------------
-- GAS LEAK: END
-----------------------------------------------------------

RegisterNetEvent('mining:client:gasLeakEnd', function(subZoneName)
    if not activeGasLeak or activeGasLeak.subZoneName ~= subZoneName then return end

    AnimpostfxStop('DrugsMichaelAliensFightIn')
    activeGasLeak = nil
    gasLoopRunning = false

    lib.notify({
        description = 'The gas has cleared.',
        type = 'inform',
        duration = 4000,
    })
end)

-----------------------------------------------------------
-- ROCKSLIDE: WARNING PHASE (Phase 4)
-----------------------------------------------------------

RegisterNetEvent('mining:client:rockslideWarning', function(subZoneName)
    local currentZone = GetActiveZone()
    if currentZone ~= subZoneName then return end

    activeRockslide = {
        subZoneName = subZoneName,
        debris = {},
        debrisTargets = {},
        phase = 'warning',
    }

    lib.notify({
        title = 'ROCKSLIDE WARNING',
        description = 'Loose rocks above! A rockslide is starting!',
        type = 'error',
        duration = Config.Rockslide.warningDuration,
    })

    -- Periodic screen shake during warning
    CreateThread(function()
        local endTime = GetGameTimer() + Config.Rockslide.warningDuration
        while activeRockslide and activeRockslide.phase == 'warning' and GetGameTimer() < endTime do
            ShakeGameplayCam('ROAD_VIBRATION_SHAKE', Config.Rockslide.warningShakeAmplitude)
            Wait(500)
        end
    end)
end)

-----------------------------------------------------------
-- ROCKSLIDE: COLLAPSE PHASE
-----------------------------------------------------------

RegisterNetEvent('mining:client:rockslideCollapse', function(subZoneName, debrisPositions)
    local currentZone = GetActiveZone()
    if currentZone ~= subZoneName then return end

    if not activeRockslide then
        activeRockslide = {
            subZoneName = subZoneName,
            debris = {},
            debrisTargets = {},
            phase = 'slide',
        }
    end

    activeRockslide.phase = 'slide'

    -- Screen shake
    ShakeGameplayCam('MEDIUM_EXPLOSION_SHAKE', Config.Rockslide.slideShakeAmplitude)

    -- Spawn debris props
    local model = joaat(Config.Rockslide.debrisModel)
    lib.requestModel(model)

    for i, pos in ipairs(debrisPositions) do
        local debris = CreateObject(model, pos.x, pos.y, pos.z - 1.0, false, true, false)
        if debris and debris ~= 0 then
            PlaceObjectOnGroundProperly(debris)
            FreezeEntityPosition(debris, true)
            activeRockslide.debris[i] = debris
        end
    end

    SetModelAsNoLongerNeeded(model)

    -- Create debris targets
    startDebrisTargets(debrisPositions)

    -- Slide damage thread (lighter than cave-in)
    CreateThread(function()
        local damageEnd = GetGameTimer() + Config.Rockslide.slideDamageDuration
        local ped = PlayerPedId()
        while activeRockslide and activeRockslide.phase == 'slide' and GetGameTimer() < damageEnd do
            local health = GetEntityHealth(ped)
            if health > 0 then
                SetEntityHealth(ped, math.max(1, health - Config.Rockslide.slideDamage))
            end
            Wait(1000)
        end
    end)

    lib.notify({
        title = 'ROCKSLIDE!',
        description = 'Rocks are falling! Clear the debris!',
        type = 'error',
        duration = 5000,
    })
end)

-----------------------------------------------------------
-- ROCKSLIDE: DEBRIS TARGETS
-----------------------------------------------------------

startDebrisTargets = function(debrisPositions)
    if not activeRockslide then return end

    for i, pos in ipairs(debrisPositions) do
        local debrisIndex = i

        local targetId = exports.ox_target:addSphereZone({
            coords = vec3(pos.x, pos.y, pos.z),
            radius = 1.5,
            debug = false,
            options = {
                {
                    name = 'mine_debris_' .. debrisIndex,
                    label = 'Clear Debris',
                    icon = 'fas fa-mountain',
                    distance = 2.5,
                    onSelect = function()
                        TriggerEvent('mining:client:mineDebris', debrisIndex)
                    end,
                    canInteract = function()
                        return activeRockslide and activeRockslide.phase == 'slide'
                            and activeRockslide.debris[debrisIndex]
                            and not LocalPlayer.state.isMining
                    end,
                },
            },
        })

        activeRockslide.debrisTargets[i] = targetId
    end
end

removeDebrisTargets = function()
    if not activeRockslide then return end
    for _, targetId in pairs(activeRockslide.debrisTargets) do
        if targetId then
            exports.ox_target:removeZone(targetId)
        end
    end
    activeRockslide.debrisTargets = {}
end

-----------------------------------------------------------
-- ROCKSLIDE: MINE DEBRIS EVENT
-----------------------------------------------------------

AddEventHandler('mining:client:mineDebris', function(debrisIndex)
    if not activeRockslide or activeRockslide.phase ~= 'slide' then return end
    if LocalPlayer.state.isMining then return end

    LocalPlayer.state:set('isMining', true, false)

    local animDict = 'melee@hatchet@streamed_core'
    lib.requestAnimDict(animDict)

    local completed = lib.progressCircle({
        duration = Config.Rockslide.debrisMineTime,
        label = 'Clearing debris...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = animDict, clip = 'plyr_shoot_2h', flag = 1 },
    })

    if not completed then
        lib.notify({ description = 'Cancelled.', type = 'inform' })
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    local result = lib.callback.await('mining:server:mineDebris', false, {
        subZoneName = activeRockslide.subZoneName,
        debrisIndex = debrisIndex,
    })

    if result and result.success then
        lib.notify({
            description = ('Debris cleared! %dx Stone'):format(result.stoneAmount),
            type = 'success',
        })

        -- Remove the debris prop and target
        if activeRockslide and activeRockslide.debris[debrisIndex] then
            local debris = activeRockslide.debris[debrisIndex]
            if DoesEntityExist(debris) then
                DeleteEntity(debris)
            end
            activeRockslide.debris[debrisIndex] = nil
        end

        if activeRockslide and activeRockslide.debrisTargets[debrisIndex] then
            exports.ox_target:removeZone(activeRockslide.debrisTargets[debrisIndex])
            activeRockslide.debrisTargets[debrisIndex] = nil
        end
    elseif result then
        lib.notify({ description = result.reason or 'Failed', type = 'error' })
    end

    LocalPlayer.state:set('isMining', false, false)
end)

-----------------------------------------------------------
-- ROCKSLIDE: END
-----------------------------------------------------------

RegisterNetEvent('mining:client:rockslideEnd', function(subZoneName)
    if not activeRockslide or activeRockslide.subZoneName ~= subZoneName then return end

    -- Clean up remaining debris
    for _, debris in pairs(activeRockslide.debris) do
        if debris and DoesEntityExist(debris) then
            DeleteEntity(debris)
        end
    end

    removeDebrisTargets()
    StopGameplayCamShaking(true)
    activeRockslide = nil

    lib.notify({
        description = 'The rockslide has settled. Area is clear.',
        type = 'inform',
        duration = 4000,
    })
end)

-----------------------------------------------------------
-- HELMET LIGHT SYSTEM
-----------------------------------------------------------

--- Toggles helmet light on/off based on dark zone status and battery.
local function updateHelmetLight()
    local currentZone = GetActiveZone()
    if not currentZone then
        -- Not in any zone, disable dark effect and light
        if darkScreenFx then
            AnimpostfxStop('BikerFilter')
            darkScreenFx = false
        end
        if helmetLightHandle then
            DeleteEntity(helmetLightHandle)
            helmetLightHandle = nil
            helmetLightActive = false
        end
        isDarkZone = false
        return
    end

    local subZone = getCurrentSubZoneConfig()
    if not subZone then return end

    local newIsDark = subZone.isDark or false

    if newIsDark and not isDarkZone then
        -- Entered dark zone
        isDarkZone = true
    elseif not newIsDark and isDarkZone then
        -- Left dark zone
        isDarkZone = false
        if darkScreenFx then
            AnimpostfxStop('BikerFilter')
            darkScreenFx = false
        end
        if helmetLightHandle then
            DeleteEntity(helmetLightHandle)
            helmetLightHandle = nil
            helmetLightActive = false
        end
        return
    end

    if not isDarkZone then return end

    -- Check helmet
    local hasLight, battery = checkHelmet()

    if hasLight and battery > 0 then
        -- Helmet active: create/maintain flashlight
        if not helmetLightActive then
            helmetLightActive = true
            if darkScreenFx then
                AnimpostfxStop('BikerFilter')
                darkScreenFx = false
            end
        end
    else
        -- No helmet or dead battery: apply dark screen
        if not darkScreenFx then
            AnimpostfxPlay('BikerFilter', 0, true)
            darkScreenFx = true
        end
        if helmetLightHandle then
            DeleteEntity(helmetLightHandle)
            helmetLightHandle = nil
        end
        helmetLightActive = false
    end
end

--- Helmet battery drain thread.
local function helmetDrainLoop()
    CreateThread(function()
        while true do
            Wait(30000) -- every 30 seconds

            if isDarkZone and helmetLightActive then
                local result = lib.callback.await('mining:server:drainHelmetBattery', false, Config.Equipment['mining_helmet'].drainRate)
                if result then
                    if result.battery <= 0 then
                        helmetLightActive = false
                        updateHelmetLight()
                    end
                end
            end
        end
    end)
end

--- Zone change monitoring for helmet light.
local function helmetMonitorLoop()
    CreateThread(function()
        while true do
            Wait(2000) -- check every 2 seconds
            updateHelmetLight()
        end
    end)
end

-----------------------------------------------------------
-- WOODEN SUPPORT PLACEMENT
-----------------------------------------------------------

RegisterNetEvent('mining:client:placeSupport', function()
    local currentZone = GetActiveZone()
    if not currentZone then
        lib.notify({ description = 'You must be in a mining zone to place a support.', type = 'error' })
        return
    end

    -- Wooden supports are not effective in quarry zones (Phase 4)
    if GetActiveZoneKey() == 'quarry' then
        lib.notify({ description = 'Wooden supports are not effective in open quarries.', type = 'inform' })
        return
    end

    if LocalPlayer.state.isMining then return end
    LocalPlayer.state:set('isMining', true, false)

    -- Placement animation
    local completed = lib.progressCircle({
        duration = 5000,
        label = 'Placing wooden support...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = 'amb@world_human_hammering@male@base', clip = 'base' },
    })

    if not completed then
        lib.notify({ description = 'Cancelled.', type = 'inform' })
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    local result = lib.callback.await('mining:server:placeSupport', false, currentZone)
    if result and result.success then
        local minutes = math.floor(result.duration / 60000)
        lib.notify({
            description = ('Wooden support placed! Cave-in risk reduced for %d minutes.'):format(minutes),
            type = 'success',
        })
    elseif result then
        lib.notify({ description = result.reason or 'Failed to place support', type = 'error' })
    end

    LocalPlayer.state:set('isMining', false, false)
end)

--- Notification when a support is placed by anyone.
RegisterNetEvent('mining:client:supportPlaced', function(subZoneName, duration)
    local currentZone = GetActiveZone()
    if currentZone ~= subZoneName then return end

    if not supportNotifyActive then
        supportNotifyActive = true
        local minutes = math.floor(duration / 60000)
        lib.notify({
            description = ('A wooden support was placed. Cave-in risk reduced for %d min.'):format(minutes),
            type = 'inform',
            duration = 5000,
        })
        SetTimeout(5000, function()
            supportNotifyActive = false
        end)
    end
end)

-----------------------------------------------------------
-- EQUIPMENT NOTIFICATIONS
-----------------------------------------------------------

RegisterNetEvent('mining:client:equipmentNotify', function(data)
    if data.success then
        lib.notify({ description = data.message, type = 'success' })
    else
        lib.notify({ description = data.reason or 'Equipment error', type = 'error' })
    end
end)

RegisterNetEvent('mining:client:equipmentBroken', function(itemLabel)
    lib.notify({
        title = 'Equipment Broken',
        description = ('%s has worn out and been destroyed.'):format(itemLabel),
        type = 'error',
        duration = 5000,
    })
end)

-----------------------------------------------------------
-- CLEANUP
-----------------------------------------------------------

function CleanupHazards()
    -- Cave-in cleanup
    if activeCaveIn then
        for _, boulder in pairs(activeCaveIn.boulders) do
            if boulder and DoesEntityExist(boulder) then
                DeleteEntity(boulder)
            end
        end
        removeBoulderTargets()
        StopGameplayCamShaking(true)
        activeCaveIn = nil
    end

    -- Gas cleanup
    if activeGasLeak then
        AnimpostfxStop('DrugsMichaelAliensFightIn')
        activeGasLeak = nil
        gasLoopRunning = false
    end

    -- Rockslide cleanup (Phase 4)
    if activeRockslide then
        for _, debris in pairs(activeRockslide.debris) do
            if debris and DoesEntityExist(debris) then
                DeleteEntity(debris)
            end
        end
        removeDebrisTargets()
        StopGameplayCamShaking(true)
        activeRockslide = nil
    end

    -- Helmet light cleanup
    if helmetLightHandle then
        DeleteEntity(helmetLightHandle)
        helmetLightHandle = nil
    end
    if darkScreenFx then
        AnimpostfxStop('BikerFilter')
        darkScreenFx = false
    end
    helmetLightActive = false
    isDarkZone = false
end

-----------------------------------------------------------
-- INIT
-----------------------------------------------------------

CreateThread(function()
    helmetDrainLoop()
    helmetMonitorLoop()
end)
