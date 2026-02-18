-----------------------------------------------------------
-- EXPLOSIVES CLIENT
-- Handles blast mining flow, demolition charge placement,
-- quarry blasting pattern, scatter/rubble pickup targets,
-- retreat/detonate sequences, and gas explosion visuals.
-----------------------------------------------------------

-----------------------------------------------------------
-- STATE
-----------------------------------------------------------

local isBlasting = false
local activeScatterTargets = {}   -- activeScatterTargets[pickupId] = { targetId, entity }
local activeScatterProps = {}     -- activeScatterProps[pickupId] = entity handle
local blasterHeadStartActive = {} -- blasterHeadStartActive[subZoneName] = true while head start is active

-----------------------------------------------------------
-- HELPERS
-----------------------------------------------------------

--- Checks if player has a specific item.
---@param itemName string
---@param count number|nil
---@return boolean
local function hasItem(itemName, count)
    local c = exports.ox_inventory:Search('count', itemName)
    return c ~= nil and c >= (count or 1)
end

--- Calculates distance between player and a point.
---@param coords table {x,y,z}
---@return number
local function distToCoords(coords)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local dx = pos.x - coords.x
    local dy = pos.y - coords.y
    local dz = pos.z - (coords.z or pos.z)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-----------------------------------------------------------
-- BLAST MINING MODE SELECTION (Concept 1)
-----------------------------------------------------------

