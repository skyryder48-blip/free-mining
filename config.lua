Config = {}

-----------------------------------------------------------
-- ORE DEFINITIONS
-----------------------------------------------------------
-- processing: 'smelt' = furnace pathway, 'cut' = gem cutting pathway, 'none' = sell raw only
-- tool: 'any' = pickaxe or rock_drill, 'rock_drill' = rock_drill required

Config.Ores = {
    -- Cave ores
    ['ore_copper'] = {
        label = 'Copper Ore',
        zone = 'cave',
        weight = 4000,
        mineTime = 5000,
        rarity = 35,
        tool = 'any',
        processing = 'smelt',
        output = 'ingot_copper',
        difficulty = 'easy',
    },
    ['ore_silver'] = {
        label = 'Silver Ore',
        zone = 'cave',
        weight = 5000,
        mineTime = 7000,
        rarity = 25,
        tool = 'any',
        processing = 'smelt',
        output = 'ingot_silver',
        difficulty = 'medium',
    },
    ['ore_gold'] = {
        label = 'Gold Ore',
        zone = 'cave',
        weight = 8000,
        mineTime = 10000,
        rarity = 10,
        tool = 'any',
        processing = 'smelt',
        output = 'ingot_gold',
        difficulty = 'hard',
    },
    ['raw_quartz'] = {
        label = 'Raw Quartz',
        zone = 'cave',
        weight = 3000,
        mineTime = 6000,
        rarity = 20,
        tool = 'any',
        processing = 'cut',
        output = 'cut_quartz',
        difficulty = 'medium',
    },
    ['raw_emerald'] = {
        label = 'Raw Emerald',
        zone = 'cave',
        weight = 4000,
        mineTime = 9000,
        rarity = 10,
        tool = 'any',
        processing = 'cut',
        output = 'cut_emerald',
        difficulty = 'hard',
    },

    -- Mine shaft ores
    ['ore_iron'] = {
        label = 'Iron Ore',
        zone = 'mine_shaft',
        weight = 6000,
        mineTime = 6000,
        rarity = 30,
        tool = 'any',
        processing = 'smelt',
        output = 'ingot_iron',
        difficulty = 'medium',
    },
    ['ore_platinum'] = {
        label = 'Platinum Ore',
        zone = 'mine_shaft',
        weight = 7000,
        mineTime = 12000,
        rarity = 10,
        tool = 'rock_drill',
        processing = 'smelt',
        output = 'ingot_platinum',
        difficulty = 'hard',
    },
    ['ore_titanium'] = {
        label = 'Titanium Ore',
        zone = 'mine_shaft',
        weight = 8000,
        mineTime = 14000,
        rarity = 8,
        tool = 'rock_drill',
        processing = 'smelt',
        output = 'ingot_titanium',
        difficulty = 'expert',
    },
    ['coal'] = {
        label = 'Coal',
        zone = 'mine_shaft',
        weight = 3000,
        mineTime = 4000,
        rarity = 40,
        tool = 'any',
        processing = 'none',
        output = nil,
        difficulty = 'easy',
    },
    ['raw_diamond'] = {
        label = 'Raw Diamond',
        zone = 'mine_shaft',
        weight = 2000,
        mineTime = 15000,
        rarity = 12,
        tool = 'rock_drill',
        processing = 'cut',
        output = 'cut_diamond',
        difficulty = 'expert',
    },

    -- Quarry ores (Phase 4)
    ['limestone'] = {
        label = 'Limestone',
        zone = 'quarry',
        weight = 5000,
        mineTime = 4000,
        rarity = 40,
        tool = 'any',
        processing = 'none',
        output = nil,
        difficulty = 'easy',
    },
    ['sandstone'] = {
        label = 'Sandstone',
        zone = 'quarry',
        weight = 4000,
        mineTime = 3500,
        rarity = 45,
        tool = 'any',
        processing = 'none',
        output = nil,
        difficulty = 'easy',
    },
}

-----------------------------------------------------------
-- TOOL DEFINITIONS
-----------------------------------------------------------

Config.Tools = {
    ['pickaxe'] = {
        label = 'Pickaxe',
        maxDurability = 300,
        speed = 1.0,
        price = 500,
        canMine = { 'ore_copper', 'ore_silver', 'ore_gold', 'raw_quartz', 'raw_emerald', 'ore_iron', 'coal', 'limestone', 'sandstone' },
        anim = { dict = 'melee@hatchet@streamed_core', clip = 'plyr_shoot_2h' },
    },
    ['rock_drill'] = {
        label = 'Rock Drill',
        maxDurability = 150,
        speed = 1.8,
        price = 2500,
        canMine = { 'ore_copper', 'ore_silver', 'ore_gold', 'raw_quartz', 'raw_emerald', 'ore_iron', 'ore_platinum', 'ore_titanium', 'coal', 'raw_diamond', 'limestone', 'sandstone' },
        anim = { dict = 'anim@heists@fleeca_bank@drilling', clip = 'drill_straight_idle' },
    },
}

