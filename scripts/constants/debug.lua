return {
	-- NOTE: All debug options should be false by default.
	DEBUG_DEFAULT_LEVEL = 0, -- 0:None, 1:Error, 2:Warn, 3:Info, 4:Trace
	DEBUG_RATE_LIMIT = 30,

	DEBUG_ENABLE_RATE_LIMITER = false,
	DEBUG_BYPASS_DECONSTRUCTION_GATE = false,
	DEBUG_BYPASS_INTRO_DELAY = false,
	DEBUG_BYPASS_RESPAWN_DELAY = false,
	DEBUG_BYPASS_EVOLUTION_GATES = false,
	DEBUG_BYPASS_MEMORIAL_ELIGIBILITY = false,
	DEBUG_BYPASS_BOND_ELIGIBILITY = false,

	DEBUG_MOOD_ENABLED = false,
	DEBUG_SCAREDY_CAT = false,
	DEBUG_SHOW_NEEDS_UPDATES = false,
	DEBUG_VISUALIZERS_ENABLED = false,

	ICON = "[img=biter-pet]",

	DEBUG_VISUALIZE_STATE_OFFSET = {
		0.65,
		-0.75
	},
	DEBUG_VISUALIZE_DAMAGE_TYPE_OFFSET = {
		-0.65,
		-0.75
	},
	DEBUG_FOLLOW_RADIUS_COLOR = {
		r = 0,
		g = 0,
		b = 255,
		a = 255
	},
	DEBUG_ITEM_SEARCH_RADIUS_COLOR = {
		r = 0,
		g = 255,
		b = 0,
		a = 255
	},
	DEBUG_INTERACT_RADIUS_COLOR = {
		r = 255,
		g = 255,
		b = 0,
		a = 255
	},
	DEBUG_ATTACK_RADIUS_COLOR = {
		r = 255,
		g = 0,
		b = 0,
		a = 255
	},
	DEBUG_INVESTIGATION_RADIUS_COLOR = {
		r = 255,
		g = 0,
		b = 255,
		a = 255
	},
	DEBUG_GUARD_RADIUS_COLOR = {
		r = 0,
		g = 0,
		b = 0,
		a = 0,
	}
}