--- Shows the explosive mining context menu on a vein.
--- Called from the vein target interaction as an alternative to normal mining.
AddEventHandler('mining:client:startBlastMining', function(subZoneName, veinId)
    if isBlasting then return end
    if LocalPlayer.state.isMining then return end

    isBlasting = true
    LocalPlayer.state:set('isMining', true, false)

    local cfg = Config.Explosives.blastMining

    -- Pre-checks
    if not hasItem('dynamite', cfg.dynamitePerBlast) then
        lib.notify({ description = 'You need dynamite to blast mine.', type = 'error' })
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    if not hasItem('detonator') then
        lib.notify({ description = 'You need a detonator.', type = 'error' })
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    -- Get vein info
    local veinData = lib.callback.await('mining:server:getVeinInfo', false, veinId)
    if not veinData then
        lib.notify({ description = 'This vein is no longer available.', type = 'error' })
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    local oreLabel = Config.Ores[veinData.oreType] and Config.Ores[veinData.oreType].label or veinData.oreType

    -- Confirmation
    local confirm = lib.alertDialog({
        header = 'Blast Mining',
        content = ('Place dynamite on **%s** vein?\n\nThis will **destroy the entire vein** and scatter %d-%d ore pickups.\n\n- Uses 1x Dynamite\n- Uses 1x Detonator charge\n- No minigame quality bonus\n- Other players can collect scattered ore'):format(
            oreLabel, cfg.scatterCount.min, cfg.scatterCount.max
        ),
        centered = true,
        cancel = true,
    })

    if confirm ~= 'confirm' then
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    -- Place charge animation
    local animDict = 'amb@world_human_hammering@male@base'
    lib.requestAnimDict(animDict)

    local placed = lib.progressCircle({
        duration = cfg.placeTime,
        label = 'Placing dynamite...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = animDict, clip = 'base', flag = 1 },
    })

    if not placed then
        lib.notify({ description = 'Cancelled.', type = 'inform' })
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    -- Notify player to retreat
    lib.notify({
        title = 'CHARGE PLACED',
        description = ('Retreat to safe distance! (%dm)'):format(math.floor(cfg.safeDistance)),
        type = 'warning',
        duration = 8000,
    })

    -- Get vein coords for distance check
    local veinInfo = lib.callback.await('mining:server:getVeinInfo', false, veinId)
    if not veinInfo then
        lib.notify({ description = 'Vein no longer available.', type = 'error' })
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    -- Wait for player to retreat, provide a detonation prompt
    local veinCoords = nil
    -- We need the vein world coords - get from the vein target data
    -- The client veins.lua stores loaded vein positions; we retrieve from server
    local veins = lib.callback.await('mining:server:getVeins', false, subZoneName)
    if veins then
        for _, v in ipairs(veins) do
            if v.id == veinId then
                veinCoords = { x = v.x, y = v.y, z = v.z }
                break
            end
        end
    end

    if not veinCoords then
        -- Fallback: use player's current position (shouldn't happen)
        local pos = GetEntityCoords(PlayerPedId())
        veinCoords = { x = pos.x, y = pos.y, z = pos.z }
    end

    -- Retreat and detonate loop
    local detonated = false
    local retreatTimeout = GetGameTimer() + 30000 -- 30 second window

    CreateThread(function()
        while not detonated and GetGameTimer() < retreatTimeout and isBlasting do
            local dist = distToCoords(veinCoords)

            if dist >= cfg.safeDistance then
                -- Show detonate prompt
                lib.showTextUI('[E] Detonate', { icon = 'fas fa-bomb' })

                while dist >= cfg.safeDistance and not detonated and GetGameTimer() < retreatTimeout and isBlasting do
                    if IsControlJustPressed(0, 38) then -- E key
                        lib.hideTextUI()
                        detonated = true
                        break
                    end
                    Wait(0)
                    dist = distToCoords(veinCoords)
                end

                lib.hideTextUI()
            else
                -- Too close, show warning
                lib.showTextUI(('Too close! (%dm / %dm)'):format(math.floor(dist), math.floor(cfg.safeDistance)), { icon = 'fas fa-exclamation-triangle' })
                Wait(200)
                lib.hideTextUI()
            end

            Wait(100)
        end

        if not detonated then
            lib.hideTextUI()
            lib.notify({ description = 'Detonation timed out. Charge was lost.', type = 'error' })
            isBlasting = false
            LocalPlayer.state:set('isMining', false, false)
        end
    end)

    -- Wait for detonation
    while not detonated and GetGameTimer() < retreatTimeout and isBlasting do
        Wait(100)
    end

    if not detonated then return end

    -- Check if too close (apply blast damage)
    local currentDist = distToCoords(veinCoords)
    if currentDist < cfg.blastRadius then
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        local dmgScale = 1.0 - (currentDist / cfg.blastRadius)
        local damage = math.floor(cfg.blastDamage * dmgScale)
        SetEntityHealth(ped, math.max(1, health - damage))
    end

    -- Explosion visual at vein
    AddExplosion(veinCoords.x, veinCoords.y, veinCoords.z, 2, 0.5, true, false, 1.0)
    ShakeGameplayCam('MEDIUM_EXPLOSION_SHAKE', 0.8)

    -- Server call to process blast
    local result = lib.callback.await('mining:server:blastMine', false, {
        veinId = veinId,
        subZoneName = subZoneName,
    })

    if result and result.success then
        local msg = ('Vein blasted! %dx %s scattered in %d pickups'):format(result.totalOre, result.oreLabel, result.scatterCount)
        if result.gasExploded then
            msg = msg .. ' - GAS EXPLOSION!'
        end
        lib.notify({
            title = 'BLAST MINING',
            description = msg,
            type = 'success',
            duration = 6000,
        })
    elseif result then
        lib.notify({ description = result.reason or 'Blast failed', type = 'error' })
    end

    isBlasting = false
    LocalPlayer.state:set('isMining', false, false)
end)

-----------------------------------------------------------
-- DEMOLITION CHARGE FLOW (Concept 3)
-----------------------------------------------------------

