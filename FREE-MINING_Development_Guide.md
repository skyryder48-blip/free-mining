# FREE-MINING: PHASED DEVELOPMENT GUIDE

**Project:** Hardcore Realistic Mining System for FiveM QBX Framework  
**Developer:** Creator  
**Framework:** QBX (QBox)  
**Version:** 1.0.0  
**Last Updated:** February 2026

---

## TABLE OF CONTENTS

1. [Development Philosophy](#development-philosophy)
2. [Feature Overview](#feature-overview)
3. [Phase 1: Foundation & Core Extraction](#phase-1-foundation--core-extraction)
4. [Phase 2: Equipment & Survival Basics](#phase-2-equipment--survival-basics)
5. [Phase 3: Dynamic Vein System & Exploration](#phase-3-dynamic-vein-system--exploration)
6. [Phase 4: Survey Equipment & Discovery](#phase-4-survey-equipment--discovery)
7. [Phase 5: Claim System & Territory](#phase-5-claim-system--territory)
8. [Phase 6: Multi-Stage Extraction & Tools](#phase-6-multi-stage-extraction--tools)
9. [Phase 7: Transportation Infrastructure](#phase-7-transportation-infrastructure)
10. [Phase 8: Cave-In System & Hazards](#phase-8-cave-in-system--hazards)
11. [Phase 9: Multi-Zone Expansion](#phase-9-multi-zone-expansion)
12. [Phase 10: NUI, Contracts & Progression](#phase-10-nui-contracts--progression)
13. [Phase 11: Processing & Economy Chain](#phase-11-processing--economy-chain)
14. [Phase 12: Polish, Optimization & Balance](#phase-12-polish-optimization--balance)
15. [Timeline & Milestones](#timeline--milestones)
16. [Recommended Approach](#recommended-approach)

---

## DEVELOPMENT PHILOSOPHY

### Core Principles
- **Each phase produces a fully functional, testable system**
- **No phase depends on incomplete future features**
- **Progressive complexity: simple → advanced**
- **Test and debug thoroughly before advancing**
- **Maintain backward compatibility as features are added**

### Design Philosophy
> **"Focus on active decision-making, risk/reward, and exploration rather than passive waiting. Every action should involve player choice and skill."**

This philosophy drives all design decisions throughout development.

---

## FEATURE OVERVIEW

### Core Features (Your Requirements)
1. ✅ Dynamic ore vein system with depletion and regeneration
2. ✅ Geological survey equipment
3. ✅ Core sampling mechanics
4. ✅ Claim staking system
5. ✅ Indicator minerals (prop-based location markers)
6. ✅ Equipment degradation over time
7. ✅ Helmet light system with rechargeable batteries
8. ✅ Toxic atmospheric hazards with gas mask/respirator system
9. ✅ Safety equipment integration with clothing system
10. ✅ Realistic weight system with mine cart transport
11. ✅ Multi-stage extraction process
12. ✅ Specialized tools for different ore types
13. ✅ Strategic ore selection and mining location choice
14. ✅ Cave-in system with warnings, prevention, and rescue mechanics
15. ✅ Variable ore quality based on vein and tool combination
16. ✅ NUI with contracts, missions, stats, and leaderboards
17. ✅ Complete ore processing chain (raw → refined → manufactured goods)

### Additional Features
18. Multi-zone architecture (Quarry, k4mb1 Cave, k4mb1 Mine Shaft)
19. Progression system with levels and specializations
20. Market dynamics with price fluctuation
21. Cooperative gameplay incentives
22. Anti-exploit systems

---

## PHASE 1: FOUNDATION & CORE EXTRACTION

**Objective:** Establish basic mining loop in a single location with essential systems

**Duration:** 1-2 weeks  
**Complexity:** ⭐⭐☆☆☆

### Features Implemented

#### 1. Basic Database Schema
```sql
-- mining_stats table
CREATE TABLE IF NOT EXISTS `mining_stats` (
    `player_id` VARCHAR(50) PRIMARY KEY,
    `level` INT DEFAULT 1,
    `experience` INT DEFAULT 0,
    `total_mined` INT DEFAULT 0,
    `hours_worked` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- mining_equipment table
CREATE TABLE IF NOT EXISTS `mining_equipment` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(50),
    `item_name` VARCHAR(50),
    `durability` FLOAT DEFAULT 100.0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`player_id`) REFERENCES `players`(`citizenid`)
);
```

#### 2. Single Mining Zone Setup
- Define zone coordinates and boundaries
- Static ore spawn points (manual placement, not dynamic yet)
- 3-4 basic ore types implemented:
  - **Copper Ore** (common, low value)
  - **Iron Ore** (common, medium value)
  - **Limestone** (abundant, construction material)
  - **Gold Ore** (rare, high value)

#### 3. Simple Equipment System
- **Pickaxe tiers:**
  - Wooden Pickaxe (50 uses, slow)
  - Iron Pickaxe (200 uses, medium)
  - Steel Pickaxe (500 uses, fast)
- **Shovel** for gravel/dirt
- Items integrate with ox_inventory
- Basic durability system (decreases on use)

#### 4. Core Extraction Mechanic
- ox_lib progressCircle for mining animation
- Tool-to-ore validation (correct tool required)
- Random ore chunk drops (1-3 per mining action)
- Base ore items added to inventory
- Animation plays during extraction

#### 5. Weight & Carry System
- Raw ore has realistic weight:
  - Iron ore = 5kg per chunk
  - Copper ore = 4kg per chunk
  - Gold ore = 8kg per chunk
  - Limestone = 3kg per chunk
- Player carry capacity enforcement (default 50kg)
- Overweight prevents running/sprinting

#### 6. Basic Processing (Smelting only)
- Simple furnace location
- Convert raw ore → ingots (1:1 ratio initially)
- ox_lib progress bar for smelting time
- Sell ingots to NPC for cash

### Configuration Structure
```lua
Config = {}

Config.Zones = {
    quarry = {
        enabled = true,
        center = vector3(0.0, 0.0, 0.0), -- Update coordinates
        radius = 100.0,
        ores = {
            {type = 'copper', chance = 40},
            {type = 'iron', chance = 35},
            {type = 'limestone', chance = 20},
            {type = 'gold', chance = 5}
        }
    }
}

Config.Tools = {
    ['pickaxe_wood'] = {
        durability = 50,
        speed = 1.0,
        ores = {'copper', 'iron', 'limestone'}
    },
    ['pickaxe_iron'] = {
        durability = 200,
        speed = 1.5,
        ores = {'copper', 'iron', 'limestone', 'gold'}
    },
    ['pickaxe_steel'] = {
        durability = 500,
        speed = 2.0,
        ores = {'copper', 'iron', 'limestone', 'gold'}
    },
    ['shovel'] = {
        durability = 100,
        speed = 1.2,
        ores = {'gravel', 'dirt'}
    }
}

Config.Ores = {
    ['copper'] = {
        label = 'Copper Ore',
        weight = 4.0,
        minAmount = 1,
        maxAmount = 3,
        miningTime = 5000, -- ms
        smeltTime = 10000,
        smeltOutput = 'copper_ingot',
        sellPrice = 50
    },
    ['iron'] = {
        label = 'Iron Ore',
        weight = 5.0,
        minAmount = 1,
        maxAmount = 3,
        miningTime = 6000,
        smeltTime = 12000,
        smeltOutput = 'iron_ingot',
        sellPrice = 75
    },
    ['gold'] = {
        label = 'Gold Ore',
        weight = 8.0,
        minAmount = 1,
        maxAmount = 2,
        miningTime = 10000,
        smeltTime = 15000,
        smeltOutput = 'gold_ingot',
        sellPrice = 200
    },
    ['limestone'] = {
        label = 'Limestone',
        weight = 3.0,
        minAmount = 2,
        maxAmount = 4,
        miningTime = 4000,
        smeltTime = 8000,
        smeltOutput = 'limestone_processed',
        sellPrice = 25
    }
}
```

### Testing Criteria
- [ ] Can mine 4 ore types with appropriate tools
- [ ] Tools degrade and break after X uses
- [ ] Ore has weight and limits carrying
- [ ] Can smelt and sell for profit
- [ ] No duplication exploits
- [ ] Database correctly tracks stats
- [ ] Server performance stable (<2ms average)

### Deliverables
```
free-mining/
├── fxmanifest.lua
├── config.lua
├── shared/
│   └── items.lua
├── server/
│   ├── main.lua
│   ├── processing.lua
│   └── database.lua
├── client/
│   └── mining.lua
└── sql/
    └── install.sql
```

### Files to Create
1. **fxmanifest.lua** - Resource manifest
2. **config.lua** - All configuration options
3. **shared/items.lua** - Item definitions for ox_inventory
4. **server/main.lua** - Core server logic, ore extraction validation
5. **server/processing.lua** - Smelting and selling system
6. **server/database.lua** - Database operations
7. **client/mining.lua** - Client-side mining interactions, animations
8. **sql/install.sql** - Database table creation

### Key Functions to Implement
- `StartMining(oreType)` - Client initiates mining
- `ValidateMining(player, ore, tool)` - Server validates action
- `ReduceDurability(player, tool, amount)` - Server updates tool durability
- `GiveOre(player, ore, amount)` - Server awards ore
- `SmeltOre(player, ore, amount)` - Server processes smelting
- `SellIngots(player, ingot, amount)` - Server handles selling

---

## PHASE 2: EQUIPMENT & SURVIVAL BASICS

**Objective:** Add safety equipment, degradation, and basic hazard systems

**Duration:** 2 weeks  
**Complexity:** ⭐⭐⭐☆☆

### Features Implemented

#### 7. Equipment Degradation Expansion
- All mining tools have visible durability UI
- Durability displays in tooltip/inspection
- Repair kit item (restores 25% durability)
- Complete tool failure when 0% durability
- Field repair mechanic with animation
- Tools cannot be used when broken

#### 8. Helmet Light System
- **Helmet Item:** `mining_helmet` with integrated light
- **Battery percentage tracking** (60 min runtime at 100%)
- **Three brightness modes:**
  - Low: 30% brightness, 1% drain per minute
  - Medium: 60% brightness, 1.5% drain per minute  
  - High: 100% brightness, 2.5% drain per minute
- Light source attached to player ped bone
- **Charging stations:**
  - Surface stations (instant charge)
  - Vehicle charging (slower, requires running engine)
  - Portable generators (deployable)
- **Emergency chemical light sticks** (single-use, 10 min duration)
- Battery HUD indicator

#### 9. Clothing System Integration
- Helmet prop spawns when equipped
- Safety vest prop spawns when equipped
- Gas mask prop (not functional yet, visual only)
- Uses existing clothing system hooks
- Props attach to correct ped bones
- Props despawn when item removed from inventory

#### 10. Basic Atmospheric Hazard (Single gas type)
- **Carbon Monoxide zones** in one cave area
- Health drain: -2 HP per second when exposed
- Gas detector item (beeps when nearby)
- Beep frequency increases with concentration
- Basic respirator provides 75% protection
- Screen effects when exposed (blur, vignette)

#### 11. Stamina System
- Mining drains stamina 3x faster than walking
- Carrying heavy ore drains stamina 2x faster
- Low stamina (<20%) = 50% slower actions
- Rest mechanic to recover (stand still)
- Hydration item reduces stamina drain
- Stamina HUD bar

### Configuration Additions
```lua
Config.Equipment = {
    ['mining_helmet'] = {
        durability = 1000, -- uses before degradation
        batteryCapacity = 100, -- percentage
        lightModes = {
            {name = 'low', brightness = 30, drainRate = 1.0},
            {name = 'medium', brightness = 60, drainRate = 1.5},
            {name = 'high', brightness = 100, drainRate = 2.5}
        },
        prop = 'prop_hard_hat_01',
        bone = 'head'
    },
    ['safety_vest'] = {
        durability = 500,
        prop = 'prop_safety_vest_01',
        bone = 'torso'
    },
    ['respirator'] = {
        durability = 300,
        protection = 0.75, -- 75% gas protection
        prop = 'prop_gas_mask_01',
        bone = 'head'
    },
    ['repair_kit'] = {
        restoreAmount = 25, -- percentage
        usageTime = 5000 -- ms
    }
}

Config.Hazards = {
    gasZones = {
        {
            coords = vector3(0.0, 0.0, 0.0),
            radius = 25.0,
            gasType = 'carbon_monoxide',
            concentration = 80, -- percentage
            damageRate = 2 -- HP per second
        }
    }
}

Config.Stamina = {
    miningDrainMultiplier = 3.0,
    carryingDrainMultiplier = 2.0,
    regenRate = 5.0, -- per second when resting
    lowStaminaThreshold = 20
}
```

### Testing Criteria
- [ ] Helmet light illuminates caves, drains battery
- [ ] Can charge batteries at stations
- [ ] Tools break and can be repaired
- [ ] Gas zones damage player without respirator
- [ ] Clothing props appear/disappear correctly
- [ ] Stamina affects mining speed
- [ ] All equipment durability tracked in database

### Deliverables
```
free-mining/
├── client/
│   ├── equipment.lua (NEW)
│   ├── lighting.lua (NEW)
│   └── hazards.lua (NEW)
├── server/
│   └── equipment.lua (NEW)
└── config/
    └── equipment.lua (NEW)
```

### Key Functions to Implement
- `ToggleHelmetLight(mode)` - Switch light modes
- `ChargeBattery(source)` - Charge at station
- `AttachProp(player, item, prop, bone)` - Spawn equipment prop
- `RemoveProp(player, prop)` - Despawn equipment prop
- `CheckGasZone(coords)` - Detect if player in hazard
- `ApplyGasDamage(player, gasType, protection)` - Calculate damage
- `RepairTool(player, tool, kit)` - Restore durability

---

## PHASE 3: DYNAMIC VEIN SYSTEM & EXPLORATION

**Objective:** Replace static ore points with dynamic procedural veins

**Duration:** 2-3 weeks  
**Complexity:** ⭐⭐⭐⭐☆

### Features Implemented

#### 12. Database Schema Expansion
```sql
CREATE TABLE IF NOT EXISTS `mining_veins` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `coords` VARCHAR(100) NOT NULL,
    `ore_type` VARCHAR(50) NOT NULL,
    `total_quantity` INT NOT NULL,
    `remaining_quantity` INT NOT NULL,
    `quality` FLOAT NOT NULL,
    `zone` VARCHAR(50) NOT NULL,
    `discovered` BOOLEAN DEFAULT FALSE,
    `discovered_by` VARCHAR(50) DEFAULT NULL,
    `depleted` BOOLEAN DEFAULT FALSE,
    `depleted_at` TIMESTAMP NULL,
    `regenerate_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_zone` (`zone`),
    INDEX `idx_ore_type` (`ore_type`),
    INDEX `idx_depleted` (`depleted`)
);
```

#### 13. Dynamic Ore Vein System
- **Server-side vein spawning** on resource start/restart
- Configurable vein density per zone (veins per km²)
- **Vein properties:**
  - `ore_type`: Copper, Iron, Gold, etc.
  - `total_quantity`: 500-5000 units (random within range)
  - `quality`: 20-95% (affects yield and value)
  - `coords`: Random spawn within zone boundaries
- Randomized spawn points within defined zone polygons
- Server-side depletion tracking (global, not per-player)
- Vein data cached in memory for performance

#### 14. Vein Depletion & Regeneration
- Each extraction reduces `remaining_quantity`
- Vein marked "depleted" when quantity reaches 0
- Depleted veins removed from active cache
- **Regeneration timer:** 24-72 hours (configurable)
- Database cleanup of old depleted veins (>30 days)
- Regenerated veins spawn in different location with new properties

#### 15. Indicator Minerals (Surface Clues)
- Spawn prop models near vein locations
- **Different props for different ore types:**
  - Copper vein → `prop_rock_copper_01`
  - Iron vein → `prop_rock_iron_01`
  - Gold vein → `prop_rock_gold_01`
- Props visible on surface above underground veins
- Surface distance from vein: 0-15 meters (random offset)
- Props despawn when vein depleted
- Multiple indicator props per rich vein (3-5 props)

#### 16. Ore Quality System
- **Quality percentage** stored per vein (random 20-95%)
- Quality affects:
  - Ore yield per extraction (higher quality = more ore)
  - Sell price multiplier
  - Smelting output quantity
- Same vein can have quality variance (±10% per extraction)
- **Display quality rating:**
  - 0-30%: "Waste Rock"
  - 31-50%: "Low Grade"
  - 51-70%: "Medium Grade"
  - 71-90%: "High Grade"
  - 91-100%: "Pure Ore"

### Configuration Additions
```lua
Config.VeinGeneration = {
    enabled = true,
    regenerateOnRestart = true,
    
    quarry = {
        density = 15, -- veins per zone
        oreDistribution = {
            copper = 40,
            iron = 30,
            limestone = 25,
            gold = 5
        },
        quantityRange = {min = 500, max = 2000},
        qualityRange = {min = 30, max = 80}
    },
    
    cave = {
        density = 10,
        oreDistribution = {
            copper = 20,
            iron = 20,
            gold = 30,
            silver = 20,
            emerald = 10
        },
        quantityRange = {min = 800, max = 3000},
        qualityRange = {min = 40, max = 95}
    }
}

Config.VeinRegeneration = {
    enabled = true,
    timeHours = 48, -- hours until regeneration
    notifyOnRegen = true,
    cleanupOldVeins = true,
    cleanupAfterDays = 30
}

Config.IndicatorProps = {
    ['copper'] = 'prop_rock_1_a',
    ['iron'] = 'prop_rock_1_b',
    ['gold'] = 'prop_rock_1_c',
    ['silver'] = 'prop_rock_1_d',
    ['emerald'] = 'prop_rock_1_e'
}
```

### Vein Generation Algorithm
```lua
function GenerateVein(zone, oreType)
    local coords = GetRandomCoordsInZone(zone)
    local quantity = math.random(
        Config.VeinGeneration[zone].quantityRange.min,
        Config.VeinGeneration[zone].quantityRange.max
    )
    local quality = math.random(
        Config.VeinGeneration[zone].qualityRange.min,
        Config.VeinGeneration[zone].qualityRange.max
    )
    
    return {
        coords = coords,
        ore_type = oreType,
        total_quantity = quantity,
        remaining_quantity = quantity,
        quality = quality,
        zone = zone
    }
end
```

### Testing Criteria
- [ ] Veins generate on server start in configured zones
- [ ] Indicator props spawn correctly at surface
- [ ] Veins deplete with mining activity
- [ ] Depleted veins regenerate after timer expires
- [ ] Quality affects yields and prices correctly
- [ ] Server performance stable with 50+ active veins
- [ ] No vein duplication or spawn issues
- [ ] Database queries optimized (<5ms)

### Deliverables
```
free-mining/
├── server/
│   ├── veins.lua (NEW)
│   └── database.lua (UPDATED)
├── client/
│   └── veins.lua (NEW)
└── config/
    └── veins.lua (NEW)
```

### Key Functions to Implement
- `GenerateVeinsForZone(zone)` - Create veins on startup
- `GetNearestVein(coords, radius)` - Find closest vein to player
- `DepletVein(veinId, amount)` - Reduce vein quantity
- `MarkVeinDepleted(veinId)` - Flag vein as empty
- `RegenerateVein(veinId)` - Respawn depleted vein
- `SpawnIndicatorProps(vein)` - Create surface markers
- `DespawnIndicatorProps(vein)` - Remove surface markers
- `GetVeinQuality(veinId)` - Calculate quality modifier

---

## PHASE 4: SURVEY EQUIPMENT & DISCOVERY

**Objective:** Add exploration gameplay with detection tools

**Duration:** 2 weeks  
**Complexity:** ⭐⭐⭐☆☆

### Features Implemented

#### 17. Geological Survey Equipment

**Metal Detector (Tier 1)**
- Audio ping system (beep frequency)
- Detection range: 10 meters
- Beeps faster as you approach vein
- Battery powered (drains during use)
- Visual indicator on screen (signal strength bar)

**Ground Penetrating Radar - GPR (Tier 2)**
- Visual overlay UI showing heat map
- Detection range: 25 meters
- Shows vein direction and approximate distance
- Battery powered (heavier drain than detector)
- Requires standing still to use
- 5-second scan animation

**Seismic Survey Kit (Tier 3)**
- Deploy sensor equipment (placeable props)
- Creates 3D map of nearby veins (100m radius)
- Requires 3+ sensors in triangulation pattern
- Setup time: 30 seconds per sensor
- Results displayed on tablet interface
- Reusable sensors (pick up after use)

#### 18. Geological Analysis System
- **Core drill rig** item (placeable heavy equipment)
- Extract core sample (reveals vein data without mining)
- **Sample analysis shows:**
  - Ore type
  - Estimated total quantity
  - Quality percentage
  - Depth from surface
- Analysis takes 60 seconds
- Results stored in "Survey Report" item
- Reports can be traded/sold to other players
- Core sample prop appears during drilling

#### 19. Survey Data Management
- **Tablet/notebook item** stores survey data
- **Log discovered vein locations** with GPS coordinates
- Mark veins as:
  - "Claimed" (you own this)
  - "Depleted" (mined out)
  - "High Priority" (rich vein)
  - "Shared" (crew access)
- **Share coordinates** with team members via in-game email
- Export data to printable format
- Quick navigation to logged veins

### Configuration Additions
```lua
Config.SurveyEquipment = {
    ['metal_detector'] = {
        tier = 1,
        range = 10.0,
        batteryDrain = 0.5, -- % per minute
        pingInterval = 1000, -- ms between beeps
        accuracy = 0.7 -- 70% accurate ore type detection
    },
    ['gpr_scanner'] = {
        tier = 2,
        range = 25.0,
        batteryDrain = 1.5,
        scanTime = 5000, -- ms
        accuracy = 0.9,
        requiresStanding = true
    },
    ['seismic_kit'] = {
        tier = 3,
        range = 100.0,
        setupTime = 30000,
        minSensors = 3,
        accuracy = 1.0,
        sensorProp = 'prop_seismic_sensor'
    },
    ['core_drill'] = {
        setupTime = 10000,
        drillTime = 60000,
        durability = 50, -- uses
        reportItem = 'survey_report'
    }
}
```

### Survey Tablet NUI
```
┌──────────────────────────────────────┐
│ MINING SURVEY TABLET                 │
├──────────────────────────────────────┤
│ [All] [Claimed] [Priority] [Depleted]│
├──────────────────────────────────────┤
│ Vein #047 - Gold                     │
│ Quality: 87% (High Grade)            │
│ Est. Quantity: 2,450 units           │
│ Coords: X: 1234 Y: 5678 Z: 32       │
│ [Navigate] [Share] [Claim]           │
├──────────────────────────────────────┤
│ Vein #103 - Copper                   │
│ Quality: 45% (Medium Grade)          │
│ Est. Quantity: 1,200 units           │
│ Coords: X: 2345 Y: 6789 Z: 28       │
│ [Navigate] [Share] [Claim]           │
└──────────────────────────────────────┘
```

### Testing Criteria
- [ ] Metal detector beeps increase frequency near veins
- [ ] GPR shows accurate heat map overlay
- [ ] Seismic kit requires proper sensor placement
- [ ] Core samples reveal accurate vein information
- [ ] Survey reports tradeable between players
- [ ] Tablet UI displays saved vein data
- [ ] Navigation to logged veins functional
- [ ] Battery drain balanced and noticeable

### Deliverables
```
free-mining/
├── client/
│   ├── survey.lua (NEW)
│   └── ui/
│       └── survey_tablet.lua (NEW)
├── server/
│   └── survey.lua (NEW)
└── html/
    ├── survey_tablet.html (NEW)
    ├── survey_tablet.css (NEW)
    └── survey_tablet.js (NEW)
```

### Key Functions to Implement
- `UseMetalDetector()` - Start detection, play beep audio
- `CalculateSignalStrength(playerCoords, veinCoords)` - Distance calculation
- `UseGPR()` - Show heat map overlay
- `RenderHeatMap(veins)` - Draw overlay UI
- `PlaceSeismicSensor(coords)` - Deploy sensor prop
- `CalculateTriangulation(sensors)` - Find veins from sensor array
- `DrillCoreSample(veinId)` - Extract sample data
- `GenerateSurveyReport(veinData)` - Create report item
- `OpenSurveyTablet()` - Show NUI
- `AddVeinToTablet(veinId, data)` - Log discovery

---

## PHASE 5: CLAIM SYSTEM & TERRITORY

**Objective:** Player-owned mining claims with economic mechanics

**Duration:** 1-2 weeks  
**Complexity:** ⭐⭐⭐☆☆

### Features Implemented

#### 20. Database Schema
```sql
CREATE TABLE IF NOT EXISTS `mining_claims` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(50) NOT NULL,
    `vein_id` INT NOT NULL,
    `stake_coords` VARCHAR(100) NOT NULL,
    `claim_type` ENUM('daily', 'weekly', 'monthly') NOT NULL,
    `purchase_price` INT NOT NULL,
    `purchased_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NOT NULL,
    `total_extracted` INT DEFAULT 0,
    `last_activity` TIMESTAMP NULL,
    `status` ENUM('active', 'expired', 'abandoned') DEFAULT 'active',
    FOREIGN KEY (`vein_id`) REFERENCES `mining_veins`(`id`) ON DELETE CASCADE,
    INDEX `idx_player` (`player_id`),
    INDEX `idx_vein` (`vein_id`),
    INDEX `idx_status` (`status`)
);
```

#### 21. Claim Staking System
- Purchase claim stakes from mining office NPC
- **Claim types:**
  - 24-hour: $500 (temporary exploration)
  - 7-day: $2,000 (short-term operation)
  - 30-day: $5,000 (long-term investment)
- Place physical stake prop at vein location
- Claim covers vein + 15-meter radius
- Visual marker showing claim boundary (particle effects)
- Stake prop shows claim owner name on inspection

#### 22. Claim Management
- **Ownership validation:** Only claim owner can mine claimed vein
- Attempt to mine shows "This vein is claimed by [PlayerName]"
- **Expiration system:**
  - Auto-remove claim after duration expires
  - 24-hour warning notification before expiration
  - Option to renew claim (pay extension fee)
- **Abandonment mechanic:**
  - No activity for 5 consecutive days = claimable by others
  - Warning after 3 days of inactivity
- **Claim transfer/sale system:**
  - Owner can transfer to another player
  - Set asking price for claim sale
  - Marketplace for claim listings

#### 23. Claim Disputes
- Detect multiple stakes placed on same vein
- First valid stake wins (timestamp-based)
- Second stake attempt denied with notification
- Admin tools to resolve disputes manually
- Dispute log stored in database

#### 24. Claim Benefits
- Claimed veins show on personal map with special icon
- **Production tracking:**
  - Total ore extracted from claim
  - Revenue generated
  - Time invested
- **Shared claims:**
  - Crew/gang ownership option
  - Split profits among members
  - Designate co-owners (max 3 players)
- **Claim upgrades:**
  - Install infrastructure (lighting, supports)
  - Upgrade claim duration for discount
  - Exclusive access to rare veins

### Configuration Additions
```lua
Config.Claims = {
    enabled = true,
    
    claimTypes = {
        daily = {
            duration = 24, -- hours
            price = 500,
            label = '24-Hour Claim'
        },
        weekly = {
            duration = 168, -- hours (7 days)
            price = 2000,
            label = '7-Day Claim'
        },
        monthly = {
            duration = 720, -- hours (30 days)
            price = 5000,
            label = '30-Day Claim'
        }
    },
    
    claimRadius = 15.0, -- meters
    abandonmentDays = 5,
    maxClaimsPerPlayer = 5,
    allowTransfers = true,
    transferFee = 100, -- flat fee
    
    stakeProps = {
        model = 'prop_flagpole_2b',
        offset = vector3(0.0, 0.0, 0.0)
    }
}
```

### Claim UI Component
```
┌──────────────────────────────────────┐
│ MY MINING CLAIMS                     │
├──────────────────────────────────────┤
│ Claim #1 - Gold Vein (Weekly)        │
│ Expires: 4 days, 12 hours           │
│ Extracted: 1,247 / 2,450 units      │
│ Revenue: $24,940                     │
│ [Renew $2000] [Transfer] [Navigate] │
├──────────────────────────────────────┤
│ Claim #2 - Copper Vein (Monthly)     │
│ Expires: 22 days, 3 hours           │
│ Extracted: 234 / 1,800 units        │
│ Revenue: $4,680                      │
│ [Renew $5000] [Transfer] [Navigate] │
└──────────────────────────────────────┘
```

### Testing Criteria
- [ ] Can purchase and place claim stakes
- [ ] Claim ownership prevents unauthorized mining
- [ ] Expiration system works correctly (auto-remove)
- [ ] Can transfer claims to other players
- [ ] Dispute detection prevents double-claiming
- [ ] Database tracks all claim transactions
- [ ] Shared claims split profits correctly
- [ ] Abandonment timer functions as expected

### Deliverables
```
free-mining/
├── server/
│   └── claims.lua (NEW)
├── client/
│   └── claims.lua (NEW)
└── html/
    ├── claims_ui.html (NEW)
    ├── claims_ui.css (NEW)
    └── claims_ui.js (NEW)
```

### Key Functions to Implement
- `PurchaseClaimStake(player, claimType)` - Buy stake from NPC
- `PlaceStake(player, coords, veinId)` - Place physical stake
- `ValidateClaimOwnership(player, veinId)` - Check if player can mine
- `CheckClaimExpiration()` - Server loop checking expirations
- `TransferClaim(fromPlayer, toPlayer, claimId, price)` - Trade claim
- `RenewClaim(player, claimId)` - Extend claim duration
- `DetectClaimDispute(veinId)` - Check for multiple stakes
- `AbandonClaim(claimId)` - Mark claim as abandoned
- `GetPlayerClaims(player)` - Fetch all claims for UI

---

## PHASE 6: MULTI-STAGE EXTRACTION & TOOLS

**Objective:** Expand mining workflow with preparation and precision

**Duration:** 2-3 weeks  
**Complexity:** ⭐⭐⭐⭐☆

### Features Implemented

#### 25. Multi-Stage Extraction Workflow

**Stage 1: Survey**
- Use survey equipment to locate vein
- Analyze vein quality and quantity
- Decide if vein is worth claiming/mining

**Stage 2: Site Preparation**
- Clear debris and loose rocks (pick up/remove props)
- Install support beams if in high-risk area
- Set up temporary lighting (portable work lights)
- Stage equipment (organize tools and carts)

**Stage 3: Extraction**
- Select appropriate tool for ore type
- Choose extraction mode (aggressive vs. precision)
- Complete precision mining minigame (optional)
- Ore chunks spawn as physics props

**Stage 4: Collection**
- Manually pick up ore chunks (heavy, limited carry)
- Visual feedback showing weight accumulation
- Organize chunks for transport

**Stage 5: Transport**
- Load chunks into mine cart or haul bag
- Push cart to collection point
- Empty at processing facility

#### 26. Tool Specialization Matrix

| Ore Type | Tier 1 (Required) | Tier 2 (Better) | Tier 3 (Best) |
|----------|-------------------|-----------------|---------------|
| Gravel/Dirt | Shovel | - | - |
| Limestone | Pickaxe | Steel Pickaxe | - |
| Copper | Steel Pickaxe | Rock Drill | - |
| Iron | Steel Pickaxe | Rock Drill | - |
| Gold | Rock Drill | Jackhammer | - |
| Silver | Rock Drill | Jackhammer | - |
| Emerald | Precision Drill | - | - |
| Quartz | Precision Drill | - | - |
| Platinum | Diamond Drill | - | - |
| Titanium | Diamond Drill | Explosives | - |
| Diamonds | Diamond Drill | - | - |

**Tool Effects:**
- Wrong tool = 50% yield penalty or cannot mine
- Higher tier tools = faster extraction + better quality
- Tool wear increases with ore hardness

#### 27. Precision Mining Minigame

**Option A: Target Zone System**
- Circular reticle with moving target zone
- Hit target zone = bonus ore (150% yield)
- Hit close = normal yield
- Miss = reduced yield (75%)
- Difficulty scales with ore rarity

**Option B: QTE (Quick Time Event)**
- Button prompts appear in sequence
- Correct sequence = quality boost
- Failed sequence = normal yield
- More complex for rare ores

**Option C: Rhythm-Based**
- Hit marks in time with pickaxe swings
- Perfect timing = bonus
- Consistent rhythm = quality boost
- Miss timing = tool damage

*Player can skip minigame for base yields*

#### 28. Strategic Mining Choices

**Aggressive Mode:**
- 200% extraction speed
- 70% base quality
- 150% tool durability loss
- Higher cave-in risk

**Balanced Mode:**
- 100% extraction speed
- 100% base quality
- 100% tool durability loss
- Normal cave-in risk

**Precision Mode:**
- 50% extraction speed
- 130% base quality
- 75% tool durability loss
- Lower cave-in risk

*Mode selection shows real-time impact on HUD*

### Configuration Additions
```lua
Config.Tools = {
    ['pickaxe_wood'] = {
        tier = 1,
        ores = {'limestone', 'gravel'},
        speed = 1.0,
        qualityMod = 0.8,
        durability = 50
    },
    ['pickaxe_steel'] = {
        tier = 2,
        ores = {'limestone', 'copper', 'iron'},
        speed = 1.5,
        qualityMod = 1.0,
        durability = 200
    },
    ['rock_drill'] = {
        tier = 2,
        ores = {'copper', 'iron', 'gold', 'silver'},
        speed = 2.0,
        qualityMod = 1.2,
        durability = 150,
        requiresPower = true
    },
    ['precision_drill'] = {
        tier = 3,
        ores = {'emerald', 'quartz'},
        speed = 1.0,
        qualityMod = 1.5,
        durability = 100,
        requiresPower = true
    },
    ['diamond_drill'] = {
        tier = 3,
        ores = {'platinum', 'titanium', 'diamonds'},
        speed = 1.5,
        qualityMod = 1.3,
        durability = 300,
        requiresPower = true
    }
}

Config.MiningModes = {
    aggressive = {
        speedMod = 2.0,
        qualityMod = 0.7,
        durabilityMod = 1.5,
        caveInRisk = 1.5
    },
    balanced = {
        speedMod = 1.0,
        qualityMod = 1.0,
        durabilityMod = 1.0,
        caveInRisk = 1.0
    },
    precision = {
        speedMod = 0.5,
        qualityMod = 1.3,
        durabilityMod = 0.75,
        caveInRisk = 0.6
    }
}

Config.Minigame = {
    enabled = true,
    optional = true, -- can be skipped
    difficulty = {
        copper = 'easy',
        iron = 'easy',
        gold = 'medium',
        platinum = 'hard',
        diamonds = 'expert'
    },
    bonusMultiplier = 1.5, -- 150% on perfect
    failurePenalty = 0.75 -- 75% on failure
}
```

### Testing Criteria
- [ ] All 5 extraction stages functional and sequential
- [ ] Tool requirements enforced correctly
- [ ] Wrong tool shows penalty or denial
- [ ] Minigame provides meaningful bonuses
- [ ] Speed/quality/precision modes have observable effects
- [ ] Ore chunks spawn as physical props
- [ ] Can complete full workflow solo
- [ ] Site preparation affects mining efficiency
- [ ] Tool tier progression feels rewarding

### Deliverables
```
free-mining/
├── client/
│   ├── extraction.lua (NEW)
│   └── minigame.lua (NEW)
├── server/
│   └── extraction.lua (NEW)
├── shared/
│   └── tool_matrix.lua (NEW)
└── html/
    ├── minigame.html (NEW)
    ├── minigame.css (NEW)
    └── minigame.js (NEW)
```

### Key Functions to Implement
- `StartSitePreparation(veinId)` - Initialize prep stage
- `ClearDebris(coords)` - Remove loose rocks
- `InstallSupport(coords)` - Place support beam
- `SelectMiningMode(mode)` - Set aggressive/balanced/precision
- `ValidateTool(tool, oreType)` - Check tool compatibility
- `StartMinigame(difficulty)` - Launch minigame UI
- `CalculateYield(vein, tool, mode, minigameScore)` - Compute ore reward
- `SpawnOreProps(coords, ore, amount)` - Create physics props
- `CollectOreChunks(player)` - Pick up spawned ore

---

## PHASE 7: TRANSPORTATION INFRASTRUCTURE

**Objective:** Realistic heavy load transport systems

**Duration:** 2 weeks  
**Complexity:** ⭐⭐⭐☆☆

### Features Implemented

#### 29. Mine Cart System
- **Spawnable mine cart entity** (physics-based vehicle)
- Push/pull mechanics using directional input
- **Rail system:**
  - Carts move 3x faster on rails
  - Rails placeable in tunnels
  - Auto-pathing on rail networks
- **Load capacity:** 500kg maximum
- Load/unload interaction menu
- Cart shows weight fill level visually
- Unload at designated collection points
- Carts auto-despawn when empty and away from players

#### 30. Weight System Overhaul
- Enhanced carry weight calculation
- **Carry penalties:**
  - 0-50%: Normal movement
  - 51-80%: -25% movement speed, slight stamina drain
  - 81-100%: -50% movement speed, cannot jump
  - 101%+: Cannot move, must drop items
- **Visual indicators:**
  - Backpack prop scales with weight
  - Player ped leans when heavy loaded
  - Struggle animation when overweight
- **Team carry option:**
  - 2 players can carry together (combined capacity)
  - Requires both players to maintain proximity
  - Split weight between players

#### 31. Transport Methods by Zone

**Surface Quarry:**
- **Haul trucks:** Drivable dump trucks
  - Load ore into truck bed
  - Vehicle weight affects handling and speed
  - Fuel consumption increases with load
- **Conveyor belts:** Automated transport
  - Place ore on belt, auto-moves to collection
  - Slower than truck but hands-free
  - Requires power supply

**Cave System:**
- **Mine carts:** Manual push on improvised rails
- **Hand carry:** Backpack/sack system
- **Rope pulley:** Vertical shaft transport
  - Attach ore load to rope
  - Crank mechanism to raise/lower

**Mine Shaft:**
- **Elevator cages:** Multi-floor access
  - Call elevator from any level
  - Load ore into cage
  - Automated vertical transport
- **Skip hoists:** Industrial ore buckets
  - Large capacity (1000kg)
  - Automated cycling system

#### 32. Vehicle Integration (Quarry)
- Dump trucks can be loaded with ore
- **Loading process:**
  - Park near collection point
  - Select "Load Truck" option
  - Transfer ore from inventory to vehicle
  - Truck bed visually fills with ore props
- Vehicle weight affects:
  - Acceleration and braking
  - Top speed reduced
  - Handling (wider turning radius)
  - Fuel consumption (+50% when full)
- Unload at processing facility
- Automatic weight calculation

### Configuration Additions
```lua
Config.Transport = {
    mineCarts = {
        enabled = true,
        model = 'prop_minecart_01',
        maxWeight = 500, -- kg
        pushSpeed = 2.0, -- m/s off rails
        railSpeed = 6.0, -- m/s on rails
        spawnLocations = {
            vector3(0, 0, 0), -- cave entrance
            vector3(0, 0, 0)  -- mine shaft level 1
        }
    },
    
    rails = {
        enabled = true,
        model = 'prop_rail_straight',
        snapDistance = 2.0,
        maxLength = 500 -- meters per rail network
    },
    
    haulTrucks = {
        enabled = true,
        models = {'rubble', 'benson'},
        maxWeight = 2000, -- kg
        loadTime = 5000, -- ms per 100kg
        unloadTime = 10000
    },
    
    elevators = {
        enabled = true,
        levels = {
            {name = 'Surface', z = 100.0},
            {name = 'Level 1', z = 50.0},
            {name = 'Level 2', z = 0.0},
            {name = 'Level 3', z = -50.0}
        },
        capacity = 800, -- kg
        travelTime = 5000 -- ms per level
    }
}

Config.Weight = {
    carryCapacity = 50, -- kg base
    penalties = {
        {threshold = 50, speedMod = 1.0, staminaMod = 1.0},
        {threshold = 80, speedMod = 0.75, staminaMod = 1.5},
        {threshold = 100, speedMod = 0.5, staminaMod = 2.0, noJump = true},
        {threshold = 101, speedMod = 0.0, cannotMove = true}
    }
}
```

### Testing Criteria
- [ ] Mine carts spawn and physics work correctly
- [ ] Can push cart with realistic movement
- [ ] Rails significantly improve cart speed
- [ ] Load/unload system functions properly
- [ ] Weight penalties apply as configured
- [ ] Team carry requires both players present
- [ ] Vehicles handle differently when loaded
- [ ] Elevators transport between levels correctly
- [ ] No cart/vehicle duplication exploits

### Deliverables
```
free-mining/
├── client/
│   └── transport.lua (NEW)
├── server/
│   └── transport.lua (NEW)
└── config/
    └── transport.lua (NEW)
```

### Key Functions to Implement
- `SpawnMineCart(coords)` - Create cart entity
- `PushCart(player, cart, direction)` - Apply force to cart
- `LoadCart(player, cart, ore)` - Transfer ore to cart
- `UnloadCart(player, cart)` - Empty cart at collection
- `PlaceRail(coords, rotation)` - Install rail segment
- `DetectRail(cartCoords)` - Check if cart on rail
- `LoadVehicle(player, vehicle, ore)` - Transfer to truck
- `ApplyWeightPenalty(player, currentWeight)` - Modify movement
- `TeamCarry(player1, player2, item)` - Shared carrying
- `CallElevator(level)` - Summon elevator cage

---

## PHASE 8: CAVE-IN SYSTEM & HAZARDS

**Objective:** Dynamic danger system with prevention and rescue

**Duration:** 2-3 weeks  
**Complexity:** ⭐⭐⭐⭐⭐

### Features Implemented

#### 33. Cave-In Detection & Triggers

**Monitoring System:**
- Server-side tracking of player activity per zone
- Real-time zone occupancy counter
- Vein extraction volume tracking
- Cumulative risk calculation per area

**Trigger Conditions:**
1. **Prolonged Mining:** 
   - 10+ minutes continuous mining in same 5m radius
   - Risk increases 10% per minute after threshold

2. **Player Density:**
   - 3+ players within 10m radius for 5+ minutes
   - Risk increases 5% per player above 2

3. **Excessive Extraction:**
   - 500+ ore units from single vein without supports
   - Risk increases 2% per 100 units

4. **Structural Weaknesses:**
   - Pre-defined weak zones in cave/mine
   - 2x risk multiplier in weak zones

**Risk Calculation:**
```lua
totalRisk = baseRisk + timeRisk + densityRisk + extractionRisk
if totalRisk > 100 then TriggerCaveIn() end
```

#### 34. Warning System

**Level 1: Early Warning (20-40% risk)**
- Subtle particle effects (dust falling from ceiling)
- Occasional small rock drops (harmless props)
- Faint creaking audio
- No screen effects

**Level 2: Moderate Warning (40-70% risk)**
- Increased dust particles
- Screen shake (light, 1-2 intensity)
- Creaking sounds more frequent and louder
- First notification: "The ground feels unstable..."

**Level 3: Severe Warning (70-90% risk)**
- Heavy dust clouds
- Screen shake (medium, 3-4 intensity)
- Loud cracking/groaning sounds
- Notification: "WARNING: Structural collapse imminent!"
- Small rocks fall and cause minor damage

**Level 4: Imminent Collapse (90-100% risk)**
- Severe screen shake (5+ intensity)
- Emergency siren sound effect
- Countdown notification: "CAVE-IN IN 30 SECONDS!"
- Players can flee if they evacuate immediately

**Progressive Timing:**
- Level 1 → 2: 60 seconds
- Level 2 → 3: 45 seconds
- Level 3 → 4: 30 seconds
- Level 4 → Collapse: 30 seconds
- **Total warning time: ~2.5 minutes**

#### 35. Cave-In Event

**Trigger Sequence:**
1. Final warning notification
2. Intense screen shake + loud rumble audio
3. Camera shake effect
4. Spawn blocking rock props at tunnel entrances
5. Damage players caught in collapse zone
6. Create "trapped zone" boundary

**Event Effects:**
- **Rock spawning:** 5-10 large boulder props block exits
- **Player damage:** 25-50% health to those in zone
- **Lighting failure:** All electrical lights turn off
- **Gas leak:** Toxic gas starts filling area (3 min delay)
- **Dust cloud:** Vision severely reduced for 30 seconds
- **Communication:** Radio static interference

**Trapped Zone:**
- Boundaries defined by rock props
- Cannot leave until rocks cleared
- HUD shows "TRAPPED" status
- Stamina drain increases (+50%)

#### 36. Support Installation System

**Support Types:**

**Wooden Support Beams**
- Craftable: 10x wood planks
- Prevents 1 cave-in
- Installation time: 10 seconds
- Durability: 1 use (destroyed in cave-in)
- Visual: Vertical wooden beam props

**Steel I-Beams**
- Craftable: 5x steel ingots
- Prevents 3 cave-ins
- Installation time: 20 seconds
- Durability: 3 uses (degrades per cave-in)
- Visual: Industrial steel beam props

**Rock Bolts**
- Purchasable: $500 each
- Permanent installation (reduces risk 50%)
- Installation time: 30 seconds
- Visual: Ceiling-mounted anchor points
- No durability (doesn't break)

**Shotcrete Spraying**
- Equipment: Shotcrete sprayer (rental)
- Seals unstable rock faces
- Covers 5m² area per application
- Reduces risk 75% in covered area
- Visual: Concrete coating on walls

**Installation Mechanics:**
- Use ox_target on designated support points
- Progress bar during installation
- Support prop spawns upon completion
- Database tracks supports per zone
- Supports reduce cave-in risk calculation

#### 37. Rescue Mechanics

**From Inside (Self-Rescue):**
- Use pickaxe on blocking rocks
- Progress: 10% per hit (10 hits total)
- Takes 5-10 minutes solo
- Drains stamina heavily
- Tool durability loss

**From Outside (Rescue Crew):**
- Other players can dig from exterior
- Progress: 15% per hit (faster)
- Takes 2-5 minutes with team
- Coordinate via radio communication
- XP reward for rescuers

**Emergency Radio:**
- Trapped players can call for help
- Sends server-wide notification to rescue crews
- Shows GPS location on map
- Creates rescue contract automatically

**Rescue Contracts:**
- Auto-generated when player trapped
- Payment: $1,000 + 500 XP
- Time limit: 30 minutes
- Bonus for fast rescue (<10 minutes)

**Emergency Escape Shafts:**
- Pre-built in some mine sections
- Hidden behind destructible walls
- One-way emergency exits
- Leads to surface/safe zone

### Configuration Additions
```lua
Config.CaveIn = {
    enabled = true,
    
    triggers = {
        prolongedMining = {
            enabled = true,
            timeThreshold = 600, -- seconds (10 min)
            radiusCheck = 5.0, -- meters
            riskPerMinute = 10
        },
        playerDensity = {
            enabled = true,
            maxPlayers = 2,
            radiusCheck = 10.0,
            timeThreshold = 300, -- seconds (5 min)
            riskPerPlayer = 5
        },
        excessiveExtraction = {
            enabled = true,
            quantityThreshold = 500,
            riskPerHundred = 2
        }
    },
    
    warnings = {
        level1 = {threshold = 20, duration = 60},
        level2 = {threshold = 40, duration = 45},
        level3 = {threshold = 70, duration = 30},
        level4 = {threshold = 90, duration = 30}
    },
    
    damage = {
        min = 25,
        max = 50
    },
    
    gasLeak = {
        enabled = true,
        delaySeconds = 180, -- 3 minutes after collapse
        damageRate = 3 -- HP per second
    }
}

Config.Supports = {
    ['wooden_beam'] = {
        preventions = 1,
        installTime = 10000,
        craft = {
            {item = 'wood_plank', amount = 10}
        },
        prop = 'prop_wooden_support'
    },
    ['steel_beam'] = {
        preventions = 3,
        installTime = 20000,
        craft = {
            {item = 'steel_ingot', amount = 5}
        },
        prop = 'prop_steel_beam_01'
    },
    ['rock_bolt'] = {
        riskReduction = 0.5, -- 50%
        installTime = 30000,
        price = 500,
        prop = 'prop_rock_bolt'
    }
}

Config.Rescue = {
    insideDigTime = 600000, -- 10 minutes solo
    outsideDigTime = 300000, -- 5 minutes team
    contractReward = 1000,
    contractXP = 500,
    timeLimit = 1800, -- 30 minutes
    bonusTime = 600 -- bonus if <10 min
}
```

### Testing Criteria
- [ ] Cave-in triggers under correct conditions
- [ ] Warning progression gives adequate time (2.5 min)
- [ ] Rocks spawn and block paths correctly
- [ ] Trapped status prevents escape
- [ ] Supports prevent cave-ins effectively
- [ ] Each support type functions as designed
- [ ] Rescue from inside takes expected time
- [ ] Rescue from outside is faster with team
- [ ] Radio communication works when trapped
- [ ] Rescue contracts auto-generate
- [ ] Gas leaks start after delay
- [ ] No false triggers or performance issues
- [ ] Database logs all cave-in events

### Deliverables
```
free-mining/
├── server/
│   ├── cave_in.lua (NEW)
│   └── rescue.lua (NEW)
├── client/
│   ├── cave_in.lua (NEW)
│   ├── rescue.lua (NEW)
│   └── supports.lua (NEW)
└── config/
    └── cave_in.lua (NEW)
```

### Key Functions to Implement
- `MonitorZoneActivity(zone)` - Track player activity
- `CalculateRisk(zone)` - Compute collapse risk
- `ShowWarning(level)` - Display warning effects
- `TriggerCaveIn(zone)` - Execute collapse event
- `SpawnBlockingRocks(coords)` - Create barriers
- `DamagePlayersInZone(zone)` - Apply collapse damage
- `InstallSupport(player, supportType, coords)` - Place support
- `CheckSupportCoverage(zone)` - Calculate risk reduction
- `StartSelfRescue(player)` - Dig from inside
- `StartExternalRescue(rescuer, trappedPlayer)` - Dig from outside
- `CreateRescueContract(trappedPlayer)` - Generate mission
- `CheckRescueCompletion(contract)` - Validate rescue

---

## PHASE 9: MULTI-ZONE EXPANSION

**Objective:** Expand from single zone to full location suite

**Duration:** 2-3 weeks  
**Complexity:** ⭐⭐⭐⭐☆

### Features Implemented

#### 38. Zone Architecture

**Surface Quarry**
- Open-pit mining environment
- Vehicle-accessible roads and ramps
- Blast zones for explosives
- Conveyor belt systems
- Processing station on-site
- **Ore types:** Copper, Iron, Limestone, Gravel
- **Difficulty:** Easy (low hazards)
- **Access:** Public, no restrictions

**k4mb1 Cave System**
- Natural cave formation (MLO integration)
- Vertical shafts requiring rope descent
- Underground water features
- Natural gas pockets
- Stalactite/stalagmite obstacles
- **Ore types:** Gold, Silver, Emerald, Quartz, Copper
- **Difficulty:** Medium (exploration-focused)
- **Access:** Requires basic equipment

**k4mb1 Mine Shaft**
- Industrial mine tunnels (MLO integration)
- Multi-level elevator access
- Rail cart networks
- Electrical infrastructure
- Deep shaft access (3+ levels)
- **Ore types:** Platinum, Titanium, Diamonds, Rare Earths
- **Difficulty:** Hard (extreme hazards)
- **Access:** Requires advanced equipment + Level 20+

#### 39. Zone-Specific Features

**Quarry Features:**
- Blast zone mechanics:
  - Purchase explosives from supplier
  - Place charges at designated points
  - Clear area before detonation
  - Massive ore yield but loud/visible
- Vehicle operations:
  - Excavators can dig large quantities
  - Dump trucks for bulk transport
  - Fuel consumption tracked
- Open-pit safety:
  - Rockslide hazards on unstable slopes
  - Heat exhaustion in summer
  - Dust storms reduce visibility

**Cave Features:**
- Vertical shaft navigation:
  - Rope/harness system required
  - Fall damage if rope fails
  - Ascend/descend mechanics
- Natural formations:
  - Narrow passages require crouching
  - Underground rivers (swim mechanics)
  - Hidden chambers with rich veins
- Stalactites/stalagmites:
  - Obstacle navigation
  - Can be harvested for calcite

**Mine Shaft Features:**
- Elevator system:
  - Call elevator from any level
  - 4 levels: Surface, L1, L2, L3
  - Deeper = better ores
  - Power outages trap players
- Electrical infrastructure:
  - Powered sections have lighting
  - Unpowered sections pitch black
  - Restore power via generator repairs
- Rail networks:
  - Pre-installed rails on main routes
  - Cart travel between levels
  - Maintenance required periodically

#### 40. Difficulty Scaling

| Aspect | Quarry | Cave | Mine Shaft |
|--------|--------|------|------------|
| Ore Value | Low-Med | Medium-High | High-Extreme |
| Hazard Level | Low | Medium | High |
| Cave-In Risk | Low (10%) | Medium (30%) | High (50%) |
| Gas Hazards | Rare | Common | Constant |
| Equipment Required | Basic | Intermediate | Advanced |
| Level Requirement | None | 5+ | 20+ |
| Light Needed | No | Yes | Critical |
| Temperature | Variable | Cool | Hot |

#### 41. Atmospheric Hazard Expansion

**Methane (CH₄) - Explosive Gas**
- Found in old mine sections
- Detector beeps rapidly
- **Effects:**
  - Explosive near open flames
  - Helmet light can trigger explosion
  - Requires flame-safe LED lights
- **Protection:** Ventilation system or evacuation

**Hydrogen Sulfide (H₂S) - Toxic Gas**
- Found in deep caves near water
- Distinct rotten egg smell (audio cue)
- **Effects:**
  - Rapid health drain (5 HP/sec)
  - Vision blur and disorientation
  - Unconsciousness after 30 sec exposure
- **Protection:** SCBA or advanced respirator

**Radon (Rn) - Radioactive Gas**
- Found in deepest mine levels
- Geiger counter detection
- **Effects:**
  - Slow radiation accumulation
  - Long-term health degradation
  - Requires medical treatment
- **Protection:** SCBA with radiation filter

**Carbon Dioxide (CO₂) - Asphyxiant**
- Common in poorly ventilated areas
- **Effects:**
  - Drowsiness and confusion
  - Stamina drain increase
  - Eventual unconsciousness
- **Protection:** Basic respirator sufficient

**SCBA System (Self-Contained Breathing Apparatus):**
- 100% protection from all gases
- Limited air supply (30 minutes)
- Refillable at surface stations
- Heavy (reduces movement speed 20%)
- Expensive ($5,000)

#### 42. Environmental Effects

**Temperature System:**
- Surface quarry: Ambient temperature
- Caves: Cool (10-15°C)
- Mine shaft levels:
  - L1: Warm (25°C)
  - L2: Hot (35°C)
  - L3: Extreme (45°C)
- **Heat effects:**
  - Increased stamina drain
  - Hydration requirement
  - Heat stroke at extreme temps
- **Cooling:** Water bottles, rest in shade

**Flooding:**
- Lower cave sections periodically flood
- Rain causes temporary water rise
- Swim mechanics required
- Ore becomes inaccessible until water recedes
- Water damage to electrical equipment

**Lighting Zones:**
- Powered sections: Full visibility
- Unpowered sections: Pitch black
- Emergency lights: Dim, limited range
- Player lights essential in dark zones

### Configuration Additions
```lua
Config.Zones = {
    quarry = {
        enabled = true,
        center = vector3(2832.0, 2770.0, 43.0),
        radius = 150.0,
        difficulty = 'easy',
        levelRequired = 0,
        ores = {
            {type = 'copper', rarity = 40},
            {type = 'iron', rarity = 35},
            {type = 'limestone', rarity = 20},
            {type = 'gravel', rarity = 5}
        },
        features = {
            blasting = true,
            vehicles = true,
            conveyors = true
        },
        hazards = {
            caveInRisk = 0.1,
            gasZones = {},
            temperature = 'ambient'
        }
    },
    
    cave = {
        enabled = true,
        entrances = {
            vector3(0, 0, 0) -- k4mb1 cave entrance
        },
        difficulty = 'medium',
        levelRequired = 5,
        ores = {
            {type = 'gold', rarity = 30},
            {type = 'silver', rarity = 25},
            {type = 'emerald', rarity = 15},
            {type = 'quartz', rarity = 20},
            {type = 'copper', rarity = 10}
        },
        features = {
            verticalShafts = true,
            undergroundRivers = true,
            hiddenChambers = true
        },
        hazards = {
            caveInRisk = 0.3,
            gasZones = {
                {type = 'co2', coords = vector3(0,0,0), radius = 15},
                {type = 'h2s', coords = vector3(0,0,0), radius = 10}
            },
            temperature = 'cool'
        }
    },
    
    mine_shaft = {
        enabled = true,
        entrance = vector3(0, 0, 0), -- k4mb1 mine entrance
        difficulty = 'hard',
        levelRequired = 20,
        levels = {
            {name = 'Surface', z = 100, ores = {}},
            {name = 'Level 1', z = 50, ores = {'platinum', 'gold'}},
            {name = 'Level 2', z = 0, ores = {'titanium', 'platinum'}},
            {name = 'Level 3', z = -50, ores = {'diamonds', 'rare_earth'}}
        },
        features = {
            elevators = true,
            railNetwork = true,
            electricalGrid = true
        },
        hazards = {
            caveInRisk = 0.5,
            gasZones = {
                {type = 'methane', level = 1},
                {type = 'radon', level = 3}
            },
            temperature = 'extreme'
        }
    }
}

Config.Gases = {
    ['methane'] = {
        color = 'yellow',
        explosive = true,
        damageRate = 0,
        detectorSound = 'beep_fast',
        protection = {'ventilation'}
    },
    ['h2s'] = {
        color = 'green',
        explosive = false,
        damageRate = 5,
        detectorSound = 'alarm_continuous',
        protection = {'respirator_advanced', 'scba'}
    },
    ['radon'] = {
        color = 'purple',
        explosive = false,
        damageRate = 1, -- radiation
        detectorSound = 'geiger_counter',
        protection = {'scba_radiation'}
    },
    ['co2'] = {
        color = 'gray',
        explosive = false,
        damageRate = 2,
        detectorSound = 'beep_slow',
        protection = {'respirator', 'scba'}
    }
}

Config.SCBA = {
    item = 'scba_system',
    airCapacity = 1800, -- seconds (30 min)
    refillTime = 60, -- seconds
    movementPenalty = 0.8, -- 20% slower
    price = 5000
}
```

### Testing Criteria
- [ ] All three zones operational independently
- [ ] Zone-specific ores spawn correctly
- [ ] Difficulty progression feels balanced
- [ ] Gas types behave distinctly
- [ ] Methane explodes near flames
- [ ] H2S causes rapid health loss
- [ ] Radon accumulates over time
- [ ] SCBA provides full protection
- [ ] Temperature affects stamina/hydration
- [ ] Flooding mechanics work in caves
- [ ] Lighting zones function properly
- [ ] Elevator system transports between levels
- [ ] Level requirements enforced
- [ ] Can transition between zones seamlessly
- [ ] Performance stable with all zones active

### Deliverables
```
free-mining/
├── config/
│   ├── zones/
│   │   ├── quarry.lua (NEW)
│   │   ├── cave.lua (NEW)
│   │   └── mine_shaft.lua (NEW)
│   └── hazards.lua (UPDATED)
├── client/
│   ├── zones.lua (NEW)
│   └── hazards.lua (UPDATED)
└── server/
    └── zones.lua (NEW)
```

### Key Functions to Implement
- `LoadZone(zoneName)` - Initialize zone data
- `CheckZoneAccess(player, zone)` - Validate level requirement
- `DetectGasType(coords)` - Identify gas in area
- `ApplyGasEffects(player, gasType)` - Gas-specific damage
- `ExplodeMethane(coords)` - Trigger methane explosion
- `CheckTemperature(zone, level)` - Get current temp
- `ApplyHeatEffects(player, temp)` - Heat exhaustion
- `OperateElevator(player, targetLevel)` - Move between floors
- `CheckPowerStatus(zone)` - Electrical grid state
- `RestorePower(player, generator)` - Repair electrical
- `CheckFloodStatus(zone)` - Water level state

---

## PHASE 10: NUI, CONTRACTS & PROGRESSION

**Objective:** Player interface, missions, and advancement systems

**Duration:** 3-4 weeks  
**Complexity:** ⭐⭐⭐⭐⭐

### Features Implemented

#### 43. Mining NUI Dashboard

**Main Interface Structure:**
```
┌─────────────────────────────────────────────┐
│  FREE-MINING                           [X]  │
├─────────────────────────────────────────────┤
│ [Dashboard] [Contracts] [Stats] [Board]    │
│ [Claims] [Market] [Equipment] [Map]        │
├─────────────────────────────────────────────┤
│                                             │
│  [CONTENT AREA - DYNAMIC]                   │
│                                             │
│                                             │
│                                             │
└─────────────────────────────────────────────┘
```

**Tab 1: Dashboard**
- Quick stats overview
- Active contracts summary
- Earnings today/week/month
- Current level and XP progress bar
- Quick access to frequent actions

**Tab 2: Contracts**
- Available contracts (5-10 at a time)
- Active contracts with progress tracking
- Contract details (requirements, rewards, time limit)
- Accept/Abandon buttons
- Filter by type (daily, weekly, special)

**Tab 3: Statistics**
- Personal mining records:
  - Total ore mined (by type)
  - Hours worked underground
  - Distance traveled in mines
  - Veins discovered
  - Cave-ins survived
  - Rescues performed
  - Total earnings
- Graphs showing trends over time
- Achievements/milestones

**Tab 4: Leaderboards**
- Multiple leaderboard categories:
  - Top miners (total ore)
  - Top earners (profit)
  - Most discoveries
  - Fastest smelters
  - Most rescues
- Time filters: daily, weekly, monthly, all-time
- Your rank highlighted

**Tab 5: Claims**
- List of your active claims
- Claim details (ore type, expiration, production)
- Renew/transfer options
- Navigate to claim location
- Claim profitability statistics

**Tab 6: Market**
- Current ore prices (live updates)
- Price history graphs
- Supply/demand indicators
- Buy orders from NPCs/businesses
- Quick sell interface

**Tab 7: Equipment**
- Tool durability overview
- Battery levels for powered equipment
- Maintenance alerts
- Quick repair/charge buttons
- Equipment upgrade shop

**Tab 8: Map**
- Interactive map of mining zones
- Discovered vein markers
- Claim locations
- Hazard zones marked
- GPS navigation to selected point

#### 44. Contract System

**Contract Types:**

**Daily Missions (Refreshes at midnight)**
- Extract X amount of specific ore
- Discover new veins in zone Y
- Mine without cave-in for X minutes
- Rewards: $500-2000, 100-500 XP

**Weekly Contracts (Refreshes Monday)**
- Supply X tons to industrial buyers
- Complete Y daily missions
- Reach mining level Z
- Rewards: $5000-15000, 1000-3000 XP

**Rush Orders (Time-limited)**
- High pay, strict time limits
- Specific quality requirements
- Premium ore types
- Rewards: $10000+, 2000+ XP
- Expires in: 1-6 hours

**Exploration Bounties**
- Discover veins in specific zones
- Find rare ore types
- Map X square meters of caves
- Rewards: $3000-8000, 500-1500 XP

**Rescue Contracts (Auto-generated)**
- Help recover trapped miners
- Time-sensitive (30 min)
- Location provided on map
- Rewards: $1000-3000, 500-1000 XP

**Infrastructure Jobs**
- Install X support beams
- Clear cave-in debris
- Repair equipment
- Restore power to mine section
- Rewards: $2000-5000, 300-800 XP

**NPC Contract Givers:**
- Mining Office Clerk (Surface)
- Foreman (Quarry)
- Cave Guide (Cave entrance)
- Mine Superintendent (Mine shaft)

#### 45. Progression System

**Experience Points:**
- Mining ore: 10 XP per extraction
- Discovering veins: 100 XP per discovery
- Completing contracts: Variable (100-3000 XP)
- Rescuing players: 500 XP per rescue
- Installing supports: 50 XP per support
- Smelting ore: 5 XP per ingot

**Level System (1-50):**
- XP required scales exponentially
- Formula: `XP = 100 * (level^1.5)`
- Example:
  - Level 2: 283 XP
  - Level 10: 3,162 XP
  - Level 20: 17,889 XP
  - Level 50: 176,777 XP

**Level Unlocks:**
| Level | Unlock |
|-------|--------|
| 1 | Basic pickaxe, quarry access |
| 5 | Cave access, metal detector |
| 10 | Steel tools, claim staking |
| 15 | Rock drill, GPR scanner |
| 20 | Mine shaft access, seismic kit |
| 25 | Precision drill, advanced contracts |
| 30 | Diamond drill, specialization choice |
| 40 | Explosives license, elite contracts |
| 50 | Master miner title, all features |

**Specialization Paths (Choose at Level 30):**

**Prospector:**
- Survey equipment range +50%
- Vein discovery XP +25%
- Metal detector battery drain -30%
- Survey reports sell for 2x price

**Excavator:**
- Mining speed +20%
- Ore yield +15%
- Tool durability +25%
- Critical hit chance (double ore)

**Engineer:**
- Support installation time -40%
- Cave-in risk reduction +30%
- Repair efficiency +50%
- Infrastructure contracts pay +25%

**Smelter:**
- Smelting speed +30%
- Rare material unlock (alloys)
- Processing yield +10%
- Market price bonus +5%

*Can reset specialization for $50,000*

#### 46. Statistics Tracking

**Server-Side Database:**
```sql
CREATE TABLE IF NOT EXISTS `mining_player_stats` (
    `player_id` VARCHAR(50) PRIMARY KEY,
    `total_ore_mined` INT DEFAULT 0,
    `ore_by_type` JSON, -- {"copper": 1234, "gold": 567}
    `hours_worked` INT DEFAULT 0,
    `distance_traveled` INT DEFAULT 0,
    `veins_discovered` INT DEFAULT 0,
    `cave_ins_survived` INT DEFAULT 0,
    `rescues_performed` INT DEFAULT 0,
    `total_earnings` INT DEFAULT 0,
    `contracts_completed` INT DEFAULT 0,
    `specialization` VARCHAR(20) DEFAULT NULL,
    `achievements` JSON,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Tracked Statistics:**
- Total ore mined (aggregate)
- Ore mined by type (breakdown)
- Hours worked (session time in mines)
- Distance traveled (meters walked underground)
- Veins discovered (unique finds)
- Cave-ins survived (trapped events)
- Rescues performed (helped others)
- Total earnings (lifetime profit)
- Contracts completed (all types)
- Highest quality ore found
- Biggest single haul
- Fastest smelting time

#### 47. Leaderboard System

**Leaderboard Categories:**

**Top Miners (Total Ore)**
```sql
SELECT player_id, total_ore_mined 
FROM mining_player_stats 
ORDER BY total_ore_mined DESC 
LIMIT 10;
```

**Top Earners (Profit)**
```sql
SELECT player_id, total_earnings 
FROM mining_player_stats 
ORDER BY total_earnings DESC 
LIMIT 10;
```

**Most Discoveries**
```sql
SELECT player_id, veins_discovered 
FROM mining_player_stats 
ORDER BY veins_discovered DESC 
LIMIT 10;
```

**Most Rescues**
```sql
SELECT player_id, rescues_performed 
FROM mining_player_stats 
ORDER BY rescues_performed DESC 
LIMIT 10;
```

**Time Periods:**
- Daily (resets at midnight)
- Weekly (resets Monday)
- Monthly (resets 1st of month)
- All-Time (permanent records)

**Rewards for Top Rankings:**
- #1: 5000 XP + $10,000 bonus
- #2: 3000 XP + $5,000 bonus
- #3: 2000 XP + $3,000 bonus
- #4-10: 1000 XP + $1,000 bonus

### Configuration Additions
```lua
Config.Progression = {
    maxLevel = 50,
    xpFormula = function(level)
        return math.floor(100 * (level ^ 1.5))
    end,
    
    xpRewards = {
        mining = 10,
        discovery = 100,
        rescue = 500,
        support = 50,
        smelting = 5
    },
    
    levelUnlocks = {
        [5] = {'cave_access', 'metal_detector'},
        [10] = {'steel_tools', 'claim_staking'},
        [15] = {'rock_drill', 'gpr_scanner'},
        [20] = {'mine_shaft_access', 'seismic_kit'},
        [30] = {'specialization_choice'},
        [50] = {'master_miner_title'}
    }
}

Config.Specializations = {
    prospector = {
        surveyRangeBonus = 1.5,
        discoveryXPBonus = 1.25,
        batteryDrainReduction = 0.7,
        reportValueMultiplier = 2.0
    },
    excavator = {
        miningSpeedBonus = 1.2,
        oreYieldBonus = 1.15,
        toolDurabilityBonus = 1.25,
        criticalHitChance = 0.1
    },
    engineer = {
        installTimeReduction = 0.6,
        caveInReduction = 0.7,
        repairEfficiency = 1.5,
        contractPayBonus = 1.25
    },
    smelter = {
        smeltingSpeedBonus = 1.3,
        processingYieldBonus = 1.1,
        priceBonus = 1.05
    }
}

Config.Contracts = {
    dailyRefreshTime = '00:00',
    weeklyRefreshDay = 'monday',
    maxActiveContracts = 5,
    
    types = {
        daily = {
            count = 3,
            rewardRange = {500, 2000},
            xpRange = {100, 500}
        },
        weekly = {
            count = 2,
            rewardRange = {5000, 15000},
            xpRange = {1000, 3000}
        },
        rush = {
            duration = 21600, -- 6 hours
            rewardRange = {10000, 25000},
            xpRange = {2000, 5000}
        }
    }
}
```

### Testing Criteria
- [ ] NUI opens and all tabs functional
- [ ] Contracts appear and track progress correctly
- [ ] XP awards properly, levels advance
- [ ] Level unlocks grant features/access
- [ ] Specializations provide bonuses as configured
- [ ] Statistics update in real-time
- [ ] Leaderboards rank accurately
- [ ] UI is responsive and intuitive
- [ ] No NUI callback errors
- [ ] Database queries optimized (<10ms)
- [ ] Contract generation balanced
- [ ] Progression feels rewarding

### Deliverables
```
free-mining/
├── html/
│   ├── index.html (NEW)
│   ├── style.css (NEW)
│   ├── script.js (NEW)
│   ├── tabs/
│   │   ├── dashboard.html (NEW)
│   │   ├── contracts.html (NEW)
│   │   ├── stats.html (NEW)
│   │   ├── leaderboard.html (NEW)
│   │   ├── claims.html (NEW)
│   │   ├── market.html (NEW)
│   │   ├── equipment.html (NEW)
│   │   └── map.html (NEW)
│   └── assets/
│       ├── icons/
│       └── images/
├── client/
│   └── ui/
│       └── nui.lua (NEW)
├── server/
│   ├── contracts.lua (NEW)
│   ├── progression.lua (NEW)
│   └── leaderboards.lua (NEW)
└── sql/
    └── progression.sql (NEW)
```

### Key Functions to Implement
- `OpenMiningUI()` - Display NUI
- `LoadTabContent(tabName)` - Fetch tab data
- `GetAvailableContracts()` - Retrieve contract list
- `AcceptContract(contractId)` - Start contract
- `UpdateContractProgress(contractId, progress)` - Track completion
- `AwardXP(player, amount)` - Grant experience
- `CheckLevelUp(player)` - Process level advancement
- `UnlockFeature(player, feature)` - Grant level reward
- `ChooseSpecialization(player, spec)` - Set specialization
- `ApplySpecBonus(player, action)` - Calculate bonus
- `UpdateStatistic(player, stat, value)` - Increment stat
- `GetLeaderboard(category, period)` - Fetch rankings
- `AwardLeaderboardPrizes()` - Distribute rewards

---

## PHASE 11: PROCESSING & ECONOMY CHAIN

**Objective:** Complete ore-to-product manufacturing pipeline

**Duration:** 2-3 weeks  
**Complexity:** ⭐⭐⭐⭐☆

### Features Implemented

#### 48. Crushing & Sorting

**Crusher Station:**
- Located at processing facility
- Load raw ore (up to 100 chunks at once)
- Crushing progress bar (30 seconds per 10 chunks)
- Output: crushed ore (smaller particles)
- Noise generation (alerts nearby players/police)

**Sorting Table:**
- Separate ore from waste rock
- Manual or automated sorting
- **Manual:** Player selects ore pieces (minigame)
- **Automated:** Conveyor belt system (requires power)
- Waste rock output:
  - Can be used for support beams
  - Sold as fill material
  - Dumped in waste pile

**Equipment:**
- Rock crusher machine (purchasable, $25,000)
- Sorting conveyor (purchasable, $15,000)
- Requires electrical power supply
- Maintenance every 500 uses

#### 49. Smelting Expansion

**Temperature Management Minigame:**
- Target temperature range for each ore type
- Fuel controls heat level
- Too hot = ore burns (loss)
- Too cold = incomplete smelting
- Perfect temp = maximum yield

**Fuel Requirements:**
| Fuel Type | Heat Output | Burn Time | Cost |
|-----------|-------------|-----------|------|
| Coal | Medium | 10 min | $5 |
| Charcoal | Medium-High | 8 min | $8 |
| Propane | High | 15 min | $12 |
| Natural Gas | Very High | 20 min | $20 |

**Smelting Process:**
1. Load ore into furnace (batch: 1-10 chunks)
2. Add fuel
3. Ignite furnace
4. Manage temperature (adjust fuel/airflow)
5. Wait for completion (5-15 min real-time)
6. Collect ingots

**Quality Impact:**
- Ore quality affects output quantity
- Perfect smelting adds +10% bonus
- Burnt ore reduces output by 50%

#### 50. Refining System (k4mb1 Foundry Integration)

**Foundry Location:**
- Dedicated building (k4mb1 map or custom)
- Industrial equipment setup
- Multiple workstations

**Purification Process:**
- Further refine ingots to increase purity
- Remove impurities and slag
- Output: refined ingots (higher value)
- Process time: 10 minutes per batch

**Alloy Creation Recipes:**

**Bronze:**
- Copper ingot (3) + Tin ingot (1)
- Output: Bronze ingot (4)
- Uses: Decorative items, statues

**Steel:**
- Iron ingot (5) + Carbon (1)
- Output: Steel ingot (5)
- Uses: Construction, tools

**Stainless Steel:**
- Steel ingot (4) + Chromium (1)
- Output: Stainless steel ingot (4)
- Uses: High-end products

**Titanium Alloy:**
- Titanium ingot (3) + Aluminum (1)
- Output: Titanium alloy ingot (3)
- Uses: Aerospace, medical

**Casting Process:**
- Pour molten metal into molds
- Shape options:
  - Ingots (standard)
  - Sheets (flat plates)
  - Rods (cylindrical)
  - Wire (thin strands)
- Shape affects use cases and value

**Quality Control Testing:**
- Test ingot purity
- Increases market value by 10-20%
- Requires testing equipment
- Certification adds prestige

#### 51. Market Dynamics

**Dynamic Pricing System:**
- Base prices set in config
- Fluctuates based on server supply
- Formula: `price = basePrice * (1 - (supply / maxSupply))`
- Updates every 30 minutes

**Price Factors:**
- Total ore sold (supply)
- Active miners online (production)
- Contract demands (demand spikes)
- Special events (double price weekends)

**High-Demand Events:**
- Construction boom (steel/concrete demand)
- Jewelry event (gold/silver/gems)
- Tech expo (copper/silicon/rare earths)
- War effort (titanium/steel/explosives)

**Price Alerts:**
- Phone notification when price spikes >20%
- Email alerts for specific ore types
- Market trend graphs in NUI

**Bulk Sale Bonuses:**
- Sell 50+ ingots = +5% bonus
- Sell 100+ ingots = +10% bonus
- Sell 500+ ingots = +15% bonus

#### 52. Manufacturing Integration

**Export API for External Scripts:**
```lua
-- Check material availability
exports['free-mining']:HasMaterial(itemName, amount)

-- Request material (deducts from player)
exports['free-mining']:RequestMaterial(source, itemName, amount)

-- Get current market price
exports['free-mining']:GetMarketPrice(itemName)

-- Register bulk buyer
exports['free-mining']:RegisterBuyer(buyerData)
```

**Crafting Integration Examples:**

**Jewelry Script:**
- Gold ingot → Gold ring, Gold necklace
- Silver ingot → Silver bracelet
- Platinum ingot → Platinum watch
- Emerald/Diamond → Gem setting

**Body Shop Script:**
- Steel ingot → Body panels, Roll cage
- Aluminum ingot → Lightweight body parts
- Titanium ingot → Performance parts

**Tool/Weapon Scripts:**
- Iron ingot → Basic tools
- Steel ingot → Advanced tools, Weapons
- Titanium ingot → High-end equipment

**Electronics/Tech Scripts:**
- Copper ingot → Wiring, Circuit boards
- Silicon → Computer chips
- Rare earth elements → Advanced electronics

**Construction Scripts:**
- Concrete (limestone processed) → Building materials
- Rebar (iron rods) → Structural support
- Structural steel → Building frames

**Wholesale Buyers (NPCs):**
- Construction Company (bulk steel/concrete)
- Jewelry Store (precious metals/gems)
- Auto Factory (aluminum/steel/titanium)
- Tech Manufacturer (copper/silicon/rare earths)
- Government (contracts for infrastructure)

**Purchase Orders:**
- Businesses place standing orders
- Automated purchasing at market rate
- Volume discounts for consistent supply
- Reputation system (reliable supplier bonus)

### Configuration Additions
```lua
Config.Processing = {
    crusher = {
        batchSize = 10,
        processingTime = 30000, -- 30 sec
        wastePercentage = 0.15, -- 15% waste rock
        maintenanceCost = 500,
        maintenanceInterval = 500 -- uses
    },
    
    furnace = {
        batchSize = 10,
        temperatures = {
            copper = {min = 1000, max = 1100},
            iron = {min = 1200, max = 1300},
            gold = {min = 1050, max = 1150},
            platinum = {min = 1500, max = 1600}
        },
        burnPenalty = 0.5, -- 50% loss if overheated
        bonusForPerfect = 0.1 -- 10% bonus
    }
}

Config.Alloys = {
    bronze = {
        recipe = {
            {item = 'copper_ingot', amount = 3},
            {item = 'tin_ingot', amount = 1}
        },
        output = {item = 'bronze_ingot', amount = 4},
        time = 600000 -- 10 min
    },
    steel = {
        recipe = {
            {item = 'iron_ingot', amount = 5},
            {item = 'carbon', amount = 1}
        },
        output = {item = 'steel_ingot', amount = 5},
        time = 600000
    },
    stainless_steel = {
        recipe = {
            {item = 'steel_ingot', amount = 4},
            {item = 'chromium', amount = 1}
        },
        output = {item = 'stainless_ingot', amount = 4},
        time = 900000 -- 15 min
    }
}

Config.Market = {
    updateInterval = 1800, -- 30 minutes
    
    basePrices = {
        copper_ingot = 50,
        iron_ingot = 75,
        gold_ingot = 200,
        silver_ingot = 150,
        platinum_ingot = 500,
        diamond = 1000
    },
    
    supplyImpact = {
        maxSupply = 10000, -- per ore type
        priceFloor = 0.5, -- min 50% of base price
        priceCeiling = 2.0 -- max 200% of base price
    },
    
    bulkBonuses = {
        {threshold = 50, bonus = 1.05},
        {threshold = 100, bonus = 1.10},
        {threshold = 500, bonus = 1.15}
    }
}

Config.Buyers = {
    construction = {
        name = 'Ironworks Construction',
        buyItems = {'steel_ingot', 'concrete', 'rebar'},
        priceMultiplier = 0.95, -- 95% of market
        volume = 'high', -- buys large quantities
        reputation = true -- affects future pricing
    },
    jewelry = {
        name = 'Vangelico Jewelers',
        buyItems = {'gold_ingot', 'silver_ingot', 'platinum_ingot', 'diamond', 'emerald'},
        priceMultiplier = 1.05, -- 105% of market
        volume = 'medium',
        reputation = true
    }
}
```

### Testing Criteria
- [ ] Crusher processes ore correctly
- [ ] Sorting separates ore from waste
- [ ] Temperature minigame affects yield
- [ ] Fuel types have different heat outputs
- [ ] Burning ore causes loss
- [ ] Perfect smelting gives bonus
- [ ] Alloy recipes work correctly
- [ ] Casting shapes available
- [ ] Market prices fluctuate realistically
- [ ] Bulk bonuses apply correctly
- [ ] Export API functions for external scripts
- [ ] Wholesale buyers purchase automatically
- [ ] No economic exploits (duping, infinite money)

### Deliverables
```
free-mining/
├── server/
│   ├── processing.lua (UPDATED)
│   ├── refining.lua (NEW)
│   └── market.lua (NEW)
├── client/
│   ├── processing.lua (NEW)
│   └── refining.lua (NEW)
├── shared/
│   └── exports.lua (NEW)
└── config/
    ├── processing.lua (NEW)
    └── market.lua (NEW)
```

### Key Functions to Implement
- `CrushOre(player, oreType, amount)` - Process raw ore
- `SortOre(player, crushedOre)` - Separate ore/waste
- `LoadFurnace(player, ore, fuel)` - Start smelting
- `ManageTemperature(player, furnaceId)` - Control heat
- `CheckSmeltCompletion(furnaceId)` - Finalize smelting
- `CreateAlloy(player, recipe)` - Combine ingots
- `CastIngot(player, metal, shape)` - Shape molten metal
- `TestQuality(player, ingotId)` - Quality control
- `UpdateMarketPrices()` - Recalculate prices
- `SellToMarket(player, item, amount)` - Sell ingots
- `CalculateBulkBonus(amount)` - Apply discount
- `ProcessWholesaleOrder(buyer, order)` - Auto-purchase

---

## PHASE 12: POLISH, OPTIMIZATION & BALANCE

**Objective:** Performance optimization, exploit fixes, balance tuning

**Duration:** 2-3 weeks  
**Complexity:** ⭐⭐⭐⭐☆

### Features Implemented

#### 53. Performance Optimization

**Database Optimization:**
- Add indexes on frequently queried columns
- Optimize JOIN queries
- Implement result caching (5 min TTL)
- Batch database updates (every 60 seconds)
- Connection pooling
- Query performance monitoring

**Vein Generation:**
- Move generation to async thread
- Cache vein data in memory
- Only load active zone veins
- Lazy load vein details on demand
- Cleanup depleted veins nightly

**Prop Management:**
- Limit max spawned props per zone (100)
- Auto-despawn props after 30 min inactivity
- Optimize prop render distance
- Use lower-poly models where appropriate
- Implement prop pooling/recycling

**Gas Zone Detection:**
- Zone-based checking vs. constant checks
- Only check when player in mining area
- Reduce check frequency (every 2 seconds)
- Spatial hashing for efficient lookups

**Light System:**
- LOD (Level of Detail) for distant players
- Reduce light update frequency
- Optimize shadow calculations
- Disable lights outside player view

**NUI Performance:**
- Lazy load tab content
- Virtualized lists for large datasets
- Debounce search inputs
- Minimize DOM manipulations
- Use CSS animations over JS

**Network Optimization:**
- Compress large data packets
- Batch event triggers
- Reduce update frequency for non-critical data
- Client-side prediction for mining actions

#### 54. Anti-Exploit Systems

**Server-Side Validation:**
```lua
-- Validate every action server-side
function ValidateMining(player, veinId, toolItem)
    -- Check player proximity to vein
    if #(GetPlayerCoords(player) - vein.coords) > 5.0 then
        return false, "Too far from vein"
    end
    
    -- Check tool in inventory
    if not HasItem(player, toolItem) then
        return false, "Tool not found"
    end
    
    -- Check vein not depleted
    if vein.remaining_quantity <= 0 then
        return false, "Vein depleted"
    end
    
    -- Check claim ownership
    if vein.claimed and vein.owner ~= player then
        return false, "Not your claim"
    end
    
    return true
end
```

**Cooldown System:**
- Mining cooldown: 500ms between extractions
- Claim staking cooldown: 10 seconds
- Contract acceptance cooldown: 5 seconds
- Prevents spam/automation

**Sanity Checks:**
- Ore quantity per extraction (max 10)
- Tool durability cannot be negative
- Battery percentage 0-100%
- Weight cannot exceed 10,000kg
- XP gains capped at 10,000 per action

**Teleportation Detection:**
- Track last known position
- Flag large distance changes (<1 second)
- Auto-kick on repeated violations
- Log suspicious activity

**Item Duplication Prevention:**
- Transaction IDs for all item transfers
- Database transaction rollback on failure
- Lock inventory during processing
- Validate item existence before transfer

**Cave-In Bypass Detection:**
- Verify player inside trapped zone
- Check rock prop existence
- Flag instant escapes
- Require minimum dig time

#### 55. Balance Tuning

**Ore Spawn Rates:**
- Test with player feedback
- Adjust rarity percentages
- Balance zone difficulty vs. reward
- Ensure rare ores feel special

**Tool Durability vs. Cost:**
- Cost should match durability value
- Repair kits priced appropriately
- High-tier tools worth investment
- Consumables feel fair

**Risk vs. Reward:**
- Quarry: Safe, moderate profit ($50-100/hr)
- Cave: Risky, good profit ($150-300/hr)
- Mine Shaft: Extreme risk, high profit ($400-800/hr)
- Adjust based on actual player earnings

**Contract Rewards:**
- Daily missions: $500-2000 (10-15 min effort)
- Weekly contracts: $5000-15000 (2-3 hours)
- Rush orders: $10000+ (1 hour, high difficulty)
- Balance XP rewards proportionally

**Market Prices:**
- Baseline profitability target
- Prevent economic inflation
- Rare ores significantly more valuable
- Processed materials worth effort

**XP Curve:**
- Early levels fast (1-10: 2-3 hours)
- Mid levels moderate (11-30: 10-20 hours)
- Late levels slow (31-50: 40-80 hours)
- Total time to max: 100-150 hours

#### 56. Quality of Life

**Keybind Customization:**
- Configurable keybinds in settings
- Default bindings provided
- Save preferences per character
- Reset to defaults option

**Audio Settings:**
- Master volume control
- Separate sliders:
  - Mining sounds
  - Gas alarms
  - Cave-in warnings
  - Background ambience
- Mute option for each category

**Visual Settings:**
- Light brightness adjustment
- Particle density (low/medium/high)
- Screen shake intensity
- HUD opacity
- Colorblind modes

**Accessibility:**
- Text size options
- High contrast mode
- Audio cues for visual alerts
- Simplified controls option
- Subtitles for audio cues

**Tutorial System:**
- First-time player guide
- Step-by-step instructions
- Interactive tooltips
- Can be replayed anytime
- Skip option for experienced players

**Contextual Help:**
- Hover tooltips on UI elements
- Help icons with detailed info
- FAQ section in NUI
- Video guides (if available)

#### 57. Admin Tools

**Admin Menu (NUI):**
```
┌─────────────────────────────────────┐
│ FREE-MINING ADMIN PANEL             │
├─────────────────────────────────────┤
│ [Vein Mgmt] [Players] [Economy]    │
│ [Events] [Settings] [Logs]         │
├─────────────────────────────────────┤
│ [Spawn Vein] [Remove Vein]         │
│ [Trigger Cave-In] [Clear Cave-In]  │
│ [Set Prices] [Reset Player]        │
│ [View Stats] [Export Data]         │
└─────────────────────────────────────┘
```

**Admin Commands:**
- `/mining spawn [ore] [quality]` - Spawn vein
- `/mining remove [veinId]` - Delete vein
- `/mining cavein [zone]` - Force cave-in
- `/mining clear [zone]` - Clear cave-in
- `/mining setprice [ore] [price]` - Override price
- `/mining reset [player]` - Reset progression
- `/mining give [player] [item] [amount]` - Give items
- `/mining stats [player]` - View player stats

**Debug Mode:**
- Toggle with `/mining debug`
- Shows vein locations on map
- Displays zone boundaries
- Prints gas zone info
- Logs all actions to console
- Performance metrics overlay

**Logging System:**
- Log all critical events:
  - Vein discoveries
  - Cave-ins
  - Large transactions (>$10,000)
  - Contract completions
  - Admin actions
- Export logs to file
- Discord webhook integration (optional)

#### 58. Documentation

**Player Guide (README.md):**
```markdown
# FREE-MINING - Player Guide

## Getting Started
1. Purchase basic pickaxe from mining office
2. Travel to quarry (marked on map)
3. Find indicator rocks
4. Mine ore with pickaxe
5. Sell at processing facility

## Mining Zones
- Quarry: Beginner-friendly, basic ores
- Cave System: Intermediate, richer ores
- Mine Shaft: Advanced, rare ores

## Equipment
- Tools: Pickaxe, Drill, Explosives
- Safety: Helmet, Respirator, SCBA
- Survey: Metal Detector, GPR, Seismic Kit

## [Full guide continues...]
```

**Admin Setup Guide (INSTALL.md):**
```markdown
# FREE-MINING - Installation Guide

## Requirements
- QBX Framework
- ox_lib
- ox_inventory
- ox_target
- MySQL/MariaDB

## Installation Steps
1. Download release
2. Extract to resources folder
3. Import SQL file
4. Configure config.lua
5. Start resource

## [Full setup continues...]
```

**Configuration Guide (CONFIG.md):**
```markdown
# FREE-MINING - Configuration

## Ore Configuration
Each ore can be customized:
- spawn rate
- quality range
- mining time
- sell price

## [Full config docs...]
```

**Troubleshooting (FAQ.md):**
```markdown
# FREE-MINING - FAQ

## Q: Veins not spawning?
A: Check database connection and restart resource

## Q: Cave-ins too frequent?
A: Adjust risk multipliers in config

## [Full FAQ continues...]
```

**API Documentation (API.md):**
```markdown
# FREE-MINING - API Reference

## Exports

### HasMaterial
Check if player has material
```lua
local hasMaterial = exports['free-mining']:HasMaterial(itemName, amount)
```

## [Full API docs...]
```

### Testing Criteria
- [ ] Server maintains <5ms resource time with 32 players
- [ ] No known duplication exploits
- [ ] No teleportation exploits
- [ ] Economy feels balanced (not too easy/hard)
- [ ] Admin tools fully functional
- [ ] Documentation complete and accurate
- [ ] No critical bugs remaining
- [ ] All features working as intended
- [ ] Performance optimized (60+ FPS client-side)
- [ ] Database queries <10ms average
- [ ] No memory leaks after 24hr runtime
- [ ] NUI responsive and bug-free

### Deliverables
```
free-mining/
├── optimizations/
│   ├── database.lua (NEW)
│   ├── props.lua (NEW)
│   └── network.lua (NEW)
├── admin/
│   ├── menu.lua (NEW)
│   ├── commands.lua (NEW)
│   └── logging.lua (NEW)
├── docs/
│   ├── README.md (NEW)
│   ├── INSTALL.md (NEW)
│   ├── CONFIG.md (NEW)
│   ├── FAQ.md (NEW)
│   └── API.md (NEW)
├── tutorial/
│   └── tutorial.lua (NEW)
└── VERSION.md (NEW)
```

### Key Functions to Implement
- `OptimizeQuery(query)` - Add caching layer
- `CleanupProps(zone)` - Remove old props
- `ValidateAction(player, action, data)` - Server-side checks
- `DetectExploit(player, exploitType)` - Flag suspicious activity
- `ApplyBalance(category, value)` - Adjust game balance
- `OpenAdminMenu(admin)` - Show admin UI
- `ExecuteAdminCommand(admin, command, args)` - Run admin action
- `LogEvent(eventType, data)` - Record event to database
- `ExportLogs(startDate, endDate)` - Generate log file
- `ShowTutorial(player, step)` - Display tutorial UI

---

## TIMELINE & MILESTONES

### Development Timeline

| Phase | Name | Duration | Cumulative Time |
|-------|------|----------|-----------------|
| 1 | Foundation & Core Extraction | 1-2 weeks | 2 weeks |
| 2 | Equipment & Survival Basics | 2 weeks | 4 weeks |
| 3 | Dynamic Vein System | 2-3 weeks | 7 weeks |
| 4 | Survey Equipment | 2 weeks | 9 weeks |
| 5 | Claim System | 1-2 weeks | 11 weeks |
| 6 | Multi-Stage Extraction | 2-3 weeks | 14 weeks |
| 7 | Transportation | 2 weeks | 16 weeks |
| 8 | Cave-In System | 2-3 weeks | 19 weeks |
| 9 | Multi-Zone Expansion | 2-3 weeks | 22 weeks |
| 10 | NUI & Progression | 3-4 weeks | 26 weeks |
| 11 | Processing & Economy | 2-3 weeks | 29 weeks |
| 12 | Polish & Optimization | 2-3 weeks | **32 weeks** |

**Total Development Time: 6-8 months** (assuming solo development, full-time work)

### Milestone Markers

**Alpha Release (Phases 1-3):** 7 weeks
- Basic mining with dynamic veins
- Core extraction mechanics
- Equipment degradation
- Single zone operational
- **Status:** Functional but limited

**Beta Release (Phases 1-8):** 19 weeks
- Full survival systems
- Cave-in mechanics
- Transportation infrastructure
- Multiple tools and equipment
- **Status:** Feature-complete for core gameplay

**Release Candidate (Phases 1-11):** 29 weeks
- All zones operational
- Complete NUI and progression
- Full economy chain
- Contract system
- **Status:** Feature-complete, needs polish

**Version 1.0 (All Phases):** 32 weeks
- Production-ready
- Optimized performance
- Balanced economy
- Complete documentation
- Admin tools
- **Status:** Public release ready

### Testing Phases

**Unit Testing:** Throughout development (per phase)
- Test each feature in isolation
- Verify database operations
- Check client-server communication

**Integration Testing:** After major milestones
- Test feature interactions
- Verify data flow between systems
- Check for conflicts

**Load Testing:** Before release
- Test with 32+ concurrent players
- Monitor server performance
- Identify bottlenecks

**Balance Testing:** Ongoing after Beta
- Gather player feedback
- Adjust rewards and difficulty
- Monitor economy health

**Security Testing:** Pre-release
- Attempt exploit techniques
- Validate all server-side checks
- Pen-test admin functions

---

## RECOMMENDED APPROACH

### Development Best Practices

1. **Start with Phase 1** - Get the core loop working perfectly before moving on
   - Don't rush to add features
   - Test thoroughly with real players
   - Fix all bugs before advancing

2. **Test extensively after each phase**
   - Create test scenarios
   - Document test results
   - Fix issues before moving forward

3. **Maintain a test server** 
   - Separate from production
   - Allow players to test new features
   - Gather feedback early

4. **Keep phases independent**
   - Each phase should work standalone
   - Don't create dependencies on incomplete features
   - Allows rollback if needed

5. **Document as you go**
   - Write code comments
   - Update configuration docs
   - Don't save documentation for the end

6. **Build config-first**
   - Make everything adjustable without code changes
   - Use descriptive config names
   - Add comments explaining each option

7. **Version control**
   - Commit after each completed feature
   - Use meaningful commit messages
   - Tag milestone releases

### Code Organization Tips

```
free-mining/
├── fxmanifest.lua
├── config.lua (main config, imports others)
├── shared/
│   ├── items.lua
│   ├── functions.lua
│   └── exports.lua
├── server/
│   ├── main.lua (core server logic)
│   ├── database.lua
│   ├── veins.lua
│   ├── claims.lua
│   ├── contracts.lua
│   ├── progression.lua
│   ├── processing.lua
│   ├── market.lua
│   └── admin.lua
├── client/
│   ├── main.lua (core client logic)
│   ├── mining.lua
│   ├── equipment.lua
│   ├── transport.lua
│   ├── ui/
│   │   └── nui.lua
│   └── zones.lua
├── html/
│   ├── index.html
│   ├── style.css
│   ├── script.js
│   └── assets/
├── config/
│   ├── zones/
│   ├── equipment.lua
│   ├── veins.lua
│   ├── processing.lua
│   └── market.lua
├── sql/
│   ├── install.sql
│   └── migrations/
└── docs/
    ├── README.md
    ├── INSTALL.md
    ├── CONFIG.md
    ├── FAQ.md
    └── API.md
```

### Testing Checklist Per Phase

Before moving to next phase:
- [ ] All features functional
- [ ] No console errors
- [ ] Database operations work
- [ ] Performance acceptable
- [ ] Config options work
- [ ] No known exploits
- [ ] Player tested
- [ ] Documentation updated

### Community Involvement

- **Alpha Testing:** Close friends, 5-10 players
- **Beta Testing:** Trusted community, 20-30 players
- **Public Testing:** Open server, 50+ players
- **Feedback Channels:** Discord, forums, in-game surveys
- **Bug Reporting:** Structured format, prioritization

### Post-Release Support

- **Version Updates:** Bug fixes, balance tweaks
- **Content Updates:** New ores, zones, features
- **Seasonal Events:** Special contracts, price events
- **Community Requests:** Feature voting, suggestions
- **Long-term Roadmap:** Plan 6-12 months ahead

---

## FINAL NOTES

### Success Metrics

**Technical:**
- <5ms server resource time
- 60+ FPS client-side
- <100ms database queries
- Zero critical exploits
- 99%+ uptime

**Player Engagement:**
- Average session: 2+ hours
- Return rate: 70%+ daily
- Economy participation: 80%+ of miners
- Contract completion: 60%+ rate

**Economic Health:**
- Balanced inflation (<5% monthly)
- Active marketplace
- Fair pricing across ores
- Sustainable player earnings

### Known Challenges

1. **Balancing Difficulty** - Too easy becomes boring, too hard frustrates
2. **Performance with Props** - Many spawned objects can lag
3. **Economic Inflation** - Requires careful monitoring
4. **Exploit Prevention** - Constant vigilance needed
5. **Player Retention** - Keep content fresh and rewarding

### Future Expansion Ideas

- **Underwater Mining** - Dive for rare minerals
- **Space Mining** - Asteroid fields (if sci-fi server)
- **Oil Drilling** - Alternative resource extraction
- **Crafting System** - Players craft tools/equipment
- **Mining Corporations** - Large-scale group operations
- **Dynamic Events** - Cave collapses, rare vein spawns
- **Competitions** - Timed mining challenges
- **Skill Trees** - Deeper specialization options

---

## CONCLUSION

This phased development guide provides a clear roadmap from basic functionality to a fully-featured, production-ready mining system. By following this structured approach:

✅ Each phase delivers a working, testable system  
✅ Features build progressively on prior work  
✅ Testing and balance happen throughout  
✅ Documentation grows with the codebase  
✅ Performance is optimized from the start  

**Estimated completion:** 6-8 months of dedicated development

**Key to success:** 
- Patience in early phases (foundation is critical)
- Thorough testing at every stage
- Community feedback integration
- Willingness to iterate and improve

Good luck with your FREE-MINING development! This system will provide your hardcore ultrarealistic server with an immersive, skill-based mining experience that rewards active decision-making and exploration.

---

**Document Version:** 1.0  
**Last Updated:** February 2026  
**Author:** Development Team  
**License:** Proprietary
