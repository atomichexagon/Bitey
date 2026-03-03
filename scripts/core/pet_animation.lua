local debug = require("scripts.utilities.debug")
local pet_state = require("scripts.core.pet_state")

local PET_VISUALS_CONSTANTS = require("scripts.constants.visuals")
local RENDER_SETTINGS = PET_VISUALS_CONSTANTS.RENDER_SETTINGS
local EMOTE_LIGHT_FADE_RATE = RENDER_SETTINGS.EMOTE_LIGHT_FADE_RATE
local EMOTE_FADE_RATE = RENDER_SETTINGS.EMOTE_FADE_RATE
local EMOTE_FORCED_MODIFIER = RENDER_SETTINGS.EMOTE_FORCED_MODIFIER

local pet_animation = {}

function pet_animation.animate_pet_reaction_icon()
	local pet_emote_queue = storage.pet_emote_sprite_queue
	if not pet_emote_queue or #pet_emote_queue == 0 then return end
	for i = #pet_emote_queue, 1, -1 do
		local sprite_render = pet_emote_queue[i]

		if not (sprite_render.sprite and sprite_render.sprite.valid) then
			table.remove(pet_emote_queue, i)
		else
			local age = game.tick - sprite_render.start_tick
			local decremented_value = math.max(0, sprite_render.sprite.color.a - age * EMOTE_FADE_RATE)
			local decremented_light_value = math.max(0,
					sprite_render.light.intensity - age * EMOTE_FADE_RATE)

			if sprite_render.fast_render then
				decremented_value = decremented_value / EMOTE_FORCED_MODIFIER
				decremented_light_value = decremented_light_value / EMOTE_FORCED_MODIFIER
			end

			sprite_render.sprite.color = {
				r = decremented_value,
				g = decremented_value,
				b = decremented_value,
				a = decremented_value
			}

			sprite_render.light.intensity = decremented_light_value
			sprite_render.light.scale = math.max(0.05, decremented_light_value)

			if decremented_value <= 0 then
				table.remove(pet_emote_queue, i)
				pet_state.on_emote_finished(sprite_render.player_index, sprite_render.entry)
			end
		end
	end
end

return pet_animation