--- Starts demolition charge placement on an obstacle (boulder/debris).
---@param subZoneName string
---@param targetType string 'boulder'|'debris'
---@param targetIndex number
---@param targetCoords table {x,y,z}
AddEventHandler('mining:client:startDemolition', function(subZoneName, targetType, targetIndex, targetCoords)
    if isBlasting then return end
    if LocalPlayer.state.isMining then return end

    isBlasting = true
    LocalPlayer.state:set('isMining', true, false)

    local cfg = Config.Explosives.demolition
    local chargesNeeded = cfg.chargesPerObstacle

    -- Pre-checks
    if not hasItem('blasting_charge', chargesNeeded) then
        lib.notify({ description = ('Need %d blasting charge(s).'):format(chargesNeeded), type = 'error' })
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    if not hasItem('detonator') then
        lib.notify({ description = 'You need a detonator.', type = 'error' })
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    -- Place charge animation
    local animDict = 'amb@world_human_hammering@male@base'
    lib.requestAnimDict(animDict)

    local placed = lib.progressCircle({
        duration = cfg.placeTime,
        label = 'Placing blasting charge...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = animDict, clip = 'base', flag = 1 },
    })

    if not placed then
        lib.notify({ description = 'Cancelled.', type = 'inform' })
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    lib.notify({
        title = 'CHARGE PLACED',
        description = ('Retreat to safe distance! (%dm)'):format(math.floor(cfg.safeDistance)),
        type = 'warning',
        duration = 6000,
    })

    -- Retreat and detonate loop
    local detonated = false
    local retreatTimeout = GetGameTimer() + 20000

    CreateThread(function()
        while not detonated and GetGameTimer() < retreatTimeout and isBlasting do
            local dist = distToCoords(targetCoords)

            if dist >= cfg.safeDistance then
                lib.showTextUI('[E] Detonate', { icon = 'fas fa-bomb' })

                while dist >= cfg.safeDistance and not detonated and GetGameTimer() < retreatTimeout and isBlasting do
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        detonated = true
                        break
                    end
                    Wait(0)
                    dist = distToCoords(targetCoords)
                end

                lib.hideTextUI()
            else
                lib.showTextUI(('Too close! (%dm / %dm)'):format(math.floor(dist), math.floor(cfg.safeDistance)), { icon = 'fas fa-exclamation-triangle' })
                Wait(200)
                lib.hideTextUI()
            end

            Wait(100)
        end

        if not detonated then
            lib.hideTextUI()
            lib.notify({ description = 'Detonation timed out. Charge was lost.', type = 'error' })
            isBlasting = false
            LocalPlayer.state:set('isMining', false, false)
        end
    end)

    while not detonated and GetGameTimer() < retreatTimeout and isBlasting do
        Wait(100)
    end

    if not detonated then return end

    -- Blast damage check
    local currentDist = distToCoords(targetCoords)
    if currentDist < cfg.blastRadius then
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        local dmgScale = 1.0 - (currentDist / cfg.blastRadius)
        local damage = math.floor(cfg.blastDamage * dmgScale)
        SetEntityHealth(ped, math.max(1, health - damage))
    end

    -- Explosion visual
    AddExplosion(targetCoords.x, targetCoords.y, targetCoords.z, 2, 0.5, true, false, 1.0)
    ShakeGameplayCam('MEDIUM_EXPLOSION_SHAKE', 0.6)

    -- Server call
    local result = lib.callback.await('mining:server:demolitionBlast', false, {
        subZoneName = subZoneName,
        targetType = targetType,
        targetIndex = targetIndex,
        coords = targetCoords,
    })

    if result and result.success then
        local msg = ('Obstacle destroyed! %d rubble pickups scattered'):format(result.rubbleCount)
        if result.gasExploded then
            msg = msg .. ' - GAS EXPLOSION!'
        end
        lib.notify({
            title = 'DEMOLITION',
            description = msg,
            type = 'success',
            duration = 5000,
        })
    elseif result then
        lib.notify({ description = result.reason or 'Demolition failed', type = 'error' })
    end

    isBlasting = false
    LocalPlayer.state:set('isMining', false, false)
end)

-----------------------------------------------------------
-- QUARRY BLASTING FLOW (Concept 4)
-----------------------------------------------------------

