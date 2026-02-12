return {
	-- Attacking.
	PET_ATTACK_RADIUS = 5.0,

	-- Fleeing.
	PET_IS_SCAREDY_CAT = false, -- NOTE: Enable to debug and trace flee mechanics.
	PET_SAFE_THRESHOLD = 0.50, -- Pet will stop fleeing when percentage of health is above this threshold.
	PET_FLEE_THRESHOLD = 0.25, -- Pet will flee when percentage of health is below this value.
	PET_FLEE_SAFE_DISTANCE = 50, -- Distance in tiles pet will flee from danger.
	PET_FLEE_HAPPINESS_PENALTY = -5,
	PET_FLEE_HUNGER_PENALTY = 8,
	PET_FLEE_THIRST_PENALTY = 15,
	PET_FLEE_BOREDOM_PENALTY = -15,

	-- Following.
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

	-- Eating.
	FOOD_SEARCH_RADIUS = 8,
	EAT_RADIUS = 1.5,
	SEEK_FOOD_THRESHOLD = 5,
	SEEK_WATER_THRESHOLD = 5,

	-- Sleeping.
	TIREDNESS_SLEEP_THRESHOLD = 70,
	TIREDNESS_WAKE_THRESHOLD = 10,
	DARKNESS_THRESHOLD = 0.75,
	HUNGER_WAKE_THRESHOLD = 90,
	THIRST_WAKE_THRESHOLD = 90
}