-- Drill bit: restores 50 uses to rock_drill
Config.DrillBit = {
    item = 'drill_bit',
    restoreAmount = 50,
    price = 400,
}

-----------------------------------------------------------
-- MINING MODES
-----------------------------------------------------------

Config.MiningModes = {
    aggressive = {
        label = 'Aggressive',
        description = '2x speed, 70% quality, 1.5x tool wear',
        icon = 'fas fa-bolt',
        speedMod = 2.0,
        qualityMod = 0.7,
        wearMod = 1.5,
    },
    balanced = {
        label = 'Balanced',
        description = 'Standard speed and quality',
        icon = 'fas fa-balance-scale',
        speedMod = 1.0,
        qualityMod = 1.0,
        wearMod = 1.0,
    },
    precision = {
        label = 'Precision',
        description = '0.5x speed, 130% quality, 0.75x tool wear',
        icon = 'fas fa-crosshairs',
        speedMod = 0.5,
        qualityMod = 1.3,
        wearMod = 0.75,
    },
}

-----------------------------------------------------------
-- MINIGAME SETTINGS
-----------------------------------------------------------
-- greenZone: degrees of arc for perfect hit
-- yellowZone: degrees of arc for normal hit (each side of green)
-- speed: degrees per frame (~60fps)

Config.Minigame = {
    difficulty = {
        easy   = { greenZone = 60, yellowZone = 40, speed = 2.0 },
        medium = { greenZone = 45, yellowZone = 30, speed = 2.8 },
        hard   = { greenZone = 30, yellowZone = 25, speed = 3.6 },
        expert = { greenZone = 20, yellowZone = 20, speed = 4.5 },
    },
    yieldMultiplier = {
        green  = 1.5,
        yellow = 1.0,
        red    = 0.75,
    },
}

-----------------------------------------------------------
-- PROCESSING: SMELTING
-----------------------------------------------------------

Config.Smelting = {
    furnaceFee = 50,
    maxBatch = 5,
    coalPerBatch = 2,
    propaneUsesPerCanister = 5,
    baseTime = 12000, -- ms per batch, scales with batch size

    -- Minigame result affects output
    -- green: full output (1:1 ore to ingot)
    -- yellow: lose 1 ore from batch
    -- red: batch ruined (lose all ore)
}

-----------------------------------------------------------
-- PROCESSING: GEM CUTTING
-----------------------------------------------------------

Config.GemCutting = {
    cuttingFee = 75,
    baseTime = 8000,

    -- Two sequential minigame checks (rough cut + fine cut)
    -- Both green = 'flawless' (150% sell value)
    -- One green + one yellow = 'good' (100% sell value)
    -- Any red = 'chipped' (50% sell value)
    qualityMultiplier = {
        flawless = 1.5,
        good     = 1.0,
        chipped  = 0.5,
    },
}

-----------------------------------------------------------
-- SELL PRICES
-----------------------------------------------------------

Config.SellPrices = {
    -- Ingots (processed metals)
    ingot_copper   = 75,
    ingot_silver   = 150,
    ingot_gold     = 350,
    ingot_iron     = 100,
    ingot_platinum = 600,
    ingot_titanium = 500,

    -- Cut gems (base price, multiplied by quality tier)
    cut_quartz  = 60,
    cut_emerald = 275,
    cut_diamond = 800,

    -- Raw ores (30-40% of processed value, metals only)
    ore_copper  = 25,
    ore_silver  = 50,
    ore_gold    = 120,
    ore_iron    = 35,
    ore_platinum = 200,
    ore_titanium = 175,
    coal         = 18,

    -- Raw gems are NOT sellable (must be cut)
    -- raw_quartz, raw_emerald, raw_diamond = nil

    -- Quarry ores (Phase 4)
    limestone = 15,
    sandstone = 12,

    -- Materials
    stone = 8,

    -- Rare finds (Phase 7) - base prices, can be multiplied by sell bonus
    pure_gold_nugget   = 2500,
    ancient_fossil     = 3500,
    flawless_crystal   = 5000,
    meteorite_fragment = 8000,
}

-----------------------------------------------------------
-- SHOP INVENTORY
-----------------------------------------------------------

Config.Shop = {
    label = 'Mining Supply Shop',
    items = {
        { item = 'pickaxe',          price = 500 },
        { item = 'rock_drill',       price = 2500, levelRequired = 10 },
        { item = 'drill_bit',        price = 400 },
        { item = 'propane_canister', price = 25 },
        { item = 'mining_helmet',    price = 350 },
        { item = 'helmet_battery',   price = 50 },
        { item = 'respirator',       price = 200 },
        { item = 'wooden_support',   price = 75 },
        -- Explosives
        { item = 'dynamite',         price = 750,  levelRequired = 5 },
        { item = 'blasting_charge',  price = 1400, levelRequired = 8 },
        { item = 'detonator',        price = 2000, levelRequired = 5 },
        { item = 'detonator_wire',   price = 150 },
    },
}

-----------------------------------------------------------
-- MINING ZONES & SUB-ZONES
-----------------------------------------------------------
-- Each sub-zone is a small polygon around a walkable area inside the MLO.
-- Veins are dynamically generated within each sub-zone's spawnArea bounds.
-- TODO: Update all coordinates once MLOs are loaded and positioned.