--- Starts the quarry blasting sequence at a blast site.
---@param subZoneName string
---@param siteIndex number
---@param siteConfig table { center, slots, safeZone }
AddEventHandler('mining:client:startQuarryBlast', function(subZoneName, siteIndex, siteConfig)
    if isBlasting then return end
    if LocalPlayer.state.isMining then return end

    isBlasting = true
    LocalPlayer.state:set('isMining', true, false)

    local cfg = Config.Explosives.quarryBlasting

    -- Pre-checks
    if not hasItem('blasting_charge', cfg.chargesPerBlast) then
        lib.notify({ description = ('Need %d blasting charges.'):format(cfg.chargesPerBlast), type = 'error' })
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    if not hasItem('detonator_wire', cfg.wiresPerBlast) then
        lib.notify({ description = 'Need detonator wire.', type = 'error' })
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    if not hasItem('detonator') then
        lib.notify({ description = 'You need a detonator.', type = 'error' })
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    -- Confirmation
    local confirm = lib.alertDialog({
        header = 'Quarry Blasting',
        content = ('Place 3 charges at blast site?\n\n- Uses %dx Blasting Charge\n- Uses %dx Detonator Wire\n- Uses 1x Detonator charge\n\nCharge placement affects rubble yield.'):format(
            cfg.chargesPerBlast, cfg.wiresPerBlast
        ),
        centered = true,
        cancel = true,
    })

    if confirm ~= 'confirm' then
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    -- Place 3 charges sequentially at slot positions
    local placementQualities = {}
    local animDict = 'amb@world_human_hammering@male@base'
    lib.requestAnimDict(animDict)

    for i = 1, #siteConfig.slots do
        local slotCoords = siteConfig.slots[i]

        -- Guide player to slot
        lib.notify({
            description = ('Go to charge slot %d of %d'):format(i, #siteConfig.slots),
            type = 'inform',
            duration = 5000,
        })

        -- Wait for player to reach slot (within 2m)
        local reachTimeout = GetGameTimer() + 30000
        local reached = false

        while GetGameTimer() < reachTimeout and isBlasting do
            local dist = distToCoords({ x = slotCoords.x, y = slotCoords.y, z = slotCoords.z })
            if dist <= 2.0 then
                reached = true
                break
            end

            -- Draw marker at slot position
            DrawMarker(1, slotCoords.x, slotCoords.y, slotCoords.z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 0.5, 255, 165, 0, 150, false, true, 2, false, nil, nil, false)
            Wait(0)
        end

        if not reached then
            lib.notify({ description = 'Took too long to reach charge slot. Aborting.', type = 'error' })
            isBlasting = false
            LocalPlayer.state:set('isMining', false, false)
            return
        end

        -- Place charge animation
        local placed = lib.progressCircle({
            duration = cfg.placeTime,
            label = ('Placing charge %d/%d...'):format(i, #siteConfig.slots),
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, combat = true, car = true },
            anim = { dict = animDict, clip = 'base', flag = 1 },
        })

        if not placed then
            lib.notify({ description = 'Cancelled.', type = 'inform' })
            isBlasting = false
            LocalPlayer.state:set('isMining', false, false)
            return
        end

        -- Evaluate placement quality based on distance to center
        local distToCenter = distToCoords({ x = siteConfig.center.x, y = siteConfig.center.y, z = siteConfig.center.z })
        local maxSlotDist = 6.0 -- max expected distance from center

        local quality = 'red'
        if distToCenter <= maxSlotDist * 0.33 then
            quality = 'green'
        elseif distToCenter <= maxSlotDist * 0.66 then
            quality = 'yellow'
        end

        placementQualities[i] = quality

        local qualityColors = { green = '~g~OPTIMAL~s~', yellow = '~y~GOOD~s~', red = '~r~POOR~s~' }
        lib.notify({
            description = ('Charge %d placed - %s placement'):format(i, qualityColors[quality] or quality),
            type = quality == 'green' and 'success' or (quality == 'yellow' and 'warning' or 'error'),
        })
    end

    -- Wiring phase
    lib.notify({
        description = 'Wiring charges together...',
        type = 'inform',
    })

    local wired = lib.progressCircle({
        duration = cfg.wiringTime,
        label = 'Wiring charges...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = animDict, clip = 'base', flag = 1 },
    })

    if not wired then
        lib.notify({ description = 'Cancelled.', type = 'inform' })
        isBlasting = false
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    -- Retreat to safe zone
    lib.notify({
        title = 'CHARGES WIRED',
        description = ('Retreat to safe zone! (%dm)'):format(math.floor(cfg.safeDistance)),
        type = 'warning',
        duration = 10000,
    })

    local safeCoords = { x = siteConfig.safeZone.x, y = siteConfig.safeZone.y, z = siteConfig.safeZone.z }
    local centerCoords = { x = siteConfig.center.x, y = siteConfig.center.y, z = siteConfig.center.z }

    local detonated = false
    local retreatTimeout = GetGameTimer() + 30000

    CreateThread(function()
        while not detonated and GetGameTimer() < retreatTimeout and isBlasting do
            local dist = distToCoords(centerCoords)

            if dist >= cfg.safeDistance then
                lib.showTextUI('[E] Detonate Quarry Blast', { icon = 'fas fa-bomb' })

                while dist >= cfg.safeDistance and not detonated and GetGameTimer() < retreatTimeout and isBlasting do
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        detonated = true
                        break
                    end
                    Wait(0)
                    dist = distToCoords(centerCoords)
                end

                lib.hideTextUI()
            else
                lib.showTextUI(('Too close! (%dm / %dm)'):format(math.floor(dist), math.floor(cfg.safeDistance)), { icon = 'fas fa-exclamation-triangle' })
                Wait(200)
                lib.hideTextUI()
            end

            Wait(100)
        end

        if not detonated then
            lib.hideTextUI()
            lib.notify({ description = 'Detonation timed out. Charges were lost.', type = 'error' })
            isBlasting = false
            LocalPlayer.state:set('isMining', false, false)
        end
    end)

    while not detonated and GetGameTimer() < retreatTimeout and isBlasting do
        Wait(100)
    end

    if not detonated then return end

    -- Blast damage check
    local currentDist = distToCoords(centerCoords)
    if currentDist < cfg.blastRadius then
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        local dmgScale = 1.0 - (currentDist / cfg.blastRadius)
        local damage = math.floor(cfg.blastDamage * dmgScale)
        SetEntityHealth(ped, math.max(1, health - damage))
    end

    -- Big explosion visual (quarry blast is larger)
    AddExplosion(centerCoords.x, centerCoords.y, centerCoords.z, 2, 1.0, true, false, 2.0)
    ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.2)

    -- Server call
    local result = lib.callback.await('mining:server:quarryBlast', false, {
        subZoneName = subZoneName,
        siteIndex = siteIndex,
        placementQualities = placementQualities,
    })

    if result and result.success then
        local qualityStr = ('%.0f%%'):format(result.avgPlacementQuality * 100)
        local msg = ('%d rubble piles scattered (Placement: %s)'):format(result.rubbleCount, qualityStr)
        if result.gasExploded then
            msg = msg .. ' - GAS EXPLOSION!'
        end
        lib.notify({
            title = 'QUARRY BLAST',
            description = msg,
            type = 'success',
            duration = 8000,
        })
    elseif result then
        lib.notify({ description = result.reason or 'Quarry blast failed', type = 'error' })
    end

    isBlasting = false
    LocalPlayer.state:set('isMining', false, false)
end)

