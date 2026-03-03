return {
	-- General.
	PET_DEFAULT_NAME = "Bitey",

	-- Attacking.
	PET_ATTACK_RADIUS = 5.0,

	-- Fleeing.
	PET_SAFE_THRESHOLD = 0.80,
	PET_FLEE_THRESHOLD = 0.25,
	PET_FLEE_SAFE_DISTANCE = 50,
	PET_FLEE_HAPPINESS_PENALTY = -5,
	PET_FLEE_HUNGER_PENALTY = 8,
	PET_FLEE_THIRST_PENALTY = 15,
	PET_FLEE_BOREDOM_PENALTY = -15,

	-- Following.
	PET_GUARD_CORPSE_RADIUS = 3.0,
	PET_FOLLOW_RADIUS = 6.0,
	FOLLOW_RADIUS_BY_TIER = {
		["pet-small-biter-baby"] = 3.0,
		["pet-small-biter-small"] = 3.2,
		["pet-small-biter-large"] = 3.5,

		["pet-medium-biter-baby"] = 4.0,
		["pet-medium-biter-small"] = 6.0,
		["pet-medium-biter-large"] = 7.0,

		["pet-big-biter-baby"] = 8.0,
		["pet-big-biter-small"] = 9.0,
		["pet-big-biter-large"] = 10.0,

		["pet-behemoth-biter-baby"] = 12.0,
		["pet-behemoth-biter-small"] = 13.0,
		["pet-behemoth-biter-large"] = 15.0,

		["pet-small-spitter-baby"] = 3.0,
		["pet-small-spitter-small"] = 3.2,
		["pet-small-spitter-large"] = 3.5,

		["pet-medium-spitter-baby"] = 4.0,
		["pet-medium-spitter-small"] = 6.0,
		["pet-medium-spitter-large"] = 7.0,

		["pet-big-spitter-baby"] = 8.0,
		["pet-big-spitter-small"] = 9.0,
		["pet-big-spitter-large"] = 10.0,

		["pet-behemoth-spitter-baby"] = 12.0,
		["pet-behemoth-spitter-small"] = 13.0,
		["pet-behemoth-spitter-large"] = 15.0
	},
	IDLE_RADIUS_MULTIPLIER = 3.0,
	CHANCE_TO_PAUSE = 0.2,

	-- Bonding.
	BONDING_HUNGER_THRESHOLD = 25,
	CHANCE_TO_ADOPT_BITER = 0.50,

	-- Interaction.
	ITEM_SEARCH_RADIUS = 8,
	INTERACT_RADIUS = 1.5,
	INTERACT_RADIUS_SQUARED = 1.5 * 1.5,
	DECONSTRUCTION_RADIUS = 25,
	DECONSTRUCTION_RADIUS_SQUARED = 25 * 25,
	GUARD_RADIUS = 10,
	GUARD_RADIUS_SQUARED = 10 * 10,
	GUARDING_INVESTIGATION_MULTIPLIER = 3,
	ASLEEP_ON_THE_JOB_CHANCE = 0.005,
	INVESTIGATION_CHANCE = 0.003,
	INVESTIGATION_RADIUS = 20,
	INVESTIGATION_RADIUS_SQUARED = 20 * 20,
	INVESTIGATION_TARGETS = {
		"accumulator",
		"agricultural-tower",
		"ammo-turret",
		"artillery-turret",
		"artillery-wagon",
		"assembling-machine",
		"beacon",
		"boiler",
		"car",
		"cargo-landing-pad",
		"container",
		"display-panel",
		"electric-turret",
		"furnace",
		"generator",
		"lab",
		"lamp",
		"mining-drill",
		"pump",
		"radar",
		"reactor",
		"roboport",
		"rocket-silo",
		"solar-panel",
		"spider-vehicle",
		"train-stop",
		"turret"
	},
	INVESTIGATION_EMOTES = {
		"confused",
		"scared",
		"home",
		"defend",
		"cringe",
		"happy",
		"love",
		"horrified"
	},

	-- Eating.
	SEEK_FOOD_HUNGER_THRESHOLD = 5,
	SEEK_WATER_THIRST_THRESHOLD = 5,
	SEEK_MORPH_THIRST_THRESHOLD = 75,
	SEEK_EVOLUTION_TIREDNESS_THRESHOLD = 75,
	SEEK_PLAY_TIREDNESS_THRESHOLD = 75,
	SEEK_PLAY_BOREDOM_THRESHOLD = 5,

	-- Sleeping.
	TIREDNESS_SLEEP_THRESHOLD = 70,
	TIREDNESS_WAKE_THRESHOLD = 10,
	DARKNESS_THRESHOLD = 0.65,
	HUNGER_WAKE_THRESHOLD = 95,
	THIRST_WAKE_THRESHOLD = 95,

	-- Death.
	MEMORIAL_BOND_THRESHOLD = 60 * 60 * 60 * 5,
	PET_REMAINS_MAP = {
		biter = "pet-biter-remains-placeholder",
		spitter = "pet-spitter-remains-placeholder"
	},
	VALID_PET_REMAINS = {
		["pet-biter-remains-placeholder"] = "pet-biter-grief-processing",
		["pet-spitter-remains-placeholder"] = "pet-spitter-grief-processing"
	},

	-- Miscellaneous
	PET_BELT_REACTION_COOLDOWN = 60 * 3
}