Config.Zones = {
    quarry = {
        label = 'Surface Quarry',
        difficulty = 'easy',
        miningSpeedMod = 1.2,   -- 20% faster mining (open-pit, easy access)
        yieldMod = 0.8,         -- 20% less yield (lower quality surface deposits)
        requiresHelmet = false,  -- outdoor, well-lit
        entryMessage = 'Open-pit quarry. Easy access, common ores.',
        subZones = {
            {
                name = 'quarry_upper',
                label = 'Upper Terrace',
                points = {
                    vec3(200.0, 0.0, 0.0),
                    vec3(220.0, 0.0, 0.0),
                    vec3(220.0, 15.0, 0.0),
                    vec3(200.0, 15.0, 0.0),
                },
                minZ = -5.0,
                maxZ = 15.0,
                oreDistribution = {
                    limestone = 35,
                    sandstone = 30,
                    ore_copper = 20,
                    coal = 15,
                },
                spawnArea = {
                    min = vec3(201.0, 1.0, 0.0),
                    max = vec3(219.0, 14.0, 0.0),
                },
                veinDensity = 5,
                hazardWeight = 0.3,
                isDark = false,
                blastSites = {
                    {
                        center = vec3(208.0, 6.0, 0.0),
                        slots = {
                            vec3(206.0, 5.0, 0.0),
                            vec3(210.0, 5.0, 0.0),
                            vec3(208.0, 8.0, 0.0),
                        },
                        safeZone = vec3(200.0, 6.0, 0.0),
                    },
                },
            },
            {
                name = 'quarry_lower',
                label = 'Lower Pit',
                points = {
                    vec3(200.0, 20.0, 0.0),
                    vec3(225.0, 20.0, 0.0),
                    vec3(225.0, 35.0, 0.0),
                    vec3(200.0, 35.0, 0.0),
                },
                minZ = -10.0,
                maxZ = 10.0,
                oreDistribution = {
                    limestone = 25,
                    sandstone = 20,
                    ore_copper = 25,
                    ore_iron = 20,
                    coal = 10,
                },
                spawnArea = {
                    min = vec3(201.0, 21.0, 0.0),
                    max = vec3(224.0, 34.0, 0.0),
                },
                veinDensity = 5,
                hazardWeight = 0.5,
                isDark = false,
                blastSites = {
                    {
                        center = vec3(212.0, 27.0, 0.0),
                        slots = {
                            vec3(210.0, 26.0, 0.0),
                            vec3(214.0, 26.0, 0.0),
                            vec3(212.0, 29.0, 0.0),
                        },
                        safeZone = vec3(202.0, 27.0, 0.0),
                    },
                },
            },
        },
    },

    cave = {
        label = 'Cave System',
        difficulty = 'medium',
        miningSpeedMod = 1.0,   -- standard speed
        yieldMod = 1.0,         -- standard yield
        requiresHelmet = true,   -- dark interior sections
        entryMessage = 'Natural cave system. Moderate hazards. Helmet recommended.',
        subZones = {
            {
                name = 'cave_entrance',
                label = 'Entrance Chamber',
                points = {
                    vec3(0.0, 0.0, 0.0),
                    vec3(10.0, 0.0, 0.0),
                    vec3(10.0, 10.0, 0.0),
                    vec3(0.0, 10.0, 0.0),
                },
                minZ = -5.0,
                maxZ = 10.0,
                oreDistribution = {
                    ore_copper = 50,
                    raw_quartz = 30,
                    ore_silver = 20,
                },
                spawnArea = {
                    min = vec3(1.0, 1.0, 0.0),
                    max = vec3(9.0, 9.0, 0.0),
                },
                veinDensity = 3,
                hazardWeight = 0.5,  -- low hazard near entrance
                isDark = false,
            },
            {
                name = 'cave_main_gallery',
                label = 'Main Gallery',
                points = {
                    vec3(15.0, 0.0, 0.0),
                    vec3(30.0, 0.0, 0.0),
                    vec3(30.0, 15.0, 0.0),
                    vec3(15.0, 15.0, 0.0),
                },
                minZ = -5.0,
                maxZ = 10.0,
                oreDistribution = {
                    ore_copper = 25,
                    ore_silver = 30,
                    ore_gold = 15,
                    raw_quartz = 20,
                    raw_emerald = 10,
                },
                spawnArea = {
                    min = vec3(16.0, 1.0, 0.0),
                    max = vec3(29.0, 14.0, 0.0),
                },
                veinDensity = 4,
                hazardWeight = 1.0,  -- standard hazard
                isDark = true,
            },
            {
                name = 'cave_deep_passage',
                label = 'Deep Passage',
                points = {
                    vec3(35.0, 0.0, 0.0),
                    vec3(50.0, 0.0, 0.0),
                    vec3(50.0, 10.0, 0.0),
                    vec3(35.0, 10.0, 0.0),
                },
                minZ = -10.0,
                maxZ = 5.0,
                oreDistribution = {
                    ore_gold = 25,
                    ore_silver = 20,
                    raw_emerald = 30,
                    raw_quartz = 25,
                },
                spawnArea = {
                    min = vec3(36.0, 1.0, 0.0),
                    max = vec3(49.0, 9.0, 0.0),
                },
                veinDensity = 3,
                hazardWeight = 1.5,  -- high hazard deep inside
                isDark = true,
            },
        },
    },

    mine_shaft = {
        label = 'Mine Shaft',
        difficulty = 'hard',
        miningSpeedMod = 0.85,  -- 15% slower (cramped, difficult conditions)
        yieldMod = 1.3,         -- 30% more yield (rich deep deposits)
        requiresHelmet = true,   -- dark underground
        entryMessage = 'Industrial mine shaft. High hazards. Full equipment required.',
        subZones = {
            {
                name = 'shaft_level1',
                label = 'Level 1 - Main Tunnel',
                points = {
                    vec3(100.0, 0.0, 0.0),
                    vec3(120.0, 0.0, 0.0),
                    vec3(120.0, 8.0, 0.0),
                    vec3(100.0, 8.0, 0.0),
                },
                minZ = -5.0,
                maxZ = 10.0,
                oreDistribution = {
                    ore_iron = 35,
                    coal = 45,
                    ore_platinum = 10,
                    ore_titanium = 10,
                },
                spawnArea = {
                    min = vec3(101.0, 1.0, 0.0),
                    max = vec3(119.0, 7.0, 0.0),
                },
                veinDensity = 4,
                hazardWeight = 0.8,
                isDark = true,
            },
            {
                name = 'shaft_level2',
                label = 'Level 2 - Deep Gallery',
                points = {
                    vec3(100.0, 15.0, 0.0),
                    vec3(125.0, 15.0, 0.0),
                    vec3(125.0, 25.0, 0.0),
                    vec3(100.0, 25.0, 0.0),
                },
                minZ = -15.0,
                maxZ = 0.0,
                oreDistribution = {
                    ore_platinum = 20,
                    ore_titanium = 15,
                    coal = 30,
                    ore_iron = 20,
                    raw_diamond = 15,
                },
                spawnArea = {
                    min = vec3(101.0, 16.0, 0.0),
                    max = vec3(124.0, 24.0, 0.0),
                },
                veinDensity = 4,
                hazardWeight = 1.5,
                isDark = true,
            },
        },
    },
}

