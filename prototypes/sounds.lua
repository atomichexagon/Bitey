data:extend({
	{
		type = "sound",
		name = "biter-roar",
		variations = sound_variations("__base__/sound/creatures/biter-roar", 6)
	},
	{
		type = "sound",
		name = "biter-roar-mid",
		variations = sound_variations("__base__/sound/creatures/biter-roar-mid", 7)
	},
	{
		type = "sound",
		name = "biter-roar-big",
		variations = sound_variations("__base__/sound/creatures/biter-roar-mid", 5)
	},
	{
		type = "sound",
		name = "biter-roar-behemoth",
		variations = sound_variations("__base__/sound/creatures/biter-roar-behemoth", 9)
	},
	{
		type = "sound",
		name = "spitter-call-small",
		variations = sound_variations("__base__/sound/creatures/spitter-call-small", 9)
	},
	{
		type = "sound",
		name = "spitter-call-med",
		variations = sound_variations("__base__/sound/creatures/spitter-call-med", 12)
	},
	{
		type = "sound",
		name = "spitter-call-big",
		variations = sound_variations("__base__/sound/creatures/spitter-call-big", 11)
	},
	{
		type = "sound",
		name = "spitter-call-behemoth",
		variations = sound_variations("__base__/sound/creatures/spitter-spit-start-behemoth", 8)
	},
	{
		type = "sound",
		name = "intro-spitter-death-call",
		sound_type = "gui-effect",
		variations = {
			filename = "__biter-pet__/sounds/death-rattle.ogg",
			volume = 1.0
		}
	}
})
