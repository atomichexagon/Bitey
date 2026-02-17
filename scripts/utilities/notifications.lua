local debug = require("scripts.utilities.debug")
local pet_state = require("scripts.core.pet_state")

local ITG = require("scripts.constants.notifications").INVESTIGATION_FLAVOR_TEXT_GENERAL
local ITS = require("scripts.constants.notifications").INVESTIGATION_FLAVOR_TEXT_SPECIFIC
local FT = require("scripts.constants.notifications").FETCH_FLAVOR_TEXT

local notifications = {}

function notifications.notify(player, message, sound)
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

local function humanize_item_name(item_name)
	if not item_name then return "machine" end
	return (item_name:gsub("-", " "))
end

function notifications.investigation_flavor_text(player, item_name)
	if math.random() < 0.5 or not item_name then
		local message = ITG[math.random(#ITG)]
		notifications.notify(player, message)
		return		
	end
	local formatted_item_name = humanize_item_name(item_name)
	local template = ITS[math.random(#ITS)]
	local message = string.format(template, formatted_item_name)
	notifications.notify(player, message)
end

function notifications.fetch_flavor_text(player_index, player, entry, item_name)
	if item_name ~= "wood" then
		pet_state.add_happiness(player_index, 25)
		pet_state.force_emote(player_index, entry, "ecstatic", true)
		pet_state.force_emote(player_index, entry, "gift", false)
		notifications.notify(player, "Wow! Has it been a year already?", "utility/achievement_unlocked")
		return
	end

	local count = #FT
	if count == 0 then return end
	local index = (entry.fetch_plays % count) + 1
	local message = FT[index]
	notifications.notify(player, message)
end

return notifications