-----------------------------------------------------------
-- NPC & INTERACTION LOCATIONS
-----------------------------------------------------------
-- TODO: Update coordinates to match your map layout.

Config.Locations = {
    shop = {
        coords = vec3(0.0, 0.0, 0.0),
        heading = 0.0,
        model = 's_m_y_construct_01',
        label = 'Mining Supply Shop',
        blip = { sprite = 618, color = 47, scale = 0.7 },
    },
    furnace = {
        coords = vec3(0.0, 0.0, 0.0),
        label = 'Smelting Furnace',
        radius = 1.5,
    },
    cuttingBench = {
        coords = vec3(0.0, 0.0, 0.0),
        label = 'Gem Cutting Bench',
        radius = 1.5,
    },
    buyer = {
        coords = vec3(0.0, 0.0, 0.0),
        heading = 0.0,
        model = 's_m_m_autoshop_02',
        label = 'Mining Buyer',
        blip = { sprite = 617, color = 2, scale = 0.7 },
    },
    contractBoard = {
        coords = vec3(0.0, 0.0, 0.0),
        heading = 0.0,
        model = 's_m_y_construct_02',
        label = 'Contract Board',
        blip = { sprite = 267, color = 5, scale = 0.7 },
    },
}

-----------------------------------------------------------
-- ORE YIELD
-----------------------------------------------------------
-- Base amount of ore per extraction (before mode/minigame modifiers)

Config.BaseYield = {
    min = 1,
    max = 3,
}

-----------------------------------------------------------
-- COOLDOWNS (ms)
-----------------------------------------------------------

Config.Cooldowns = {
    mining        = 500,
    smelting      = 1000,
    cutting       = 1000,
    selling       = 500,
    purchase      = 500,
    drillBit      = 1000,
    helmetBattery = 1000,
    blasting      = 2000,
    demolition    = 2000,
    quarryBlast   = 3000,
    pickupScatter = 300,
}

-----------------------------------------------------------
-- ANIMATIONS
-----------------------------------------------------------

Config.Animations = {
    smelting = { dict = 'anim@amb@business@weed@weed_inspecting_high_dry@', clip = 'weed_inspecting_high_base_inspector' },
    cutting  = { dict = 'mini@repair', clip = 'fixing_a_player' },
}

-----------------------------------------------------------
-- DYNAMIC VEINS (Phase 2)
-----------------------------------------------------------

