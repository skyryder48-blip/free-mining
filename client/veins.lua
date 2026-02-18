-----------------------------------------------------------
-- DYNAMIC VEINS CLIENT
-- Handles vein discovery, indicator prop spawning,
-- and ox_target interaction points for veins.
-----------------------------------------------------------

-----------------------------------------------------------
-- STATE
-----------------------------------------------------------

local activeVeins = {}      -- activeVeins[veinId] = { id, oreType, coords, remaining, totalQuantity, quality, targetId, props }
local activeSubZone = nil   -- sub-zone name currently loaded for veins
local propModelsLoaded = {} -- track loaded prop models

-----------------------------------------------------------
-- PROP MANAGEMENT
-----------------------------------------------------------

--- Spawns indicator props around a vein position.
---@param vein table
---@return table[] propHandles
local function spawnIndicatorProps(vein)
    local propConfig = Config.IndicatorProps[vein.oreType]
    if not propConfig then return {} end

    local model = joaat(propConfig.model)
    if not propModelsLoaded[model] then
        lib.requestModel(model)
        propModelsLoaded[model] = true
    end

    local props = {}
    local count = propConfig.count or 1
    local offsetRange = propConfig.offsetRange or 0.5

    for i = 1, count do
        local angle = (i / count) * math.pi * 2 + math.random() * 0.5
        local ox = math.cos(angle) * offsetRange * (0.5 + math.random() * 0.5)
        local oy = math.sin(angle) * offsetRange * (0.5 + math.random() * 0.5)

        local prop = CreateObject(model, vein.coords.x + ox, vein.coords.y + oy, vein.coords.z - 0.5, false, true, false)
        if prop and prop ~= 0 then
            PlaceObjectOnGroundProperly(prop)
            FreezeEntityPosition(prop, true)
            SetEntityCollision(prop, false, false)
            props[#props + 1] = prop
        end
    end

    return props
end

--- Removes all props for a vein.
---@param props table[]
local function removeProps(props)
    if not props then return end
    for _, prop in ipairs(props) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
end

-----------------------------------------------------------
-- VEIN TARGET MANAGEMENT
-----------------------------------------------------------

--- Creates an ox_target sphere for a vein.
---@param vein table
---@return number|nil targetId
local function createVeinTarget(vein)
    local oreDef = Config.Ores[vein.oreType]
    local oreLabel = oreDef and oreDef.label or vein.oreType

    local id = exports.ox_target:addSphereZone({
        coords = vein.coords,
        radius = Config.Veins.interactionRadius,
        debug = false,
        options = {
            {
                name = 'mine_vein_' .. vein.id,
                label = ('Mine %s (%d/%d)'):format(oreLabel, vein.remaining, vein.totalQuantity),
                icon = 'fas fa-hammer',
                distance = 2.0,
                onSelect = function()
                    TriggerEvent('mining:client:startMining', activeSubZone, vein.id)
                end,
                canInteract = function()
                    return not LocalPlayer.state.isMining
                end,
            },
            {
                name = 'blast_vein_' .. vein.id,
                label = ('Blast Mine %s (%d remaining)'):format(oreLabel, vein.remaining),
                icon = 'fas fa-bomb',
                distance = 2.0,
                onSelect = function()
                    TriggerEvent('mining:client:startBlastMining', activeSubZone, vein.id)
                end,
                canInteract = function()
                    return not LocalPlayer.state.isMining
                        and CanBlastMine ~= nil and CanBlastMine()
                end,
            },
        },
    })

    return id
end

-----------------------------------------------------------
-- VEIN LOADING / UNLOADING
-----------------------------------------------------------

--- Loads veins for a sub-zone from the server and creates targets + props.
---@param subZoneName string
function LoadVeinsForSubZone(subZoneName)
    if activeSubZone == subZoneName then return end -- already loaded

    -- Unload previous
    UnloadActiveVeins()

    activeSubZone = subZoneName

    local veins = lib.callback.await('mining:server:getVeins', false, subZoneName)
    if not veins then return end

    for _, veinData in ipairs(veins) do
        local vein = {
            id = veinData.id,
            oreType = veinData.oreType,
            coords = vec3(veinData.x, veinData.y, veinData.z),
            remaining = veinData.remaining,
            totalQuantity = veinData.totalQuantity,
            quality = veinData.quality,
            targetId = nil,
            props = {},
        }

        -- Spawn indicator props
        vein.props = spawnIndicatorProps(vein)

        -- Create interaction target
        vein.targetId = createVeinTarget(vein)

        activeVeins[vein.id] = vein
    end
end

--- Unloads all active veins (targets + props).
function UnloadActiveVeins()
    for veinId, vein in pairs(activeVeins) do
        if vein.targetId then
            exports.ox_target:removeZone(vein.targetId)
        end
        removeProps(vein.props)
    end
    activeVeins = {}
    activeSubZone = nil
end

--- Returns the active sub-zone for veins.
---@return string|nil
function GetActiveVeinSubZone()
    return activeSubZone
end

-----------------------------------------------------------
-- SERVER EVENT HANDLERS
-----------------------------------------------------------

--- A vein was fully depleted — remove its target and props.
RegisterNetEvent('mining:client:veinDepleted', function(veinId, subZoneName)
    if activeSubZone ~= subZoneName then return end

    local vein = activeVeins[veinId]
    if not vein then return end

    if vein.targetId then
        exports.ox_target:removeZone(vein.targetId)
    end
    removeProps(vein.props)
    activeVeins[veinId] = nil
end)

--- A vein's remaining count was updated — refresh the target label.
RegisterNetEvent('mining:client:veinUpdated', function(veinId, subZoneName, newRemaining)
    if activeSubZone ~= subZoneName then return end

    local vein = activeVeins[veinId]
    if not vein then return end

    vein.remaining = newRemaining

    -- Recreate the target with updated label
    if vein.targetId then
        exports.ox_target:removeZone(vein.targetId)
    end
    vein.targetId = createVeinTarget(vein)
end)

--- Veins were regenerated server-side — reload if we're in a sub-zone.
RegisterNetEvent('mining:client:veinsRefreshed', function()
    if activeSubZone then
        local current = activeSubZone
        UnloadActiveVeins()
        LoadVeinsForSubZone(current)
    end
end)

-----------------------------------------------------------
-- CLEANUP
-----------------------------------------------------------

--- Cleanup on resource stop.
function CleanupVeins()
    UnloadActiveVeins()
    for model in pairs(propModelsLoaded) do
        SetModelAsNoLongerNeeded(model)
    end
    propModelsLoaded = {}
end
