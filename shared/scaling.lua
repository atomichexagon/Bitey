local SPEED_SCALE = {
	idle = 0.5,
	sleeping = 0.1
}

local SLEEP_SCALE = {
	["pet-small-biter-baby"] = 0.600,
	["pet-small-biter-small"] = 0.625,
	["pet-small-biter-large"] = 0.650,

	["pet-medium-biter-baby"] = 1.000,
	["pet-medium-biter-small"] = 1.025,
	["pet-medium-biter-large"] = 1.050,

	["pet-big-biter-baby"] = 1.500,
	["pet-big-biter-small"] = 1.525,
	["pet-big-biter-large"] = 1.550,

	["pet-behemoth-biter-baby"] = 2.000,
	["pet-behemoth-biter-small"] = 2.025,
	["pet-behemoth-biter-large"] = 2.050,

	["pet-small-spitter-baby"] = 0.600,
	["pet-small-spitter-small"] = 0.625,
	["pet-small-spitter-large"] = 0.650,

	["pet-medium-spitter-baby"] = 1.000,
	["pet-medium-spitter-small"] = 1.025,
	["pet-medium-spitter-large"] = 1.050,

	["pet-big-spitter-baby"] = 1.500,
	["pet-big-spitter-small"] = 1.525,
	["pet-big-spitter-large"] = 1.550,

	["pet-behemoth-spitter-baby"] = 2.000,
	["pet-behemoth-spitter-small"] = 2.025,
	["pet-behemoth-spitter-large"] = 2.050
}

local SIZE_SCALE = {
	["pet-small-biter-baby"] = 0.625,
	["pet-small-biter-small"] = 0.650,
	["pet-small-biter-large"] = 0.675,

	["pet-medium-biter-baby"] = 0.725,
	["pet-medium-biter-small"] = 0.750,
	["pet-medium-biter-large"] = 0.775,

	["pet-big-biter-baby"] = 0.825,
	["pet-big-biter-small"] = 0.850,
	["pet-big-biter-large"] = 0.875,

	["pet-behemoth-biter-baby"] = 0.900,
	["pet-behemoth-biter-small"] = 0.950,
	["pet-behemoth-biter-large"] = 1.000,

	["pet-small-spitter-baby"] = 0.625,
	["pet-small-spitter-small"] = 0.635,
	["pet-small-spitter-large"] = 0.645,

	["pet-medium-spitter-baby"] = 0.685,
	["pet-medium-spitter-small"] = 0.695,
	["pet-medium-spitter-large"] = 0.705,

	["pet-big-spitter-baby"] = 0.745,
	["pet-big-spitter-small"] = 0.755,
	["pet-big-spitter-large"] = 0.765,

	["pet-behemoth-spitter-baby"] = 0.805,
	["pet-behemoth-spitter-small"] = 0.815,
	["pet-behemoth-spitter-large"] = 0.855,
}

local HEALTH_SCALE = {
	["pet-small-biter-baby"] = 1.0,
	["pet-small-biter-small"] = 1.1,
	["pet-small-biter-large"] = 1.2,

	["pet-medium-biter-baby"] = 1.3,
	["pet-medium-biter-small"] = 1.4,
	["pet-medium-biter-large"] = 1.5,

	["pet-big-biter-baby"] = 1.6,
	["pet-big-biter-small"] = 1.7,
	["pet-big-biter-large"] = 1.8,

	["pet-behemoth-biter-baby"] = 2.0,
	["pet-behemoth-biter-small"] = 2.2,
	["pet-behemoth-biter-large"] = 2.5,

	["pet-small-spitter-baby"] = 1.0,
	["pet-small-spitter-small"] = 1.1,
	["pet-small-spitter-large"] = 1.2,

	["pet-medium-spitter-baby"] = 1.3,
	["pet-medium-spitter-small"] = 1.4,
	["pet-medium-spitter-large"] = 1.5,

	["pet-big-spitter-baby"] = 1.6,
	["pet-big-spitter-small"] = 1.7,
	["pet-big-spitter-large"] = 1.8,

	["pet-behemoth-spitter-baby"] = 2.0,
	["pet-behemoth-spitter-small"] = 2.2,
	["pet-behemoth-spitter-large"] = 2.5
}

return {
	SIZE_SCALE = SIZE_SCALE,
	SPEED_SCALE = SPEED_SCALE,
	SLEEP_SCALE = SLEEP_SCALE,
	HEALTH_SCALE = HEALTH_SCALE
}
