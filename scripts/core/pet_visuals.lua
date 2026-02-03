local debug = require("scripts.util.debug")
local pet_audio = require("scripts.core.pet_audio")
local util = require("util")

local VC = require("scripts.constants.visuals") -- Visuals constants.

local pet_visuals = {}

local EMOTE_MAP = {
	-- General emotes.
	home = {
		sprite = "entity/biter-spawner"
	},
	sleeping = {
		sprite = "virtual-signal/signal-battery-low"
	},
	work = {
		sprite = "virtual-signal/signal-mining"
	},
	investigate = {
		sprite = "virtual-signal/signal-info"
	},
	tired = {
		sprite = "virtual-signal/signal-battery-mid-level"
	},
	alert = {
		sprite = "virtual-signal/signal-alert"
	},
	-- Combat emotes.
	attack = {
		sprite = "item/submachine-gun"
	},
	stay = {
		sprite = "virtual-signal/signal-map-marker"
	},
	biter = {
		sprite = "entity/medium-biter"
	},
	fire = {
		sprite = "virtual-signal/signal-fire"
	},
	defend = {
		sprite = "entity/character"
	},
	patrol = {
		sprite = "virtual-signal/signal-white-flag"
	},
	scared = {
		sprite = "virtual-signal/signal-ghost"
	},
	-- Feeding emotes.
	hungry = {
		sprite = "item/raw-fish"
	},
	thirsty = {
		sprite = "fluid/water"
	},
	morphing = {
		sprite = "virtual-signal/signal-radioactivity"
	},
	-- Boredom emotes.
	bored = {
		sprite = "virtual-signal/signal-hourglass"
	},
	play = {
		sprite = "item/wood"
	},
	mischievous = {
		sprite = "item/explosives"
	},
	confused = {
		sprite = "entity/atomic-bomb-wave"
	},
	-- Sadness emotes.
	ecstatic = {
		sprite = "virtual-signal/signal-skull" -- Placeholder.
	},
	very_happy = {
		sprite = "virtual-signal/signal-skull" -- Placeholder.
	},
	happy = {
		sprite = "virtual-signal/signal-skull" -- Placeholder.
	},
	sad = {
		sprite = "virtual-signal/signal-skull" -- Placeholder.
	},
	crying = {
		sprite = "virtual-signal/signal-skull" -- Placeholder.
	},
	-- Loyalty emotes.
	love = {
		sprite = "virtual-signal/signal-heart"
	},
	gift = {
		sprite = "item/wooden-chest"
	},
	hurt = {
		sprite = "entity/behemoth-biter-die"
	},
	angry = {
		sprite = "fluid/steam"
	}
}

function pet_visuals.emote(player_index, entry, emote, forced)
	local forced = forced or false
	local pet = entry.unit
	local data = EMOTE_MAP[emote]
	local sprite = (data and data.sprite) or emote

	local sprite_render = pet_visuals.show_pet_reaction(player_index, entry, sprite, forced)

	pet_audio.play_for_size(player_index, entry)

	return sprite_render
end

function pet_visuals.show_pet_reaction(player_index, entry, sprite, forced)
	if not (entry and entry.unit and entry.unit.valid) then
		return
	end

	local pet = entry.unit
	if not (pet and pet.valid) then
		return
	end

	local target = {
		entity = pet,
		offset = {0, VC.EMOTE_VERTICAL_OFFSET}
	}

	local sprite_id = rendering.draw_sprite {
		sprite = sprite,
		target = target,
		surface = pet.surface,
		x_scale = VC.EMOTE_SCALE,
		y_scale = VC.EMOTE_SCALE,
		time_to_live = VC.TIME_TO_LIVE_FALLBACK
	}

	local light_id = rendering.draw_light {
		sprite = VC.EMOTE_LIGHT_SPRITE,
		target = target,
		surface = pet.surface,
		intensity = VC.EMOTE_LIGHT_VALUE,
		scale = VC.EMOTE_LIGHT_VALUE,
		time_to_live = VC.TIME_TO_LIVE_FALLBACK
	}

	local sprite_render = {
		sprite = sprite_id,
		light = light_id,
		color = {
			r = 1,
			g = 1,
			b = 1,
			a = 1
		},
		start_tick = game.tick,
		fade = VC.EMOTE_FADE_RATE,
		player_index = player_index,
		entry = entry,
		forced = forced or false
	}

	storage.pet_emote_sprite_queue = storage.pet_emote_sprite_queue or {}
	table.insert(storage.pet_emote_sprite_queue, sprite_render)

	return sprite_render
end

return pet_visuals
