local debug = require("scripts.util.debug")
local pet_state = require("scripts.core.pet_state")

local PET_VISUALS_CONSTANTS = require("scripts.constants.visuals")
local RENDER_SETTINGS = PET_VISUALS_CONSTANTS.RENDER_SETTINGS

local pet_animation = {}

function pet_animation.animate_pet_reaction_icon()
	-- Pet reaction animations and lighting.
	if game.tick % 2 ~= 0 then return end

	local pesq = storage.pet_emote_sprite_queue

	if not pesq or #pesq == 0 then return end

	for i = #pesq, 1, -1 do
		local sprite_render = pesq[i]

		if not (sprite_render.sprite and sprite_render.sprite.valid) then
			table.remove(pesq, i)
		else
			local age = game.tick - sprite_render.start_tick
			local dec_value = math.max(0, sprite_render.sprite.color.a - age * RENDER_SETTINGS.EMOTE_FADE_RATE)
			local dec_l_value = math.max(0, sprite_render.light.intensity - age * RENDER_SETTINGS.EMOTE_LIGHT_FADE_RATE)

			if sprite_render.fast_render then
				dec_value = dec_value / RENDER_SETTINGS.EMOTE_FORCED_MODIFIER
				dec_l_value = dec_l_value / RENDER_SETTINGS.EMOTE_FORCED_MODIFIER
			end

			-- Don't touch this again or you'll be here for hours.
			sprite_render.sprite.color = {
				r = dec_value,
				g = dec_value,
				b = dec_value,
				a = dec_value
			}

			-- sprite_render.sprite.color = sprite_render.color
			sprite_render.light.intensity = dec_l_value
			sprite_render.light.scale = math.max(0.05, dec_l_value)

			-- Destroy sprite and light source if they're invisible.
			if dec_value <= 0 then
				table.remove(pesq, i)
				pet_state.on_emote_finished(sprite_render.player_index, sprite_render.entry)
			end
		end
	end
end

return pet_animation
