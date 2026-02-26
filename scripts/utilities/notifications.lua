local debug = require("scripts.utilities.debug")
local pet_state = require("scripts.core.pet_state")
local position_util = require("scripts.utilities.position_util")

local LC = require("scripts.constants.lifecycle")
local DC = require("scripts.constants.debug")

local ITG = require("scripts.constants.notifications").INVESTIGATION_FLAVOR_TEXT_GENERAL
local ITS = require("scripts.constants.notifications").INVESTIGATION_FLAVOR_TEXT_SPECIFIC
local FFT = require("scripts.constants.notifications").FETCH_FLAVOR_TEXT
local RFT = require("scripts.constants.notifications").RENAME_FLAVOR_TEXT
local GFG = require("scripts.constants.notifications").GUARD_FLAVOR_TEXT_GENERAL
local GFS = require("scripts.constants.notifications").GUARD_FLAVOR_TEXT_SPECIFIC
local LGT = require("scripts.constants.notifications").LAZY_GUARD_FLAVOR_TEXT
local PFT = require("scripts.constants.notifications").PETTING_FLAVOR_TEXT
local PMS = require("scripts.constants.notifications").PETTING_MODIFIERS_AND_SETTINGS
local FMF = require("scripts.constants.notifications").FOLLOW_ME_FLAVOR_TEXT
local NOS = require("scripts.constants.notifications").NOTIFICATION_SETTINGS
local PSD = require("scripts.constants.notifications").PET_SENSES_DANGER_FLAVOR_TEXT
local PUR = require("scripts.constants.notifications").PICKUP_REMAINS_FLAVOR_TEXT
local PLL = require("scripts.constants.notifications").PICKUP_LONG_LIVED_REMAINS_FLAVOR_TEXT
local PRF = require("scripts.constants.notifications").PLAYER_RESURRECTED_FLAVOR_TEXT

local notifications = {}

local function can_show_flavor(entry)
	local now = game.tick
	entry.last_flavor_tick = entry.last_flavor_tick or 0
	entry.last_petting_reward_tick = entry.last_petting_reward_tick or 0
	local flavor_cooldown = PMS.PETTING_FLAVOR_TEXT_COOLDOWN
	if (now - entry.last_flavor_tick) >= flavor_cooldown then
		entry.last_flavor_tick = now
		return true
	end
	return false
end

function notifications.notify(player, message, sound)
	if not (player and player.valid) then return end
	local character = player.character
	if not (character and character.valid) then return end

	if sound then
		player.play_sound {
			path = sound,
			volume_modifier = 1.0
		}
	end

	local inv = player.get_inventory(defines.inventory.character_armor)
	local armor = inv and inv[1]
	local is_mech = armor and armor.valid_for_read and armor.name == "mech-armor"
	local offset = (is_mech and NOS.MECH_NOTIFICATION_OFFSET) or NOS.PLAYER_NOTIFICATION_OFFSET

	local render_id = rendering.draw_text {
		text = message,
		surface = player.surface,
		target = {
			entity = character,
			offset = offset
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

local function humanize_item_name(item_name)
	if not item_name then return "machine" end
	return item_name:gsub("-", " ")
end

function notifications.investigation_flavor_text(player, entry, item_name)
	if not can_show_flavor(entry) then return end

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

function notifications.rename_pet_flavor_text(player, entry, pet_name)
	if not (player and player.valid) then return end
	if not can_show_flavor(entry) then return end
	local player_index = player.index
	local template = RFT[math.random(#RFT)]
	local message = string.format(template, pet_name)
	pet_state.pause(player_index, 120)
	pet_state.force_emote(player_index, entry, "investigate")
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

	if not can_show_flavor(entry) then return end
	local count = #FFT
	if count == 0 then return end
	local index = (entry.fetch_plays % count) + 1
	local message = FFT[index]
	notifications.notify(player, message)
end

function notifications.player_resurrected_flavor_text(player, entry)
	if not (player and player.valid) then return end
	if not can_show_flavor(entry) then return end
	local message = PRF[math.random(#PRF)]
	notifications.notify(player, message)
end

function notifications.follow_flavor_text(player, entry)
	if not (player and player.valid) then return end
	if not can_show_flavor(entry) then return end
	local message = FMF[math.random(#FMF)]
	notifications.notify(player, message)
end

function notifications.pickup_remains_flavor_text(player, entry)
	if not (player and player.valid) then return end
	if not can_show_flavor(entry) then return end
	
	local length_of_bond = game.tick - entry.birthday_tick
	local special_bond = (length_of_bond >= (LC.MEMORIAL_BOND_THRESHOLD / 2)) or DC.DEBUG_BYPASS_BOND_ELIGIBILITY
	local message

	if special_bond then
		message = PLL[math.random(#PLL)]
	else
		message = PUR[math.random(#PUR)]
	end
	notifications.notify(player, message)
end

function notifications.guard_flavor_text(player, entry)
	if not (player and player.valid) then return end
	if not can_show_flavor(entry) then return end
	local message
	local structure = position_util.get_nearest_player_structure(player)
	if structure and structure.name then
		local structure_name = humanize_item_name(structure.name)
		local template = GFS[math.random(#GFS)]
		message = string.format(template, structure_name)
	else
		message = GFG[math.random(#GFG)]
	end

	notifications.notify(player, message)
end

local function lazy_guard_flavor_text(player, entry)
	if not (player and player.valid) then return end
	if not can_show_flavor(entry) then return end
	local name = entry.pet_given_name or LC.PET_DEFAULT_NAME or "Bitey"
	local message = LGT[math.random(#LGT)]
	notifications.notify(player, message)
end

local function pet_sense_danger_flavor_text(player, entry)
	if not (player and player.valid) then return end
	if not can_show_flavor(entry) then return end
	local raw_message = PSD[math.random(#PSD)]
	local pet_name = entry.pet_given_name or LC.PET_DEFAULT_NAME or "Bitey"
	local message = raw_message:gsub("#NAME#", pet_name)
	notifications.notify(player, message)
end

function notifications.petting_biter_flavor_text(player, entry)
	if not (player and player.valid) then return end

	local player_index = player.index
	local now = game.tick

	local reward_cooldown = PMS.PETTING_REWARD_COOLDOWN
	local can_reward = (now - (entry.last_petting_reward_tick or 0)) >= reward_cooldown

	local affection_emotes = {
		"mischievous",
		"ecstatic",
		"very-happy",
		"happy",
		"love",
		"defend"
	}
	local random_emote = affection_emotes[math.random(#affection_emotes)]
	pet_state.force_emote(player_index, entry, random_emote)

	if can_show_flavor(entry) then
		local message = PFT[math.random(#PFT)]
		notifications.notify(player, message)
	end

	if can_reward then
		pet_state.add_happiness(player_index, PMS.HAPPINESS_BONUS)
		pet_state.add_friendship(player_index, PMS.FRIENDSHIP_BONUS)
		pet_state.add_boredom(player_index, PMS.BOREDOM_BONUS)
		entry.last_petting_reward_tick = now
	end
end

function notifications.process_delayed_commentary(player_index, entry)
	if not entry.delayed_commentary then return end

	local player = game.get_player(player_index)
	if not (player and player.valid) then return end

	local now = game.tick
	local commentary_table = entry.delayed_commentary

	if now >= commentary_table.tick_trigger then
		if commentary_table.commentary == "lazy_guard" then
			lazy_guard_flavor_text(player, entry)
		elseif commentary_table.commentary == "pet_senses_danger" then
			pet_sense_danger_flavor_text(player, entry)
		end
		entry.delayed_commentary = nil
	end
end

return notifications
