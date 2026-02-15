local audio = require("scripts.utilities.audio")
local debug = require("scripts.utilities.debug")
local notifications = require("scripts.utilities.notifications")
local pet_modifiers = require("scripts.core.pet_modifiers")
local pet_state = require("scripts.core.pet_state")
local position_util = require("scripts.utilities.position_util")
local t = require("scripts.utilities.text_format")

local BM = require("scripts.constants.biters").BITER_MAP
local BT = require("scripts.constants.thresholds").BEHAVIORAL_THRESHOLDS
local ES = require("scripts.constants.events")

local pet_behavior = {}

local function process_intro_notification(player_index, entry)
	local now = game.tick
	local player = game.get_player(player_index)
	if not player then return end

	if not (entry.unit and entry.unit.valid) then return end
	local pet = entry.unit

	if not entry.intro_end_tick or not entry.intro_pet_alert_threshold then
		entry.intro_end_tick = now
		local random_delay = now + ES.MININUM_DELAY_BEFORE_PET_SPAWN_AFTER_INTRO + math.random(0, ES.RANDOM_DELAY_PADDING)
		entry.intro_pet_alert_threshold = random_delay
	end

	if entry.intro_end_tick and not entry.intro_notification_sent then
		if now > entry.intro_pet_alert_threshold then
			local direction = position_util.get_direction_of_position(player.position, pet.position)
			if direction then
				notifications.notify(player, string.format("I heard a scream to the %s...", direction))
			end
			entry.intro_notification_sent = true
			audio.play_global_sound(player, "death-rattle")
			player.force.chart(pet.surface, {
				{
					pet.position.x - 4,
					pet.position.y - 4
				},
				{
					pet.position.x + 4,
					pet.position.y + 4
				}
			})
			player.force.add_chart_tag(pet.surface, {
				position = pet.position,
				icon = {
					type = "virtual",
					name = "signal-deny"
				}
			})
		end
	end
end

function pet_behavior.process_events(player_index, entry)
	process_intro_notification(player_index, entry)
end

function pet_behavior.record_intro_cinematic_end_tick(player_index, entry)
	local player = game.get_player(player_index)
	if not player then return end
	if player.controller_type ~= defines.controllers.cutscene then entry.intro_end_tick = game.tick end
end

function pet_behavior.on_research_finished(event)
	local tech = event.research
	if tech.name == "fluid-handling" then
		for _, player in pairs(tech.force.players) do
			if player and player.valid and player.connected then
				debug.info(string.format("%s %s", "Pet thirst unlocked for player", t.f(player.index, "f")))
				local state = pet_state.get_state(player.index)
				state.has_fluid_handling = true
			end
		end
	end
end

function pet_behavior.on_pet_damaged(player_index, entry, event)
	local state = pet_state.get_state(player_index)
	local player = game.get_player(player_index)

	state.attack_target = player.character
	pet_state.set_behavior(player_index, "flee")

	if entry.current_form == "sleeping" then
		pet_state.set_behavior(player_index, "active")
		pet_state.force_emote(player_index, entry, "angry")
	end

	local attacker_force = event.force
	if attacker_force ~= player.force then return end

	-- Evaluate friendly-fire.
	local maximum_health = entry.unit.prototype.get_max_health()
	local current_health = entry.unit.health
	local damage = event.final_damage_amount

	local is_full_health = (current_health >= maximum_health)
	local damage_insignificant = (damage <= maximum_health * 0.1)

	if state.friendship < BT.friendship_total_betrayal then
		pet_modifiers.apply_friendly_fire_modifiers(player_index, entry, "total_betrayal")
		pet_state.force_emote(player_index, entry, "angry")
		pet_state.switch_to_enemy_force(player_index, entry)
	elseif state.friendship < BT.friendship_mild_betrayal then
		pet_modifiers.apply_friendly_fire_modifiers(player_index, entry, "mild_betrayal")
		pet_state.force_emote(player_index, entry, "very_sad")
	elseif state.friendship >= BT.friendship_playing_dead and is_full_health and damage_insignificant then
		pet_modifiers.apply_friendly_fire_modifiers(player_index, entry, "playing_dead")
		pet_state.force_emote(player_index, entry, "playing_dead")
		pet_state.force_emote(player_index, entry, "silly")
	else
		pet_modifiers.apply_friendly_fire_modifiers(player_index, entry, "betrayal")
		pet_state.force_emote(player_index, entry, "scared")
	end
end

return pet_behavior