Config.Veins = {
    -- Per-vein quantity range (number of extractions before depleted)
    quantityMin = 5,
    quantityMax = 15,

    -- Quality range (0-100, affects yield multiplier)
    qualityMin = 20,
    qualityMax = 95,

    -- Quality yield multiplier: final yield *= lerp(qualityYieldMin, qualityYieldMax, quality/100)
    qualityYieldMin = 0.5,  -- quality 0
    qualityYieldMax = 1.5,  -- quality 100

    -- Minimum distance between veins within the same sub-zone (units)
    minSpacing = 3.0,

    -- Interaction radius for ox_target sphere on each vein
    interactionRadius = 1.2,

    -- Discovery: veins are only visible to client within this distance (units)
    discoveryRange = 50.0,
}

-----------------------------------------------------------
-- VEIN REGENERATION
-----------------------------------------------------------

Config.VeinRegeneration = {
    -- How often the server checks for depleted veins to regenerate (ms)
    checkInterval = 60000, -- 1 minute

    -- Time range (ms) after depletion before a vein regenerates as a new one
    regenMinTime = 30 * 60 * 1000,   -- 30 minutes (shorter for testing; set to 24h for production)
    regenMaxTime = 90 * 60 * 1000,   -- 90 minutes (shorter for testing; set to 72h for production)
}

-----------------------------------------------------------
-- INDICATOR PROPS (placed near veins for visual cue)
-----------------------------------------------------------
-- Each ore type can have 1-3 small props spawned near the vein.
-- model: prop model name, offset: spawn offset range from vein center

Config.IndicatorProps = {
    ore_copper   = { model = 'prop_rock_4_c',     count = 2, offsetRange = 0.8 },
    ore_silver   = { model = 'prop_rock_4_b',     count = 2, offsetRange = 0.8 },
    ore_gold     = { model = 'prop_rock_4_c',     count = 2, offsetRange = 0.8 },
    ore_iron     = { model = 'prop_rock_4_b',     count = 2, offsetRange = 0.8 },
    ore_platinum = { model = 'prop_rock_4_c',     count = 3, offsetRange = 1.0 },
    ore_titanium = { model = 'prop_rock_4_c',     count = 3, offsetRange = 1.0 },
    coal         = { model = 'prop_rock_4_b',     count = 1, offsetRange = 0.5 },
    raw_quartz   = { model = 'prop_rock_4_cl2',   count = 2, offsetRange = 0.8 },
    raw_emerald  = { model = 'prop_rock_4_cl2',   count = 2, offsetRange = 0.8 },
    raw_diamond  = { model = 'prop_rock_4_cl2',   count = 3, offsetRange = 1.0 },
    limestone    = { model = 'prop_rock_4_b',     count = 2, offsetRange = 0.8 },
    sandstone    = { model = 'prop_rock_4_b',     count = 1, offsetRange = 0.6 },
}

-----------------------------------------------------------
-- HAZARDS (Phase 3)
-----------------------------------------------------------

Config.Hazards = {
    -- Base chance (0-100) to trigger a hazard per successful extraction
    -- Actual chance = baseChance * subZone.hazardWeight
    baseChance = 8,

    -- Which hazard types can occur (weights for random selection when a hazard triggers)
    -- Used in underground zones (cave, mine_shaft)
    types = {
        cave_in  = 60,  -- 60% of hazard rolls become cave-ins
        gas_leak = 40,  -- 40% of hazard rolls become gas leaks
    },

    -- Quarry-specific hazard types (surface zones)
    quarryTypes = {
        rockslide = 100, -- 100% of quarry hazard rolls become rockslides
    },
}

-----------------------------------------------------------
-- CAVE-IN
-----------------------------------------------------------

Config.CaveIn = {
    -- Warning phase: rumble and dust before the collapse
    warningDuration = 8000,    -- 8 seconds of warning

    -- Main collapse phase
    collapseDuration = 90000,  -- 90 seconds total event

    -- Screen shake during warning
    warningShakeAmplitude = 0.2,
    -- Screen shake during collapse
    collapseShakeAmplitude = 0.8,
    collapseShakeDuration = 3000,

    -- Boulders spawned to block the area
    boulderCount = 3,
    boulderModel = 'prop_rock_4_big',
    boulderSpreadRadius = 3.0,  -- how far from center boulders spawn

    -- Mining boulders
    boulderMineTime = 10000,   -- ms to mine a boulder
    boulderStoneYield = { min = 2, max = 5 },
    boulderOreChance = 25,     -- 25% chance a boulder also yields ore

    -- Damage to players caught in collapse (per second, during first 5s)
    collapseDamage = 5,
    collapseDamageDuration = 5000,

    -- Wooden support effect
    supportReduction = 0.5,    -- chance (0-1) that a support prevents a cave-in (50% block rate)
    supportDuration = 300000,  -- 5 minutes of protection per support
}

-----------------------------------------------------------
-- ROCKSLIDE (Phase 4 - quarry hazard)
-----------------------------------------------------------

