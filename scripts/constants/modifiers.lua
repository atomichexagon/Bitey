local MOOD_BONUS_SCALER = 25
local GUARDING_INTERVAL_MULTIPLIER = 3

local COMBAT_MODIFIERS = {
	["cowardice"] = {
		boredom = -12,
		evolution = 0,
		friendship = 0,
		happiness = -8,
		hunger = 12,
		morph = 0,
		thirst = 6,
		tiredness = 10
	}
}

local BEHAVIORAL_MODIFIERS = {
	["total_betrayal"] = {
		boredom = -0,
		evolution = -10,
		friendship = -100,
		happiness = -25,
		hunger = 5,
		morph = 0,
		thirst = 5,
		tiredness = 1
	},
	["mild_betrayal"] = {
		boredom = -0,
		evolution = -5,
		friendship = -50,
		happiness = -15,
		hunger = 5,
		morph = 0,
		thirst = 5,
		tiredness = 1
	},
	["betrayal"] = {
		boredom = 0,
		evolution = -3,
		friendship = -25,
		happiness = -10,
		hunger = 5,
		morph = 0,
		thirst = 5,
		tiredness = 1
	},
	["playing-dead"] = {
		boredom = -5,
		evolution = 0,
		friendship = 2,
		happiness = 2,
		hunger = 1,
		morph = 0,
		thirst = 1,
		tiredness = 1
	}
}

return {
	MOOD_BONUS_SCALER = MOOD_BONUS_SCALER,
	COMBAT_MODIFIERS = COMBAT_MODIFIERS,
	BEHAVIORAL_MODIFIERS = BEHAVIORAL_MODIFIERS,
	GUARDING_INTERVAL_MULTIPLIER = GUARDING_INTERVAL_MULTIPLIER
}
