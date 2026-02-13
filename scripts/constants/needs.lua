-- Use /bpmoods to switch to high-frequency debug intervals.
local NEED_INTERVALS = {

	-- State tick intervals for physiological needs (ticks per second) * (seconds).
	active = {
		mood = 60 * 25,
		hunger = 60 * 10,
		thirst = 60 * 20,
		boredom = 60 * 60,
		tiredness = 60 * 5
	},
	idle = {
		mood = 60 * 15,
		hunger = 60 * 15,
		thirst = 60 * 30,
		boredom = 60 * 30,
		tiredness = 60 * 5
	},
	sleeping = {
		mood = 60 * 10,
		hunger = 60 * 15,
		thirst = 60 * 30,
		boredom = 60 * 60,
		tiredness = 60 * 3
	},
	debug = {
		mood = 60 * 3,
		hunger = 60 * 3,
		thirst = 60 * 3,
		boredom = 60 * 3
	}
}

local NEED_RATES = {
	active = {
		increments = {
			-- Need increment values per need interval.
			hunger = 2,
			thirst = 2,
			boredom = 1,
			tiredness = 2
		},
		penalties = {
			-- Mood (happiness) penalty for negative physiological states at interval.
			hunger = -3,
			thirst = -2,
			boredom = -1,
			tiredness = 0,
			happiness = -2
		}

	},
	idle = {
		increments = {
			hunger = 1,
			thirst = 1,
			boredom = 2,
			tiredness = 1
		},
		penalties = {
			hunger = -1,
			thirst = -1,
			boredom = -2,
			tiredness = 0,
			happiness = -1
		}

	},
	sleeping = {
		increments = {
			hunger = 1,
			thirst = 1,
			boredom = 0,
			tiredness = -8
		},
		penalties = {
			hunger = 0,
			thirst = 0,
			boredom = 0,
			tiredness = 0,
			happiness = 0
		}

	}
}

return {
	NEED_INTERVALS = NEED_INTERVALS,
	NEED_RATES = NEED_RATES
}
