local FOOD_REACTIONS = {
	["raw-fish"] = {
		emotes = {
			{
				name = "love",
				fast_render = true
			},
			{
				name = "defend",
				fast_render = false
			}
		}
	},
	["water-barrel"] = {
		emotes = {
			{
				name = "love",
				fast_render = true
			},
			{
				name = "defend",
				fast_render = false
			}
		}
	},
	["sulfuric-acid-barrel"] = {
		emotes = {
			{
				name = "spitter",
				fast_render = true
			},
			{
				name = "confused",
				fast_render = false
			}
		}
	},
	["stone"] = {
		emotes = {
			{
				name = "biter",
				fast_render = true
			},
			{
				name = "confused",
				fast_render = false
			}
		}
	},
	["uranium-238"] = {
		emotes = {
			{
				name = "uranium_238",
				fast_render = true
			},
			{
				name = "sick",
				fast_render = false
			}
		}
	},
	["uranium-235"] = {
		emotes = {
			{
				name = "uranium_235",
				fast_render = true
			},
			{
				name = "evolve",
				fast_render = false
			}
		}
	},
	["spoilage"] = {
		emotes = {
			{
				name = "angry",
				fast_render = true
			},
			{
				name = "defend",
				fast_render = false
			}
		}
	},
	["pentapod-egg"] = {
		emotes = {
			{
				name = "pentapod_egg",
				fast_render = true
			},
			{
				name = "cringe",
				fast_render = false
			}
		}
	},
	["biter-egg"] = {
		emotes = {
			{
				name = "biter_egg",
				fast_render = true
			},
			{
				name = "horrified",
				fast_render = false
			}
		}
	},
	["yumako-seed"] = {
		emotes = {
			{
				name = "happy",
				fast_render = true
			},
			{
				name = "defend",
				fast_render = false
			}
		}
	},
	["jellynut-seed"] = {
		emotes = {
			{
				name = "happy",
				fast_render = true
			},
			{
				name = "defend",
				fast_render = false
			}
		}
	},
	["yumako"] = {
		emotes = {
			{
				name = "yumako",
				fast_render = true
			},
			{
				name = "happy",
				fast_render = false
			}
		}
	},
	["jellynut"] = {
		emotes = {
			{
				name = "jellynut",
				fast_render = true
			},
			{
				name = "happy",
				fast_render = false
			}
		}
	},
	["nutrients"] = {
		emotes = {
			{
				name = "very_happy",
				fast_render = true
			},
			{
				name = "defend",
				fast_render = false
			}
		}
	},
	["bioflux"] = {
		emotes = {
			{
				name = "bioflux",
				fast_render = true
			},
			{
				name = "ecstatic",
				fast_render = false
			}
		}
	},
	["yumako-mash"] = {
		emotes = {
			{
				name = "yumako_mash",
				fast_render = true
			},
			{
				name = "ecstatic",
				fast_render = false
			}
		}
	},
	["jelly"] = {
		emotes = {
			{
				name = "yumako_mash",
				fast_render = true
			},
			{
				name = "ecstatic",
				fast_render = false
			}
		}
	},
	["tree-seed"] = {
		emotes = {
			{
				name = "wood",
				fast_render = true
			},
			{
				name = "happy",
				fast_render = false
			}
		}
	}
}

local COMBAT_REACTIONS = {
	["cowardice"] = {
		emotes = {
			{
				name = "attack",
				fast_render = true
			},
			{
				name = "very_sad",
				fast_render = false
			}
		}
	},
}

return {
	FOOD_REACTIONS = FOOD_REACTIONS,
	FOOD_DEFINITIONS = FOOD_REACTIONS,
	COMBAT_REACTIONS = COMBAT_REACTIONS
}