Config.Rockslide = {
    -- Warning phase: dust and rumble before the slide
    warningDuration = 5000,    -- 5 seconds warning

    -- Main slide event duration
    slideDuration = 30000,     -- 30 seconds (shorter than cave-in)

    -- Screen shake during warning
    warningShakeAmplitude = 0.15,
    -- Screen shake during slide
    slideShakeAmplitude = 0.5,
    slideShakeDuration = 2000,

    -- Debris spawned
    debrisCount = 2,
    debrisModel = 'prop_rock_4_big',
    debrisSpreadRadius = 4.0,

    -- Damage (lighter than cave-in)
    slideDamage = 3,
    slideDamageDuration = 3000,

    -- Debris yields stone when mined
    debrisMineTime = 6000,
    debrisStoneYield = { min = 3, max = 8 },
}

-----------------------------------------------------------
-- GAS LEAK
-----------------------------------------------------------

Config.GasLeak = {
    -- Warning before gas reaches dangerous levels
    warningDuration = 5000,    -- 5 seconds warning

    -- Active gas duration
    activeDuration = 45000,    -- 45 seconds of active gas

    -- Damage per second to players without respirator
    damagePerSecond = 3,

    -- Visual effect intensity (0.0-1.0)
    fogIntensity = 0.7,

    -- Respirator uses consumed per second during active gas
    respiratorDrainPerTick = 1,
}

-----------------------------------------------------------
-- LEVELING (Phase 4)
-----------------------------------------------------------
-- XP required per level: level N requires baseXP * N^exponent total XP
Config.Leveling = {
    maxLevel = 20,
    xpPerLevel = 100,  -- XP needed per level (level 2 = 100, level 3 = 200, etc.)
}

-----------------------------------------------------------
-- HUD & PROGRESSION UI (Phase 6)
-----------------------------------------------------------
Config.HUD = {
    -- Show the mining HUD while inside a mining zone
    enabled = true,

    -- Position: 'top-left', 'top-right', 'bottom-left', 'bottom-right'
    position = 'bottom-right',

    -- Refresh interval (ms) for stats sync from server
    refreshInterval = 15000,

    -- Show HUD on zone enter, hide on zone exit
    autoToggle = true,

    -- Compact mode: only shows level and XP bar (no stats)
    compactMode = false,

    -- XP notification on gain (shows +XP floating text)
    showXpGain = true,

    -- Level-up celebration effect
    levelUpEffect = true,
    levelUpSound = true,
}

-----------------------------------------------------------
-- CONTRACTS (Phase 7)
-----------------------------------------------------------
-- Daily mining contracts available from the Contract Board NPC.
-- Players can accept up to maxActive contracts at once.
-- Contracts refresh daily (server midnight reset).

Config.Contracts = {
    maxActive = 3,                -- max simultaneous active contracts
    refreshHour = 0,              -- hour (0-23) at which available contracts refresh
    availableCount = 6,           -- how many contracts appear on the board each day

    -- Contract difficulty tiers and their reward scaling
    tiers = {
        easy   = { xpReward = 50,  cashReward = 500,  color = '~g~' },
        medium = { xpReward = 100, cashReward = 1200, color = '~y~' },
        hard   = { xpReward = 200, cashReward = 2500, color = '~r~' },
    },

    -- Bonus for completing all 3 active contracts in one day
    completionBonus = {
        xp = 150,
        cash = 1000,
    },

    -- Contract templates: each defines what the player must do.
    -- 'type' determines tracking method; 'target' is the goal amount.
    -- Templates are randomly selected and scaled per tier.
    templates = {
        -- Mining contracts
        { type = 'mine_ore',     label = 'Mine %d ore',                   target = { easy = 15, medium = 30, hard = 60 } },
        { type = 'mine_specific', label = 'Mine %d %s',                   target = { easy = 8,  medium = 18, hard = 35 }, ores = { 'ore_copper', 'ore_silver', 'ore_gold', 'ore_iron' } },
        { type = 'mine_zone',    label = 'Mine %d ore in %s',             target = { easy = 10, medium = 25, hard = 45 }, zones = { 'cave', 'mine_shaft', 'quarry' } },
        { type = 'mine_gems',    label = 'Mine %d raw gems',              target = { easy = 3,  medium = 8,  hard = 15 } },

        -- Processing contracts
        { type = 'smelt_ore',    label = 'Smelt %d ingots',               target = { easy = 8,  medium = 20, hard = 40 } },
        { type = 'cut_gems',     label = 'Cut %d gems',                   target = { easy = 2,  medium = 5,  hard = 10 } },

        -- Minigame skill contracts
        { type = 'perfect_hits', label = 'Get %d perfect (green) hits',   target = { easy = 5,  medium = 12, hard = 25 } },

        -- Economy contracts
        { type = 'earn_cash',    label = 'Earn $%d from mining sales',    target = { easy = 1000, medium = 3000, hard = 8000 } },

        -- Explosives contracts
        { type = 'blast_veins',  label = 'Blast mine %d veins',           target = { easy = 2,  medium = 5,  hard = 10 } },
    },
}

-----------------------------------------------------------
-- RARE FINDS (Phase 7)
-----------------------------------------------------------
-- Ultra-rare bonus loot that can drop from any extraction.
-- Creates exciting discovery moments with server-wide alerts.

