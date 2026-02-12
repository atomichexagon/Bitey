return {
	SPAWN_SEARCH_RADIUS = 6,
	SEARCH_PRECISION = 0.5,

	MINIMUM_SPAWN_DISTANCE = 50, -- Don't go far over 32 else you risk spawning in unloaded chunks.
	MAXIMUM_SPAWN_OFFSET = 150,

	TICKS_PER_DAY = 25200, -- The standard day length on Nauvis.

	PET_DEFAULTS = {
		boredom = 50,
		evolution = 0,
		friendship = 0,
		happiness = 0,
		hunger = 100,
		morph = 0,
		thirst = 100,
		tiredness = 50,
		current_form = "active",
		feeding_target = nil
	}
}
