-- TODO: Break these out into clearly defined tables (low-priority).
return {
	-- Attacking.
	PET_ATTACK_RADIUS = 5.0,

	-- Fleeing.
	PET_IS_SCAREDY_CAT = true, -- Enable to debug and trace flee mechanics.
	PET_SAFE_THRESHOLD = 0.50,
	PET_FLEE_THRESHOLD = 1,
	PET_FLEE_SAFE_DISTANCE = 50,
	PET_FLEE_HAPPINESS_PENALTY = -5,
	PET_FLEE_HUNGER_PENALTY = 8,
	PET_FLEE_THIRST_PENALTY = 15,
	PET_FLEE_BOREDOM_PENALTY = -15,

	-- Following.
	PET_FOLLOW_RADIUS = 5.0,
	FOLLOW_RADIUS_BY_TIER = {
		["pet-biter-baby"] = 2.0,
		["pet-biter-small"] = 3.0,
		["pet-biter-large"] = 5.0
	},

	-- Bonding.
	BONDING_HUNGER_THRESHOLD = 25,
	CHANCE_TO_ADOPT_BITER = 0.50,

	-- Eating.
	FOOD_SEARCH_RADIUS = 10,
	EAT_RADIUS = 1.5
}