-----------------------------------------------------------
-- SCATTER / RUBBLE PICKUP SYSTEM
-----------------------------------------------------------

--- Spawns scatter pickup props and ox_target interactions.
RegisterNetEvent('mining:client:scatterSpawned', function(subZoneName, pickupIds, pickupData, blasterSrc, persistence)
    local currentZone = GetActiveZone()
    if currentZone ~= subZoneName then return end

    local mySource = GetPlayerServerId(PlayerId())
    local isBlaster = (mySource == blasterSrc)

    for _, pickupId in ipairs(pickupIds) do
        local pickup = pickupData[pickupId]
        if pickup and pickup.coords then
            -- Spawn prop
            local modelName = pickup.model or 'prop_rock_4_c'
            local model = joaat(modelName)
            lib.requestModel(model)

            local obj = CreateObject(model, pickup.coords.x, pickup.coords.y, pickup.coords.z - 0.5, false, true, false)
            if obj and obj ~= 0 then
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                activeScatterProps[pickupId] = obj
            end

            SetModelAsNoLongerNeeded(model)

            -- Determine pickup label
            local label = 'Collect Rubble'
            if not pickup.isRubble and pickup.oreType then
                local oreLabel = Config.Ores[pickup.oreType] and Config.Ores[pickup.oreType].label or pickup.oreType
                label = ('Collect %s'):format(oreLabel)
            end

            -- Determine pickup time
            local pickupTime = Config.Explosives.blastMining.pickupTime
            if pickup.isRubble then
                -- Check if this is quarry rubble (faster) or demolition rubble
                if GetActiveZoneKey() == 'quarry' then
                    pickupTime = Config.Explosives.quarryBlasting.pickupTime
                else
                    pickupTime = Config.Explosives.demolition.pickupTime
                end
            end

            -- Create ox_target
            local targetId = exports.ox_target:addSphereZone({
                coords = vec3(pickup.coords.x, pickup.coords.y, pickup.coords.z),
                radius = pickup.pickupRadius or 1.0,
                debug = false,
                options = {
                    {
                        name = 'collect_scatter_' .. pickupId,
                        label = label,
                        icon = pickup.isRubble and 'fas fa-mountain' or 'fas fa-gem',
                        distance = 2.0,
                        onSelect = function()
                            TriggerEvent('mining:client:collectScatter', pickupId, pickupTime)
                        end,
                        canInteract = function()
                            return activeScatterTargets[pickupId] ~= nil
                                and not LocalPlayer.state.isMining
                                and not isBlasting
                        end,
                    },
                },
            })

            activeScatterTargets[pickupId] = {
                targetId = targetId,
                entity = obj,
            }
        end
    end
end)

