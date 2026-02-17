local SPAWN_SETTINGS = {
	spawn_search_radius = 6, -- Default: 6
	search_precision = 0.5, -- Default: 0.5

	minimum_spawn_distance = 100, -- Default: 100
	maximum_spawn_offset = 150, -- Default: 150

	ticks_per_day = 25200, -- Default: 25200
	ticks_per_year = 9198000 -- Default: 9198000
}

local STATE_DEFAULTS = {
	boredom = 50, -- Default: 50
	evolution = 0, -- Default: 0
	friendship = 0, -- Default: 0
	happiness = 0, -- Default: 0
	hunger = 100, -- Default: 100
	morph = 0, -- Default: 0
	thirst = 0, -- Default: 0
	tiredness = 50, -- Default: 50
}

local ORPHAN_MAP = {
	["biter"] = "pet-small-biter-baby",
	["spitter"] = "pet-small-spitter-baby"
}

return {
	SPAWN_SETTINGS = SPAWN_SETTINGS,
	STATE_DEFAULTS = STATE_DEFAULTS,
	ORPHAN_MAP = ORPHAN_MAP
}
