---@meta
--- ox_inventory item definitions for free-mining
--- Add these entries to your ox_inventory/data/items.lua

--[[

    -- Tools
    ['pickaxe'] = {
        label = 'Pickaxe',
        weight = 5000,
        stack = false,
        close = true,
        description = 'A sturdy pickaxe for mining ore',
    },
    ['rock_drill'] = {
        label = 'Rock Drill',
        weight = 8000,
        stack = false,
        close = true,
        description = 'A powered rock drill for extracting hard minerals',
    },
    ['drill_bit'] = {
        label = 'Drill Bit',
        weight = 500,
        stack = true,
        close = true,
        description = 'Replacement bit for a rock drill. Restores 50 uses.',
    },

    -- Fuel
    ['propane_canister'] = {
        label = 'Propane Canister',
        weight = 3000,
        stack = true,
        close = true,
        description = 'Fuel canister for smelting furnace. 5 uses per canister.',
    },

    -- Cave Ores
    ['ore_copper'] = {
        label = 'Copper Ore',
        weight = 4000,
        stack = true,
        close = false,
        description = 'Raw copper ore',
    },
    ['ore_silver'] = {
        label = 'Silver Ore',
        weight = 5000,
        stack = true,
        close = false,
        description = 'Raw silver ore',
    },
    ['ore_gold'] = {
        label = 'Gold Ore',
        weight = 8000,
        stack = true,
        close = false,
        description = 'Raw gold ore',
    },
    ['raw_quartz'] = {
        label = 'Raw Quartz',
        weight = 3000,
        stack = true,
        close = false,
        description = 'Uncut quartz crystal',
    },
    ['raw_emerald'] = {
        label = 'Raw Emerald',
        weight = 4000,
        stack = true,
        close = false,
        description = 'Uncut emerald gemstone',
    },

    -- Mine Shaft Ores
    ['ore_iron'] = {
        label = 'Iron Ore',
        weight = 6000,
        stack = true,
        close = false,
        description = 'Raw iron ore',
    },
    ['ore_platinum'] = {
        label = 'Platinum Ore',
        weight = 7000,
        stack = true,
        close = false,
        description = 'Raw platinum ore',
    },
    ['ore_titanium'] = {
        label = 'Titanium Ore',
        weight = 8000,
        stack = true,
        close = false,
        description = 'Raw titanium ore',
    },
    ['coal'] = {
        label = 'Coal',
        weight = 3000,
        stack = true,
        close = false,
        description = 'Mined coal. Used as smelting fuel or sold.',
    },
    ['raw_diamond'] = {
        label = 'Raw Diamond',
        weight = 2000,
        stack = true,
        close = false,
        description = 'Uncut rough diamond',
    },

    -- Ingots (Smelted)
    ['ingot_copper'] = {
        label = 'Copper Ingot',
        weight = 3500,
        stack = true,
        close = false,
        description = 'Smelted copper ingot',
    },
    ['ingot_silver'] = {
        label = 'Silver Ingot',
        weight = 4500,
        stack = true,
        close = false,
        description = 'Smelted silver ingot',
    },
    ['ingot_gold'] = {
        label = 'Gold Ingot',
        weight = 7000,
        stack = true,
        close = false,
        description = 'Smelted gold ingot',
    },
    ['ingot_iron'] = {
        label = 'Iron Ingot',
        weight = 5000,
        stack = true,
        close = false,
        description = 'Smelted iron ingot',
    },
    ['ingot_platinum'] = {
        label = 'Platinum Ingot',
        weight = 6000,
        stack = true,
        close = false,
        description = 'Smelted platinum ingot',
    },
    ['ingot_titanium'] = {
        label = 'Titanium Ingot',
        weight = 7000,
        stack = true,
        close = false,
        description = 'Smelted titanium ingot',
    },

    -- Cut Gems
    ['cut_quartz'] = {
        label = 'Cut Quartz',
        weight = 2000,
        stack = true,
        close = false,
        description = 'Polished and cut quartz crystal',
    },
    ['cut_emerald'] = {
        label = 'Cut Emerald',
        weight = 3000,
        stack = true,
        close = false,
        description = 'Expertly cut emerald gemstone',
    },
    ['cut_diamond'] = {
        label = 'Cut Diamond',
        weight = 1500,
        stack = true,
        close = false,
        description = 'Brilliantly cut diamond',
    },

    -- Quarry Ores (Phase 4)
    ['limestone'] = {
        label = 'Limestone',
        weight = 5000,
        stack = true,
        close = false,
        description = 'Quarried limestone block',
    },
    ['sandstone'] = {
        label = 'Sandstone',
        weight = 4000,
        stack = true,
        close = false,
        description = 'Quarried sandstone',
    },

    -- Materials
    ['stone'] = {
        label = 'Stone',
        weight = 5000,
        stack = true,
        close = false,
        description = 'Rough stone. Construction material.',
    },

    -- Safety Equipment (Phase 3)
    ['mining_helmet'] = {
        label = 'Mining Helmet',
        weight = 2000,
        stack = false,
        close = true,
        description = 'Helmet with built-in lamp. Requires batteries.',
    },
    ['helmet_battery'] = {
        label = 'Helmet Battery',
        weight = 300,
        stack = true,
        close = true,
        description = 'Replacement battery for mining helmet. Restores 50 charge.',
    },
    ['respirator'] = {
        label = 'Respirator',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Filters toxic gas in mines. 100 uses.',
    },
    ['wooden_support'] = {
        label = 'Wooden Support',
        weight = 8000,
        stack = true,
        close = true,
        description = 'Structural support beam. Place to reduce cave-in risk.',
    },

    -- Explosives
    ['dynamite'] = {
        label = 'Dynamite',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Explosive charge for blast mining. Destroys entire veins.',
    },
    ['blasting_charge'] = {
        label = 'Blasting Charge',
        weight = 3000,
        stack = true,
        close = true,
        description = 'Heavy-duty explosive for demolition and quarry blasting.',
    },
    ['detonator'] = {
        label = 'Detonator',
        weight = 1500,
        stack = false,
        close = true,
        description = 'Remote detonator for explosives. 50 uses.',
    },
    ['detonator_wire'] = {
        label = 'Detonator Wire',
        weight = 500,
        stack = true,
        close = true,
        description = 'Wiring kit for connecting multiple charges together.',
    },

]]