--- Handles collecting a scatter/rubble pickup.
AddEventHandler('mining:client:collectScatter', function(pickupId, pickupTime)
    if LocalPlayer.state.isMining then return end
    if isBlasting then return end

    LocalPlayer.state:set('isMining', true, false)

    -- Quick pickup animation
    local animDict = 'random@domestic'
    lib.requestAnimDict(animDict)

    local completed = lib.progressCircle({
        duration = pickupTime,
        label = 'Collecting...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = animDict, clip = 'pickup_low', flag = 1 },
    })

    if not completed then
        lib.notify({ description = 'Cancelled.', type = 'inform' })
        LocalPlayer.state:set('isMining', false, false)
        return
    end

    -- Server validation
    local result = lib.callback.await('mining:server:collectPickup', false, { pickupId = pickupId })

    if result and result.success then
        -- Build notification message
        local msg = ''
        for _, item in ipairs(result.items) do
            if msg ~= '' then msg = msg .. ' + ' end
            msg = msg .. ('%dx %s'):format(item.amount, item.label)
        end
        if msg ~= '' then
            lib.notify({ description = 'Collected: ' .. msg, type = 'success' })
        end

        -- Remove local target and prop
        removeScatterPickup(pickupId)
    elseif result then
        lib.notify({ description = result.reason or 'Collection failed', type = 'error' })
    end

    LocalPlayer.state:set('isMining', false, false)
end)

--- Removes a single scatter pickup (target + prop).
---@param pickupId number
function removeScatterPickup(pickupId)
    local data = activeScatterTargets[pickupId]
    if data then
        if data.targetId then
            exports.ox_target:removeZone(data.targetId)
        end
        if data.entity and DoesEntityExist(data.entity) then
            DeleteEntity(data.entity)
        end
        activeScatterTargets[pickupId] = nil
    end
    if activeScatterProps[pickupId] and DoesEntityExist(activeScatterProps[pickupId]) then
        DeleteEntity(activeScatterProps[pickupId])
    end
    activeScatterProps[pickupId] = nil
end

--- Server tells us a pickup was collected by someone.
RegisterNetEvent('mining:client:pickupCollected', function(pickupId, subZoneName)
    removeScatterPickup(pickupId)
end)

--- Server tells us pickups have despawned.
RegisterNetEvent('mining:client:scatterDespawned', function(subZoneName, pickupIds)
    for _, pickupId in ipairs(pickupIds) do
        removeScatterPickup(pickupId)
    end
end)

--- Server tells us an obstacle was destroyed by demolition.
RegisterNetEvent('mining:client:obstacleDestroyed', function(subZoneName, targetType, targetIndex)
    -- The hazards.lua handles boulder/debris cleanup;
    -- this event tells us to remove the target interaction
    -- The actual entity removal is handled by the existing cave-in/rockslide systems
end)

--- Server tells us a quarry crater was created.
RegisterNetEvent('mining:client:quarryCraterCreated', function(subZoneName, siteIndex, pickupIds, blasterSrc, headStartMs)
    -- Head start mechanic: non-blasters wait before seeing targets
    local mySource = GetPlayerServerId(PlayerId())
    if mySource ~= blasterSrc then
        blasterHeadStartActive[subZoneName] = true
        SetTimeout(headStartMs, function()
            blasterHeadStartActive[subZoneName] = nil
        end)
    end
end)

