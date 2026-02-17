local LC = require("scripts.constants.lifecycle")

local ITEM_DEFINITIONS = {
	["wood"] = {
		emotes = {
			{
				name = "play",
				fast_render = false
			},
			{
				name = "ecstatic",
				fast_render = false
			}
		},
		interaction = "fetch",
		need_check = function(needs)
			return needs.boredom >= LC.SEEK_PLAY_BOREDOM_THRESHOLD and needs.tiredness < LC.SEEK_PLAY_TIREDNESS_THRESHOLD
		end,
		modifiers = {
			boredom = -5,
			evolution = 0,
			friendship = 1,
			happiness = 2,
			hunger = 1,
			morph = 0,
			thirst = 1,
			tiredness = 2
		}
	},
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
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.hunger > LC.SEEK_FOOD_HUNGER_THRESHOLD
		end,
		modifiers = {
			boredom = -1,
			evolution = 0,
			friendship = 1,
			happiness = 3,
			hunger = -10,
			morph = 0,
			thirst = -2,
			tiredness = 1
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
		},
		interaction = "drink",
		need_check = function(needs)
			return needs.thirst < LC.SEEK_WATER_THIRST_THRESHOLD
		end,
		modifiers = {
			boredom = -1,
			evolution = 0,
			friendship = 1,
			happiness = 1,
			hunger = -1,
			morph = 0,
			thirst = -10,
			tiredness = 0
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
		},
		interaction = "drink",
		need_check = function(needs)
			return needs.thirst < LC.SEEK_MORPH_THIRST_THRESHOLD
		end,
		modifiers = {
			boredom = -1,
			evolution = 0,
			friendship = 0,
			happiness = 0,
			hunger = 0,
			morph = 1,
			thirst = 10,
			tiredness = 2

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
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.thirst < LC.SEEK_MORPH_THIRST_THRESHOLD
		end,
		modifiers = {
			boredom = -1,
			evolution = 0,
			friendship = 0,
			happiness = 0,
			hunger = 0,
			morph = -1,
			thirst = 10,
			tiredness = 2
		}
	},
	["uranium-238"] = {
		emotes = {
			{
				name = "uranium-238",
				fast_render = true
			},
			{
				name = "sick",
				fast_render = false
			}
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.hunger > LC.SEEK_FOOD_HUNGER_THRESHOLD
		end,
		modifiers = {
			boredom = 1,
			evolution = 0,
			friendship = -1,
			happiness = -1,
			hunger = 5,
			morph = 0,
			thirst = 5,
			tiredness = 15
		}
	},
	["uranium-235"] = {
		emotes = {
			{
				name = "uranium-235",
				fast_render = true
			},
			{
				name = "evolve",
				fast_render = false
			}
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.tiredness < LC.SEEK_EVOLUTION_TIREDNESS_THRESHOLD
		end,
		modifiers = {
			boredom = -5,
			evolution = 1,
			friendship = 0,
			happiness = 1,
			hunger = 5,
			morph = 0,
			thirst = 5,
			tiredness = -15
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
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.hunger > LC.SEEK_FOOD_HUNGER_THRESHOLD
		end,
		modifiers = {
			boredom = 3,
			evolution = 0,
			friendship = -1,
			happiness = -5,
			hunger = 5,
			morph = 0,
			thirst = 10,
			tiredness = 3
		}
	},
	["pentapod-egg"] = {
		emotes = {
			{
				name = "pentapod-egg",
				fast_render = true
			},
			{
				name = "ecstatic",
				fast_render = false
			}
		},
		interaction = "eat",
		modifiers = {
			boredom = -2,
			evolution = 0,
			friendship = 1,
			happiness = 3,
			hunger = -10,
			morph = 0,
			thirst = -5,
			tiredness = 0
		}
	},
	["biter-egg"] = {
		emotes = {
			{
				name = "biter-egg",
				fast_render = true
			},
			{
				name = "horrified",
				fast_render = false
			}
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.hunger > LC.SEEK_FOOD_HUNGER_THRESHOLD
		end,
		modifiers = {
			boredom = 10,
			evolution = 0,
			friendship = -2,
			happiness = -15,
			hunger = -5,
			morph = 0,
			thirst = -2,
			tiredness = 0
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
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.hunger > LC.SEEK_FOOD_HUNGER_THRESHOLD
		end,
		modifiers = {
			boredom = -1,
			evolution = 0,
			friendship = 1,
			happiness = 1,
			hunger = -1,
			morph = 0,
			thirst = 1,
			tiredness = 0
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
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.hunger > LC.SEEK_FOOD_HUNGER_THRESHOLD
		end,
		modifiers = {
			boredom = -1,
			evolution = 0,
			friendship = 1,
			happiness = 1,
			hunger = -1,
			morph = 0,
			thirst = 1,
			tiredness = 0
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
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.hunger > LC.SEEK_FOOD_HUNGER_THRESHOLD
		end,
		modifiers = {
			boredom = -1,
			evolution = 0,
			friendship = 1,
			happiness = 1,
			hunger = -2,
			morph = 0,
			thirst = -1,
			tiredness = 0
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
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.hunger > LC.SEEK_FOOD_HUNGER_THRESHOLD
		end,
		modifiers = {
			boredom = -1,
			evolution = 0,
			friendship = 1,
			happiness = 1,
			hunger = -1,
			morph = 0,
			thirst = -2,
			tiredness = 0
		}
	},
	["nutrients"] = {
		emotes = {
			{
				name = "very-happy",
				fast_render = true
			},
			{
				name = "defend",
				fast_render = false
			}
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.hunger > LC.SEEK_FOOD_HUNGER_THRESHOLD
		end,
		modifiers = {
			boredom = -1,
			evolution = 0,
			friendship = 1,
			happiness = 1,
			hunger = -5,
			morph = 0,
			thirst = 0,
			tiredness = 1
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
		},
		interaction = "eat",
		modifiers = {
			boredom = -2,
			evolution = 0,
			friendship = 1,
			happiness = 2,
			hunger = -10,
			morph = 0,
			thirst = -10,
			tiredness = 1
		}
	},
	["yumako-mash"] = {
		emotes = {
			{
				name = "yumako-mash",
				fast_render = true
			},
			{
				name = "ecstatic",
				fast_render = false
			}
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.hunger > LC.SEEK_FOOD_HUNGER_THRESHOLD
		end,
		modifiers = {
			boredom = -1,
			evolution = 0,
			friendship = 1,
			happiness = 1,
			hunger = -3,
			morph = 0,
			thirst = -2,
			tiredness = 0
		}
	},
	["jelly"] = {
		emotes = {
			{
				name = "yumako-mash",
				fast_render = true
			},
			{
				name = "ecstatic",
				fast_render = false
			}
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.hunger > LC.SEEK_FOOD_HUNGER_THRESHOLD
		end,
		modifiers = {
			boredom = -1,
			evolution = 0,
			friendship = 1,
			happiness = 1,
			hunger = -3,
			morph = 0,
			thirst = -2,
			tiredness = 0
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
		},
		interaction = "eat",
		need_check = function(needs)
			return needs.hunger > LC.SEEK_FOOD_HUNGER_THRESHOLD
		end,
		modifiers = {
			boredom = -1,
			evolution = 0,
			friendship = 1,
			happiness = 1,
			hunger = -2,
			morph = 0,
			thirst = 1,
			tiredness = 0
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
				name = "very-sad",
				fast_render = false
			}
		}
	}
}

return {
	ITEM_DEFINITIONS = ITEM_DEFINITIONS,
	COMBAT_REACTIONS = COMBAT_REACTIONS
}
