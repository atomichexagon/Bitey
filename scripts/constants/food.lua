local FOOD_DEFINITIONS = {
	["raw-fish"] = {
		boredom = -1,
		evolution = 0,
		friendship = 1,
		happiness = 3,
		hunger = -10,
		morph = 0,
		thirst = -2,
		tiredness = 1
	},
	["water-barrel"] = {
		boredom = -1,
		evolution = 0,
		friendship = 1,
		happiness = 1,
		hunger = -1,
		morph = 0,
		thirst = -10,
		tiredness = 0
	},
	["sulfuric-acid-barrel"] = {
		boredom = -1,
		evolution = 0,
		friendship = 0,
		happiness = 0,
		hunger = 0,
		morph = 5,
		thirst = 10,
		tiredness = 2
	},
	["stone"] = {
		boredom = -1,
		evolution = 0,
		friendship = 0,
		happiness = 0,
		hunger = 0,
		morph = -5,
		thirst = 10,
		tiredness = 2
	},
	["uranium-238"] = {
		boredom = 1,
		evolution = 0,
		friendship = -1,
		happiness = -1,
		hunger = 5,
		morph = 0,
		thirst = 5,
		tiredness = 15
	},
	["uranium-235"] = {
		boredom = -5,
		evolution = 1,
		friendship = 0,
		happiness = 1,
		hunger = 5,
		morph = 0,
		thirst = 5,
		tiredness = -15
	},
	["spoilage"] = {
		boredom = 3,
		evolution = 0,
		friendship = -1,
		happiness = -5,
		hunger = 5,
		morph = 0,
		thirst = 10,
		tiredness = 3
	},
	["pentapod-egg"] = {
		boredom = -2,
		evolution = 0,
		friendship = 1,
		happiness = 3,
		hunger = -10,
		morph = 0,
		thirst = -5,
		tiredness = 0
	},
	["biter-egg"] = {
		boredom = 10,
		evolution = 0,
		friendship = -2,
		happiness = -15,
		hunger = -5,
		morph = 0,
		thirst = -2,
		tiredness = 0
	},
	["yumako-seed"] = {
		boredom = -1,
		evolution = 0,
		friendship = 1,
		happiness = 1,
		hunger = -1,
		morph = 0,
		thirst = 1,
		tiredness = 0
	},
	["jellynut-seed"] = {
		boredom = -1,
		evolution = 0,
		friendship = 1,
		happiness = 1,
		hunger = -1,
		morph = 0,
		thirst = 1,
		tiredness = 0
	},
	["yumako"] = {
		boredom = -1,
		evolution = 0,
		friendship = 1,
		happiness = 1,
		hunger = -2,
		morph = 0,
		thirst = -1,
		tiredness = 0
	},
	["jellynut"] = {
		boredom = -1,
		evolution = 0,
		friendship = 1,
		happiness = 1,
		hunger = -1,
		morph = 0,
		thirst = -2,
		tiredness = 0
	},
	["nutrients"] = {
		boredom = -1,
		evolution = 0,
		friendship = 1,
		happiness = 1,
		hunger = -5,
		morph = 0,
		thirst = 0,
		tiredness = 1
	},
	["bioflux"] = {
		boredom = -2,
		evolution = 0,
		friendship = 1,
		happiness = 2,
		hunger = -10,
		morph = 0,
		thirst = -10,
		tiredness = 1
	},
	["yumako-mash"] = {
		boredom = -1,
		evolution = 0,
		friendship = 1,
		happiness = 1,
		hunger = -3,
		morph = 0,
		thirst = -2,
		tiredness = 0
	},
	["jelly"] = {
		boredom = -1,
		evolution = 0,
		friendship = 1,
		happiness = 1,
		hunger = -3,
		morph = 0,
		thirst = -2,
		tiredness = 0
	},
	["tree-seed"] = {
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

return {
	FOOD_DEFINITIONS = FOOD_DEFINITIONS
}