Config.RareFinds = {
    enabled = true,

    -- Global base chance per extraction (0.01 = 1%). Modified by vein quality.
    baseChance = 0.008,  -- 0.8% base

    -- Vein quality bonus: high quality veins are more likely to yield rare finds.
    -- At quality 100, chance is baseChance * (1 + qualityBonus)
    qualityBonus = 1.5,  -- at quality 100: 0.8% * 2.5 = 2% chance

    -- Precision mode bonus multiplier (rewards careful mining)
    precisionBonus = 1.5,

    -- Green minigame result bonus multiplier
    greenBonus = 2.0,

    -- Server-wide discovery announcement
    announceToServer = true,

    -- XP bonus for finding a rare item (on top of normal mining XP)
    discoveryXp = 50,

    -- Discoverer gets a time-limited sell bonus
    sellBonusDuration = 3600,  -- seconds (1 hour)
    sellBonusMultiplier = 3.0, -- 3x sell price during bonus window

    -- Rare find items and their weights (higher = more common among rares)
    items = {
        ['pure_gold_nugget'] = {
            label = 'Pure Gold Nugget',
            weight = 40,
            sellPrice = 2500,
            description = 'A pristine gold nugget of exceptional purity',
        },
        ['ancient_fossil'] = {
            label = 'Ancient Fossil',
            weight = 30,
            sellPrice = 3500,
            description = 'A remarkably preserved prehistoric fossil',
        },
        ['flawless_crystal'] = {
            label = 'Flawless Crystal',
            weight = 20,
            sellPrice = 5000,
            description = 'A crystal of extraordinary clarity and size',
        },
        ['meteorite_fragment'] = {
            label = 'Meteorite Fragment',
            weight = 10,
            sellPrice = 8000,
            description = 'A fragment of extraterrestrial origin',
        },
    },
}

-----------------------------------------------------------
-- SAFETY EQUIPMENT
-----------------------------------------------------------

Config.Equipment = {
    ['mining_helmet'] = {
        label = 'Mining Helmet',
        price = 350,
        maxBattery = 100,        -- battery units
        drainRate = 1,           -- units drained per 30 seconds in dark zone
        lightRange = 15.0,       -- flashlight range
        lightIntensity = 5.0,    -- flashlight brightness
    },
    ['helmet_battery'] = {
        label = 'Helmet Battery',
        price = 50,
        restoreAmount = 50,      -- restores 50 battery units
    },
    ['respirator'] = {
        label = 'Respirator',
        price = 200,
        maxUses = 100,           -- total uses before replacement
    },
    ['wooden_support'] = {
        label = 'Wooden Support',
        price = 75,
        -- placeable item, consumed on use
        -- reduces cave-in chance in sub-zone for Config.CaveIn.supportDuration
    },
}

-----------------------------------------------------------
-- EXPLOSIVES
-----------------------------------------------------------

