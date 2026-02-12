local GROWTH_SETTINGS = {	
	DEBUG_IGNORE_EVOLUTION_GATES = false, -- NOTE: Change back to false after debugging evolution.
}

-- Growth tiers and thresholds.
local GROWTH_RULES = {
	["pet-small-biter-baby"] = {
		next = "pet-small-biter-small",
		hunger_threshold = 50,
		thirst_threshold = 100,
		evo_factor_threshold = 0.06,
		evo_state_threshold = 0,
		chance = 0.50
	},
	["pet-small-biter-small"] = {
		next = "pet-small-biter-large",
		hunger_threshold = 50,
		thirst_threshold = 100,
		evo_factor_threshold = 0.12,
		evo_state_threshold = 0,
		chance = 0.45
	},
	["pet-small-biter-large"] = {
		next = "pet-medium-biter-baby",
		hunger_threshold = 50,
		thirst_threshold = 100,
		evo_factor_threshold = 0.18,
		evo_state_threshold = 0,
		chance = 0.40
	},
	["pet-medium-biter-baby"] = {
		next = "pet-medium-biter-small",
		hunger_threshold = 35,
		thirst_threshold = 50,
		evo_factor_threshold = 0.2,
		evo_state_threshold = 0,
		chance = 0.35
	},
	["pet-medium-biter-small"] = {
		next = "pet-medium-biter-large",
		hunger_threshold = 35,
		thirst_threshold = 50,
		evo_factor_threshold = 0.3,
		evo_state_threshold = 0,
		chance = 0.30
	},
	["pet-medium-biter-large"] = {
		next = "pet-big-biter-baby",
		hunger_threshold = 35,
		thirst_threshold = 35,
		evo_factor_threshold = 0.4,
		evo_state_threshold = 0,
		chance = 0.25
	},
	["pet-big-biter-baby"] = {
		next = "pet-big-biter-small",
		hunger_threshold = 25,
		thirst_threshold = 35,
		evo_factor_threshold = 0.5,
		evo_state_threshold = 0,
		chance = 0.20
	},
	["pet-big-biter-small"] = {
		next = "pet-big-biter-large",
		hunger_threshold = 25,
		thirst_threshold = 35,
		evo_factor_threshold = 0.64,
		evo_state_threshold = 100,
		chance = 0.15
	},
	["pet-big-biter-large"] = {
		next = "pet-behemoth-biter-baby",
		hunger_threshold = 25,
		thirst_threshold = 25,
		evo_factor_threshold = 0.76,
		evo_state_threshold = 0,
		chance = 0.10
	},
	["pet-behemoth-biter-baby"] = {
		next = "pet-behemoth-biter-small",
		hunger_threshold = 15,
		thirst_threshold = 15,
		evo_factor_threshold = 0.9,
		evo_state_threshold = 0,
		chance = 0.05
	},
	["pet-behemoth-biter-small"] = {
		next = "pet-behemoth-biter-large",
		hunger_threshold = 10,
		thirst_threshold = 10,
		evo_factor_threshold = 0.9,
		evo_state_threshold = 0,
		chance = 0.01
	},
	["pet-behemoth-biter-large"] = {
		next = nil,
		hunger_threshold = 0,
		thirst_threshold = 0,
		evo_factor_threshold = 0.9,
		evo_state_threshold = 0,
		chance = 0.0
	},
	["pet-small-spitter-baby"] = {
		next = "pet-small-spitter-small",
		hunger_threshold = 50,
		thirst_threshold = 100,
		evo_factor_threshold = 0.06,
		evo_state_threshold = 0,
		chance = 0.50
	},
	["pet-small-spitter-small"] = {
		next = "pet-small-spitter-large",
		hunger_threshold = 50,
		thirst_threshold = 100,
		evo_factor_threshold = 0.12,
		evo_state_threshold = 0,
		chance = 0.45
	},
	["pet-small-spitter-large"] = {
		next = "pet-medium-spitter-baby",
		hunger_threshold = 50,
		thirst_threshold = 100,
		evo_factor_threshold = 0.18,
		evo_state_threshold = 0,
		chance = 0.40
	},
	["pet-medium-spitter-baby"] = {
		next = "pet-medium-spitter-small",
		hunger_threshold = 35,
		thirst_threshold = 50,
		evo_factor_threshold = 0.2,
		evo_state_threshold = 0,
		chance = 0.35
	},
	["pet-medium-spitter-small"] = {
		next = "pet-medium-spitter-large",
		hunger_threshold = 35,
		thirst_threshold = 50,
		evo_factor_threshold = 0.3,
		evo_state_threshold = 0,
		chance = 0.30
	},
	["pet-medium-spitter-large"] = {
		next = "pet-big-spitter-baby",
		hunger_threshold = 35,
		thirst_threshold = 35,
		evo_factor_threshold = 0.4,
		evo_state_threshold = 0,
		chance = 0.25
	},
	["pet-big-spitter-baby"] = {
		next = "pet-big-spitter-small",
		hunger_threshold = 25,
		thirst_threshold = 35,
		evo_factor_threshold = 0.5,
		evo_state_threshold = 0,
		chance = 0.20
	},
	["pet-big-spitter-small"] = {
		next = "pet-big-spitter-large",
		hunger_threshold = 25,
		thirst_threshold = 35,
		evo_factor_threshold = 0.64,
		evo_state_threshold = 100,
		chance = 0.15
	},
	["pet-big-spitter-large"] = {
		next = "pet-behemoth-spitter-baby",
		hunger_threshold = 25,
		thirst_threshold = 25,
		evo_factor_threshold = 0.76,
		evo_state_threshold = 0,
		chance = 0.10
	},
	["pet-behemoth-spitter-baby"] = {
		next = "pet-behemoth-spitter-small",
		hunger_threshold = 15,
		thirst_threshold = 15,
		evo_factor_threshold = 0.9,
		evo_state_threshold = 0,
		chance = 0.05
	},
	["pet-behemoth-spitter-small"] = {
		next = "pet-behemoth-spitter-large",
		hunger_threshold = 15,
		thirst_threshold = 10,
		evo_factor_threshold = 0.9,
		evo_state_threshold = 0,
		chance = 0.01
	},
	["pet-behemoth-spitter-large"] = {
		next = nil,
		hunger_threshold = 0,
		thirst_threshold = 0,
		evo_factor_threshold = 0.9,
		evo_state_threshold = 0,
		chance = 0.0
	}
}
return {
	GROWTH_SETTINGS = GROWTH_SETTINGS,
	GROWTH_RULES = GROWTH_RULES
}
