local debug = require("scripts.utilities.debug")
local pet_audio = require("scripts.core.pet_audio")
local util = require("util")

local RS = require("scripts.constants.visuals").RENDER_SETTINGS
local SM = require("scripts.constants.sprites").SPRITE_MAP

local pet_visuals = {}

local function show_pet_reaction(player_index, entry, sprite, fast_render, behavior)
	local fast_render = fast_render or false
	if not (entry and entry.unit and entry.unit.valid) then return end

	local pet = entry.unit
	if not (pet and pet.valid) then return end

	local target = {
		entity = pet,
		offset = {
			0,
			RS.EMOTE_VERTICAL_OFFSET
		}
	}

	local debug_descriptor = (fast_render and "Fast render") or "Standard render"
	debug.trace(string.format("%s queued for sprite [img=%s].", debug_descriptor, sprite))

	local sprite_id = rendering.draw_sprite {
		sprite = sprite,
		target = target,
		surface = pet.surface,
		x_scale = RS.EMOTE_SCALE,
		y_scale = RS.EMOTE_SCALE,
		time_to_live = RS.TIME_TO_LIVE_FALLBACK
	}

	local color = (behavior == "sleeping" and RS.EMOTE_SLEEPING_LIGHT_COLOR) or RS.EMOTE_WAKING_LIGHT_COLOR
	local light_id = rendering.draw_light {
		sprite = RS.EMOTE_LIGHT_SPRITE,
		target = target,
		color = color,
		surface = pet.surface,
		intensity = RS.EMOTE_LIGHT_VALUE,
		scale = RS.EMOTE_LIGHT_VALUE,
		time_to_live = RS.TIME_TO_LIVE_FALLBACK
	}

	local sprite_render = {
		sprite = sprite_id,
		light = light_id,
		color = {
			r = 255,
			g = 255,
			b = 255,
			a = 255
		},
		start_tick = game.tick,
		fade = RS.EMOTE_FADE_RATE,
		player_index = player_index,
		entry = entry,
		fast_render = fast_render
	}

	storage.pet_emote_sprite_queue = storage.pet_emote_sprite_queue or {}
	table.insert(storage.pet_emote_sprite_queue, sprite_render)

	return sprite_render
end

function pet_visuals.emote(player_index, entry, emote, fast_render, behavior)
	local pet = entry.unit
	local data = SM[emote]
	local sprite = (data and data.sprite) or emote

	local sprite_render = show_pet_reaction(player_index, entry, sprite, fast_render, behavior)

	pet_audio.play_for_size(player_index, entry)

	return sprite_render
end

return pet_visuals
