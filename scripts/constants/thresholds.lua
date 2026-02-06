local MOOD_THRESHOLDS = {
	-- Hunger thresholds.
	STARVING = 90,
	HUNGRY = 70,
	CONTENT = 40,
	FULL = 0,

	-- Thirst thresholds.
	DEHYDRATED = 90,
	PARCHED = 70,
	QUENCHED = 40,
	HYDRATED = 0,

	-- Boredom thresholds.
	FRUSTRATED = 90,
	APATHETIC = 70,
	ALERT = 40,
	FOCUSED = 0,

	-- Happiness thresholds.
	OVERJOYED = 90,
	HAPPY = 70,
	SAD = 40,
	DEPRESSED = 20,

	-- Friendship thresholds.
	DEVOTED = 90,
	LOYAL = 70,
	FRIENDLY = 40,
	WARY = 0
}

return {
	MOOD_THRESHOLDS = MOOD_THRESHOLDS
}
