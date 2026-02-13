local debug = require("scripts.utilities.debug")
local pet_audio = require("scripts.core.pet_audio")
local util = require("util")

local PET_VISUALS_CONSTANTS = require("scripts.constants.visuals")
local RENDER_SETTINGS = PET_VISUALS_CONSTANTS.RENDER_SETTINGS

local SM = require("scripts.constants.sprites")
local SPRITE_MAP = SM.SPRITE_MAP

local pet_visuals = {}

function pet_visuals.emote(player_index, entry, emote, fast_render)
	local pet = entry.unit
	local data = SPRITE_MAP[emote]
	local sprite = (data and data.sprite) or emote

	local sprite_render = pet_visuals.show_pet_reaction(player_index, entry, sprite, fast_render)

	pet_audio.play_for_size(player_index, entry)

	return sprite_render
end

function pet_visuals.show_pet_reaction(player_index, entry, sprite, fast_render)
	local fast_render = fast_render or false
	if not (entry and entry.unit and entry.unit.valid) then return end

	local pet = entry.unit
	if not (pet and pet.valid) then return end

	local target = {
		entity = pet,
		offset = {
			0,
			RENDER_SETTINGS.EMOTE_VERTICAL_OFFSET
		}
	}
	if fast_render then
		debug.trace(string.format("Fast render queued for sprite [img=%s].", sprite))
	else
		debug.trace(string.format("Standard render queued for sprite [img=%s].", sprite))
	end
	
	local sprite_id = rendering.draw_sprite {
		sprite = sprite,
		target = target,
		surface = pet.surface,
		x_scale = RENDER_SETTINGS.EMOTE_SCALE,
		y_scale = RENDER_SETTINGS.EMOTE_SCALE,
		time_to_live = RENDER_SETTINGS.TIME_TO_LIVE_FALLBACK
	}

	local light_id = rendering.draw_light {
		sprite = RENDER_SETTINGS.EMOTE_LIGHT_SPRITE,
		target = target,
		surface = pet.surface,
		intensity = RENDER_SETTINGS.EMOTE_LIGHT_VALUE,
		scale = RENDER_SETTINGS.EMOTE_LIGHT_VALUE,
		time_to_live = RENDER_SETTINGS.TIME_TO_LIVE_FALLBACK
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
		fade = RENDER_SETTINGS.EMOTE_FADE_RATE,
		player_index = player_index,
		entry = entry,
		fast_render = fast_render
	}

	storage.pet_emote_sprite_queue = storage.pet_emote_sprite_queue or {}
	table.insert(storage.pet_emote_sprite_queue, sprite_render)

	return sprite_render
end

return pet_visuals
