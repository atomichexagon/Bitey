local SPAWN_SETTINGS = {
	spawn_search_radius = 6,
	search_precision = 0.5,

	minimum_spawn_distance = 100, -- don't go far over 32 else you risk spawning in unloaded chunks.
	maximum_spawn_offset = 150,

	ticks_per_day = 25200 -- the standard day length on nauvis.
}

local STATE_DEFAULTS = {
	boredom = 50,
	evolution = 0,
	friendship = 0,
	happiness = 0,
	hunger = 100,
	morph = 0,
	thirst = 0,
	tiredness = 50,
	feeding_target = nil,
	attack_target = nil,
	item_interaction = nil

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