-----------------------------------------------------------
-- GAS EXPLOSION VISUAL
-----------------------------------------------------------

RegisterNetEvent('mining:client:gasExplosion', function(subZoneName, blastCoords, cfg)
    local currentZone = GetActiveZone()
    if not currentZone then return end

    -- Devastating explosion visual
    AddExplosion(blastCoords.x, blastCoords.y, blastCoords.z, cfg.explosionType, 2.0, true, false, 3.0)

    -- Heavy screen shake
    ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', cfg.shakeAmplitude)

    -- Flash effect
    AnimpostfxPlay(cfg.flashEffect, 0, false)
    SetTimeout(1500, function()
        AnimpostfxStop(cfg.flashEffect)
    end)

    -- Apply devastating damage to all players in radius
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local dist = #(pos - vec3(blastCoords.x, blastCoords.y, blastCoords.z))

    if dist < cfg.radius then
        local dmgScale = 1.0 - (dist / cfg.radius)
        local damage = math.floor(cfg.damage * dmgScale)
        local health = GetEntityHealth(ped)
        SetEntityHealth(ped, math.max(1, health - damage))

        lib.notify({
            title = 'GAS EXPLOSION!',
            description = 'The blast ignited a gas pocket!',
            type = 'error',
            duration = 6000,
        })
    end

    -- Stop existing gas effects since the explosion clears the gas
    AnimpostfxStop('DrugsMichaelAliensFightIn')
end)

-----------------------------------------------------------
-- QUARRY BLAST SITE TARGETS
-----------------------------------------------------------

local blastSiteTargets = {}

--- Creates ox_target interactions at quarry blast sites.
local function initBlastSiteTargets()
    local quarryZone = Config.Zones.quarry
    if not quarryZone then return end

    for _, subZone in ipairs(quarryZone.subZones) do
        if subZone.blastSites then
            for siteIdx, site in ipairs(subZone.blastSites) do
                local subZoneName = subZone.name
                local siteIndex = siteIdx

                local targetId = exports.ox_target:addSphereZone({
                    coords = site.center,
                    radius = 2.0,
                    debug = false,
                    options = {
                        {
                            name = 'quarry_blast_' .. subZoneName .. '_' .. siteIndex,
                            label = 'Quarry Blast Site',
                            icon = 'fas fa-bomb',
                            distance = 3.0,
                            onSelect = function()
                                TriggerEvent('mining:client:startQuarryBlast', subZoneName, siteIndex, site)
                            end,
                            canInteract = function()
                                return GetActiveZoneKey() == 'quarry'
                                    and not isBlasting
                                    and not LocalPlayer.state.isMining
                            end,
                        },
                    },
                })

                blastSiteTargets[#blastSiteTargets + 1] = targetId
            end
        end
    end
end

-----------------------------------------------------------
-- VEIN BLAST OPTION
-- Adds "Blast Mine" option to vein ox_target interactions.
-- This is handled by modifying the vein target creation in
-- client/veins.lua. We expose a function here for it.
-----------------------------------------------------------

--- Returns whether blast mining is available (has items).
---@return boolean
function CanBlastMine()
    return hasItem('dynamite') and hasItem('detonator')
end

--- Returns whether demolition is available (has items).
---@return boolean
function CanDemolish()
    return hasItem('blasting_charge') and hasItem('detonator')
end

-----------------------------------------------------------
-- CLEANUP
-----------------------------------------------------------

function CleanupExplosives()
    -- Remove scatter pickups
    for pickupId in pairs(activeScatterTargets) do
        removeScatterPickup(pickupId)
    end
    activeScatterTargets = {}
    activeScatterProps = {}

    -- Remove blast site targets
    for _, targetId in ipairs(blastSiteTargets) do
        exports.ox_target:removeZone(targetId)
    end
    blastSiteTargets = {}

    isBlasting = false
    blasterHeadStartActive = {}

    lib.hideTextUI()
end

-----------------------------------------------------------
-- INIT
-----------------------------------------------------------

CreateThread(function()
    initBlastSiteTargets()
end)
