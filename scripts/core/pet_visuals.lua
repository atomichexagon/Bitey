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
		sprite = "virtual-signal/signal-mining",
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
		sprite = "virtual-signal/signal-fire",
	},
	defend = {
		sprite = "entity/character"
	},
	patrol = {
		sprite = "virtual-signal/signal-white-flag",
	},
	scared = {
		sprite = "virtual-signal/signal-ghost",
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
		sprite = "virtual-signal/signal-hourglass",
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

function pet_visuals.emote(player_index, entry, key, play_audio)
	local pa = play_audio or true
	local pet = entry.unit
	local data = EMOTE_MAP[key]
	local sprite = (data and data.sprite) or key

	local render_id = pet_visuals.show_pet_reaction(pet, sprite, color)

	if pa then
		pet_audio.play_for_size(player_index, entry)
	end

	return render_id
end

function pet_visuals.emote(player_index, entry, key, play_audio)
	sprite = "bored"
	local pa = play_audio or true
	local pet = entry.unit
	local data = EMOTE_MAP[key]
	local sprite = (data and data.sprite) or key

	local render_id = pet_visuals.show_pet_reaction(pet, sprite)

	if pa then
		-- Assuming pet_audio handles its own player scope as discussed earlier
		pet_audio.play_for_size(player_index, entry)
	end

	return render_id
end

function pet_visuals.show_pet_reaction(pet, sprite)
	if not (pet and pet.valid) then
		return
	end

	local target = {
		entity = pet,
		offset = {0, VC.EMOTE_VERTICAL_OFFSET}
	}

	local render_id = rendering.draw_sprite {
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

	storage.pet_emote_sprite_queue = storage.pet_emote_sprite_queue or {}
	table.insert(storage.pet_emote_sprite_queue, {
		id = render_id,
		light_id = light_id,
		target = target,
		pet = pet,
		start_tick = game.tick
	})

	return render_id
end

function pet_visuals.animate_pet_reaction_icon()
	-- Pet reaction animations and lighting.
	if game.tick % 5 ~= 0 then
		return
	end

	local pesq = storage.pet_emote_sprite_queue

	if not pesq or #pesq == 0 then
		return
	end

	for i = #pesq, 1, -1 do
		local sprite_render = pesq[i]

		if not (sprite_render.id and sprite_render.id.valid) then
			table.remove(pesq, i)
		else
			local age = game.tick - sprite_render.start_tick
			local dec_value = math.max(0, sprite_render.id.color.a - age * VC.EMOTE_FADE_RATE)
			local dec_l_value = math.max(0, sprite_render.light_id.intensity - age * VC.EMOTE_LIGHT_FADE_RATE)

			-- Don't fuck with this again or you'll be here for hours.
			-- If you're forking this mod, you should also not fuck with it.
			-- The fade will only happen if you decrement every value in the rgba table.
			sprite_render.color = {
				r = dec_value,
				g = dec_value,
				b = dec_value,
				a = dec_value
			}

			sprite_render.id.color = sprite_render.color
			sprite_render.light_id.intensity = dec_l_value
			sprite_render.light_id.scale = math.max(0.05, dec_l_value)


			-- Destroy sprite and light source if they're invisible.
			if dec_value <= 0 then
				sprite_render.id.destroy()
				sprite_render.light_id.destroy()
				table.remove(pesq, i)
			end
		end
	end
end

return pet_visuals
