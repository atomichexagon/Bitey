local debug = require("scripts.utilities.debug")
local notifications = {}

function notifications.notify(player, entity, icon, message, sound)
	if sound then
		player.play_sound {
			path = sound,
			volume_modifier = 1.0
		}
	end

	local character = player.character
	if character and character.valid then

		local render_id = rendering.draw_text {
			text = message,
			surface = player.surface,
			target = {
				entity = character,
				offset = {
					0.75,
					-1.5
				}
			},
			color = {
				player.color.r,
				player.color.g,
				player.color.b,
				1
			},
			text_align = "center",
			use_rich_text = true,
			scale = 1,
			time_to_live = 300
		}
	end
end

return notifications
