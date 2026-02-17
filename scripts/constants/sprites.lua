-- TODO: Organize and validate all of this shit.
local SPRITE_MAP = {
	-- General emotes.
	["alert"] = {
		sprite = "virtual-signal/signal-alert"
	},
	["home"] = {
		sprite = "entity/biter-spawner"
	},
	["investigate"] = {
		sprite = "investigate"
	},
	["sleeping"] = {
		sprite = "sleeping"
	},
	["tired"] = {
		sprite = "virtual-signal/signal-battery-low"
	},
	["animated"] = {
		sprite = "virtual-signal/signal-battery-mid-level"
	},
	["energized"] = {
		sprite = "virtual-signal/signal-battery-full"
	},
	["work"] = {
		sprite = "virtual-signal/signal-mining"
	},
	-- Combat emotes.
	["attack"] = {
		sprite = "item/submachine-gun"
	},
	["biter"] = {
		sprite = "entity/medium-biter"
	},
	["defend"] = {
		sprite = "entity/character"
	},
	["fire"] = {
		sprite = "virtual-signal/signal-fire"
	},
	["patrol"] = {
		sprite = "virtual-signal/signal-white-flag"
	},
	["scared"] = {
		sprite = "scared"
	},
	["spitter"] = {
		sprite = "entity/medium-spitter"
	},
	["stay"] = {
		sprite = "virtual-signal/signal-map-marker"
	},
	["stone"] = {
		sprite = "item/stone"
	},
	["sulfuric-acid"] = {
		sprite = "item/sulfuric-acid-barrel"
	},
	-- Feeding emotes.
	["hungry"] = {
		sprite = "item/raw-fish"
	},
	["horrified"] = {
		sprite = "horrified"
	},
	["evolve"] = {
		sprite = "virtual-signal/signal-radioactivity"
	},
	["sick"] = {
		sprite = "sick"
	},
	["thirsty"] = {
		sprite = "fluid/water"
	},
	["cringe"] = {
		sprite = "cringe"
	},
	-- Boredom emotes.
	["bored"] = {
		sprite = "bored"
	},
	["confused"] = {
		sprite = "confused"
	},
	["mischievous"] = {
		sprite = "silly"
	},
	["play"] = {
		sprite = "item/wood"
	},
	["playing-dead"] = {
		sprite = "playing-dead"
	},
	-- Happiness emotes.
	["ecstatic"] = {
		sprite = "ecstatic"
	},
	["very-happy"] = {
		sprite = "very-happy"
	},
	["happy"] = {
		sprite = "happy"
	},
	["sad"] = {
		sprite = "sad"
	},
	["very-sad"] = {
		sprite = "very-sad"
	},
	-- Friendship emotes.
	["angry"] = {
		sprite = "angry"
	},
	["gift"] = {
		sprite = "gift"
	},
	["hurt"] = {
		sprite = "entity/behemoth-biter-die"
	},
	["love"] = {
		sprite = "virtual-signal/signal-heart"
	},
	-- Food emotes.
	["uranium-238"] = {
		sprite = "item/uranium-238"
	},
	["uranium-235"] = {
		sprite = "item/uranium-235"
	},
	["spoilage"] = {
		sprite = "item/spoilage"
	},
	["pentapod-egg"] = {
		sprite = "item/pentapod-egg"
	},
	["biter-egg"] = {
		sprite = "item/biter-egg"
	},
	["yumako-seed"] = {
		sprite = "item/yumako-seed"
	},
	["jellynut-seed"] = {
		sprite = "item/jellynut-seed"
	},
	["yumako"] = {
		sprite = "item/yumako"
	},
	["jellynut"] = {
		sprite = "item/jellynut"
	},
	["nutrient"] = {
		sprite = "item/nutrients"
	},
	["bioflux"] = {
		sprite = "item/bioflux"
	},
	["yumako-mash"] = {
		sprite = "item/yumako-mash"
	},
	["jelly"] = {
		sprite = "item/jelly"
	},
	["tree-seed"] = {
		sprite = "item/tree-seed"
	}
}

return {
	SPRITE_MAP = SPRITE_MAP
}
