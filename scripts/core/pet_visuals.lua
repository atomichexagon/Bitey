local debug = require("scripts.utilities.debug")
local pet_audio = require("scripts.core.pet_audio")
local util = require("util")

local t = require("scripts.utilities.text_format")
local RS = require("scripts.constants.visuals").RENDER_SETTINGS
local SM = require("scripts.constants.sprites").SPRITE_MAP

local pet_visuals = {}

local function try_draw_sprite(sprite, target, pet)
	return pcall(function()
		return rendering.draw_sprite {
			sprite = sprite,
			target = target,
			surface = pet.surface,
			x_scale = RS.EMOTE_SCALE,
			y_scale = RS.EMOTE_SCALE,
			time_to_live = RS.TIME_TO_LIVE_FALLBACK
		}
	end)
end

local function try_draw_animation(animation, target, pet)
	return pcall(function()
		return rendering.draw_animation {
			animation = animation,
			target = target,
			surface = pet.surface,
			x_scale = RS.EMOTE_SCALE,
			y_scale = RS.EMOTE_SCALE,
			time_to_live = RS.TIME_TO_LIVE_FALLBACK
		}
	end)
end

local function show_pet_reaction(player_index, entry, emote_data, fast_render)
	local fast_render = fast_render or false
	if not (entry and entry.unit and entry.unit.valid) then return end

	local pet = entry.unit
	if not (pet and pet.valid) then return end

	local y_offset = (emote_data.animated and RS.EMOTE_ANIMATED_OFFSET) or RS.EMOTE_VERTICAL_OFFSET
	local target = {
		entity = pet,
		offset = {
			0,
			y_offset
		}
	}

	local render_id
	local successful
	if emote_data.animated then
		successful, render_id = try_draw_animation(emote_data.animation, target, pet)
	else
		successful, render_id = try_draw_sprite(emote_data.sprite, target, pet)
	end

	if not successful then
		-- Error rendering emote.
		return
	end

	local color = (entry.current_form == "sleeping" and RS.EMOTE_SLEEPING_LIGHT_COLOR) or RS.EMOTE_WAKING_LIGHT_COLOR
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
		sprite = render_id,
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

function pet_visuals.emote(player_index, entry, emote, fast_render)
	local pet = entry.unit

	local data = SM[emote]
	if not data then return end

	local sprite_render = show_pet_reaction(player_index, entry, data, fast_render)

	pet_audio.play_for_size(player_index, entry)

	return sprite_render
end

return pet_visuals
