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