Config.Explosives = {
    -- Items
    items = {
        ['dynamite'] = {
            label = 'Dynamite',
            price = 750,
            levelRequired = 5,
            description = 'Explosive charge for blast mining veins',
        },
        ['blasting_charge'] = {
            label = 'Blasting Charge',
            price = 1400,
            levelRequired = 8,
            description = 'Heavy-duty charge for demolition and quarry blasting',
        },
        ['detonator'] = {
            label = 'Detonator',
            price = 2000,
            maxUses = 50,
            levelRequired = 5,
            description = 'Remote detonator. Required for all explosive operations.',
        },
        ['detonator_wire'] = {
            label = 'Detonator Wire',
            price = 150,
            description = 'Wiring kit for connecting multiple charges',
        },
    },

    -----------------------------------------------------------
    -- BLAST MINING (Concept 1) - Vein detonation
    -----------------------------------------------------------
    blastMining = {
        -- Dynamite consumed per vein blast
        dynamitePerBlast = 1,

        -- Safe distance: player must be this far from vein to detonate (units)
        safeDistance = 8.0,

        -- Damage if player is within blast radius when detonating
        blastDamage = 40,
        blastRadius = 6.0,

        -- Scattered ore pickups spawned after detonation
        scatterCount = { min = 8, max = 12 },
        scatterRadius = 6.0,

        -- Time (ms) for player to collect each scatter pickup
        pickupTime = 1500,

        -- How long scattered pickups persist before despawning (ms)
        pickupPersistence = 150000, -- 2.5 minutes

        -- Yield per pickup is derived from vein remaining/quality
        -- No minigame bonus (traded precision for speed)

        -- Hazard multiplier: blast mining multiplies the hazard roll chance
        hazardMultiplier = 3.0,

        -- Place charge animation duration (ms)
        placeTime = 4000,

        -- Prop for scattered ore pickups
        scatterModel = 'prop_rock_4_c',
        scatterPickupRadius = 1.0, -- ox_target interaction radius

        -- XP per blast
        xpReward = 15,
    },

    -----------------------------------------------------------
    -- DEMOLITION CHARGES (Concept 3) - Obstacle clearing
    -----------------------------------------------------------
    demolition = {
        -- Charges consumed per obstacle type
        chargesPerObstacle = 1,     -- boulders / debris
        chargesPerPassage = 2,      -- sealed passages

        -- Safe distance for demolition detonation
        safeDistance = 6.0,

        -- Blast damage / radius
        blastDamage = 30,
        blastRadius = 5.0,

        -- Rubble pickups from demolishing obstacles (LESS than manual mining)
        rubbleCount = { min = 2, max = 3 },
        pickupTime = 1500,

        -- Rubble loot: stone yield per pickup
        rubbleStoneYield = { min = 1, max = 3 },
        -- Ore chance per rubble pickup (same loot table as cave-in boulders)
        rubbleOreChance = 25,

        -- Sealed passage config
        passageVeinCount = { min = 2, max = 3 },
        passageDuration = 600000, -- 10 minutes before passage collapses
        -- Sealed passages use cave-in loot rolls for their pickups
        passageRubbleCount = { min = 3, max = 5 },

        -- Place charge animation duration (ms)
        placeTime = 3000,

        -- Prop for rubble pickups
        rubbleModel = 'prop_rock_4_b',
        rubblePickupRadius = 1.0,

        -- XP per demolition
        xpReward = 10,
    },

    -----------------------------------------------------------
    -- QUARRY BLASTING (Concept 4) - Pattern detonation
    -----------------------------------------------------------
    quarryBlasting = {
        -- Charges required per blast site (3 placement slots)
        chargesPerBlast = 3,

        -- Wiring kit consumed per blast
        wiresPerBlast = 1,

        -- Wiring animation duration (ms)
        wiringTime = 5000,

        -- Safe distance: must retreat to safe zone before detonation
        safeDistance = 12.0,

        -- Blast damage / radius (bigger than underground)
        blastDamage = 50,
        blastRadius = 10.0,

        -- Rubble pile pickups in the blast crater
        rubbleCount = { min = 14, max = 20 },
        pickupTime = 1200, -- faster, loose surface material

        -- Crater persistence (ms)
        craterDuration = 300000, -- 5 minutes

        -- Head start for the blaster before others see pickups (ms)
        blasterHeadStart = 10000,

        -- Blast site cooldown after use (ms)
        siteCooldown = 900000, -- 15 minutes

        -- Charge placement: optimal placement increases rubble count
        -- Green placement (close to center): full rubble count
        -- Yellow placement (moderate): 80% rubble
        -- Red placement (far from center): 65% rubble
        placementQuality = {
            green  = 1.0,
            yellow = 0.80,
            red    = 0.65,
        },

        -- Place charge animation duration per slot (ms)
        placeTime = 3000,

        -- Prop for rubble piles
        rubbleModel = 'prop_rock_4_b',
        rubblePickupRadius = 1.2,

        -- Rubble loot: random ore from quarry ore table
        -- Stone yield per rubble pile
        rubbleStoneYield = { min = 1, max = 4 },

        -- XP per quarry blast
        xpReward = 25,
    },

    -----------------------------------------------------------
    -- GAS EXPLOSION (triggered when detonating during gas leak)
    -----------------------------------------------------------
    gasExplosion = {
        -- Devastating damage in all instances
        damage = 80,
        radius = 15.0,

        -- Screen shake
        shakeAmplitude = 2.0,
        shakeDuration = 4000,

        -- Gas leak is instantly cleared by the explosion
        clearsGas = true,

        -- Ore scatters are NOT destroyed (player still gets them)
        destroysScatter = false,

        -- Visual effect
        explosionType = 2,  -- GTA explosion type (large fire)
        flashEffect = 'SwitchHUDIn',
    },
}

-----------------------------------------------------------
-- ADMIN & ECONOMY (Phase 8)
-----------------------------------------------------------

Config.Admin = {
    -- ACE permission required for admin commands
    acePermission = 'mining.admin',

    -- Economy multipliers (adjustable at runtime via admin commands)
    -- These are defaults; server/admin.lua keeps live overrides in memory.
    defaultMultipliers = {
        xp = 1.0,          -- global XP multiplier
        yield = 1.0,       -- global ore yield multiplier
        sellPrice = 1.0,   -- global sell price multiplier
        hazardRate = 1.0,  -- global hazard chance multiplier
        rareChance = 1.0,  -- global rare find chance multiplier
    },
}

-----------------------------------------------------------
-- ANTI-CHEAT (Phase 8)
-----------------------------------------------------------

Config.AntiCheat = {
    enabled = true,

    -- Position validation: max distance (units) from vein to accept extraction
    maxMiningDistance = 8.0,

    -- Per-vein cooldown: seconds before same player can mine same vein
    perVeinCooldown = 3,

    -- Rate limits (actions per window)
    rateLimits = {
        -- Max extractions per 60 seconds
        mining = { max = 20, window = 60 },
        -- Max sells per 60 seconds
        selling = { max = 15, window = 60 },
        -- Max purchases per 60 seconds
        purchase = { max = 10, window = 60 },
    },

    -- Flag thresholds: when exceeded, flag player for review
    flags = {
        -- If player earns more than this in a single hour, flag them
        hourlyEarningsThreshold = 50000,
        -- If player mines more than this ore in a single hour, flag them
        hourlyMiningThreshold = 500,
    },
}
