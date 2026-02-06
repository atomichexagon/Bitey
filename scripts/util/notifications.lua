local debug = require("scripts.util.debug")
local notifications = {}

function notifications.notify(player, entity, icon, message, sound)
	if sound then
		player.play_sound {
			path = sound,
			volume_modifier = 1.0
		}
	end

	debug.info("Alerting player: " .. tostring(message))
	if entity and entity.valid then player.add_custom_alert(entity, icon, message, false) end
end

return notifications
