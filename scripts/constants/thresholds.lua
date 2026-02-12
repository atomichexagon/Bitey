local MOOD_THRESHOLDS = {
	-- Hunger thresholds.
	starving = 90,
	hungry = 70,
	content = 40,
	full = 0,

	-- Thirst thresholds.
	dehydrated = 90,
	parched = 70,
	quenched = 40,
	hydrated = 0,

	-- Boredom thresholds.
	frustrated = 90,
	apathetic = 70,
	alert = 40,
	focused = 0,

	-- Tiredness thresholds.
	exhausted = 95,
	sleepy = 80,
	animated = 65,
	energized = 25,

	-- Happiness thresholds.
	overjoyed = 90,
	happy = 70,
	sad = 40,
	depressed = 20,

	-- Friendship thresholds.
	devoted = 90,
	loyal = 70,
	friendly = 40,
	wary = 0
}

local THRESHOLD_TO_SPRITE_MAP = {
	starving = "hungry",
	frustrated = "angry",
	depressed = "very_sad",
	devoted = "love",
	exhausted = "playing_dead",
	hungry = "hungry",
	apathetic = "bored",
	sad = "sad",
	loyal = "happy",
	sleepy = "tired",
	content = "happy",
	alert = "investigate",
	happy = "happy",
	friendly = "love",
	animated = "animated",
	full = "happy",
	focused = "investigate",
	overjoyed = "very_happy",
	wary = "scared",
	energized = "energized"
}

return {
	MOOD_THRESHOLDS = MOOD_THRESHOLDS,
	THRESHOLD_TO_SPRITE_MAP = THRESHOLD_TO_SPRITE_MAP
}
