-----------------------------------------------------------
-- ZONE MANAGEMENT
-- Registers ox_lib poly zones for each sub-zone.
-- Delegates vein targets/props to client/veins.lua.
-----------------------------------------------------------

local activeZone = nil      -- current sub-zone name the player is in
local activeBlips = {}      -- map blips

-----------------------------------------------------------
-- GETTERS (used by mining.lua and processing.lua)
-----------------------------------------------------------

--- Returns the name of the sub-zone the player is currently inside, or nil.
---@return string|nil
function GetActiveZone()
    return activeZone
end

-----------------------------------------------------------
-- SUB-ZONE REGISTRATION
-----------------------------------------------------------

local function initZones()
    for zoneName, zoneData in pairs(Config.Zones) do
        for _, subZone in ipairs(zoneData.subZones) do
            lib.zones.poly({
                points = subZone.points,
                thickness = (subZone.maxZ or 10.0) - (subZone.minZ or -5.0),
                debug = false,
                onEnter = function()
                    activeZone = subZone.name
                    -- Load dynamic veins for this sub-zone
                    LoadVeinsForSubZone(subZone.name)
                    lib.notify({
                        description = ('Entered %s - %s'):format(zoneData.label, subZone.label),
                        type = 'inform',
                        duration = 3000,
                    })
                end,
                onExit = function()
                    if activeZone == subZone.name then
                        activeZone = nil
                        -- Unload veins when leaving sub-zone
                        UnloadActiveVeins()
                    end
                end,
            })
        end
    end
end

-----------------------------------------------------------
-- NPC SPAWNING
-----------------------------------------------------------

local spawnedPeds = {}

--- Spawns a static NPC ped at the given location config.
---@param locConfig table
---@return number|nil pedHandle
local function spawnNpc(locConfig)
    if not locConfig.model then return nil end

    local model = joaat(locConfig.model)
    lib.requestModel(model)

    local ped = CreatePed(0, model, locConfig.coords.x, locConfig.coords.y, locConfig.coords.z - 1.0, locConfig.heading or 0.0, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    spawnedPeds[#spawnedPeds + 1] = ped
    return ped
end

-----------------------------------------------------------
-- BLIPS
-----------------------------------------------------------

local function createBlips()
    for key, loc in pairs(Config.Locations) do
        if loc.blip then
            local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
            SetBlipSprite(blip, loc.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, loc.blip.scale or 0.7)
            SetBlipColour(blip, loc.blip.color or 0)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(loc.label)
            EndTextCommandSetBlipName(blip)
            activeBlips[#activeBlips + 1] = blip
        end
    end
end

-----------------------------------------------------------
-- INTERACTION POINTS (Shop, Furnace, Cutting Bench, Buyer)
-----------------------------------------------------------

local function initInteractionPoints()
    -- Shop NPC
    local shopPed = spawnNpc(Config.Locations.shop)
    if shopPed then
        exports.ox_target:addLocalEntity(shopPed, {
            {
                name = 'mining_shop',
                label = Config.Locations.shop.label,
                icon = 'fas fa-store',
                distance = 2.5,
                onSelect = function()
                    TriggerEvent('mining:client:openShop')
                end,
            },
        })
    end

    -- Buyer NPC
    local buyerPed = spawnNpc(Config.Locations.buyer)
    if buyerPed then
        exports.ox_target:addLocalEntity(buyerPed, {
            {
                name = 'mining_buyer',
                label = Config.Locations.buyer.label,
                icon = 'fas fa-cash-register',
                distance = 2.5,
                onSelect = function()
                    TriggerEvent('mining:client:openBuyer')
                end,
            },
        })
    end

    -- Furnace
    exports.ox_target:addSphereZone({
        coords = Config.Locations.furnace.coords,
        radius = Config.Locations.furnace.radius or 1.5,
        debug = false,
        options = {
            {
                name = 'mining_furnace',
                label = Config.Locations.furnace.label,
                icon = 'fas fa-fire',
                distance = 2.0,
                onSelect = function()
                    TriggerEvent('mining:client:openFurnace')
                end,
            },
        },
    })

    -- Cutting Bench
    exports.ox_target:addSphereZone({
        coords = Config.Locations.cuttingBench.coords,
        radius = Config.Locations.cuttingBench.radius or 1.5,
        debug = false,
        options = {
            {
                name = 'mining_cutting_bench',
                label = Config.Locations.cuttingBench.label,
                icon = 'fas fa-gem',
                distance = 2.0,
                onSelect = function()
                    TriggerEvent('mining:client:openCuttingBench')
                end,
            },
        },
    })
end

-----------------------------------------------------------
-- CLEANUP
-----------------------------------------------------------

local function cleanup()
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    spawnedPeds = {}

    for _, blip in ipairs(activeBlips) do
        RemoveBlip(blip)
    end
    activeBlips = {}

    CleanupVeins()
    CleanupHazards()
    activeZone = nil
end

-----------------------------------------------------------
-- INIT
-----------------------------------------------------------

CreateThread(function()
    initZones()
    createBlips()
    initInteractionPoints()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        cleanup()
    end
end)
