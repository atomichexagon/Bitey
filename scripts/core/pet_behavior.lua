local debug = require("scripts.util.debug")
local notifications = require("scripts.util.notifications")
local position_util = require("scripts.util.position_util")
local audio = require("scripts.util.audio")
local pet_state = require("scripts.core.pet_state")
local EVENT_SETTINGS = require("scripts.constants.events")
local BITER_CONSTANTS = require("scripts.constants.biters")
local BITER_MAP = BITER_CONSTANTS.BITER_MAP

local pet_behavior = {}

local function process_intro_notification(player_index, entry)
	local now = game.tick
	local player = game.get_player(player_index)
	if not player then return end

	if not (entry.unit and entry.unit.valid) then return end
	local pet = entry.unit

	if not entry.intro_end_tick or not entry.intro_pet_alert_threshold then
		entry.intro_end_tick = now
		local random_delay = now + EVENT_SETTINGS.MININUM_DELAY_BEFORE_PET_SPAWN_AFTER_INTRO +
				                     math.random(0, EVENT_SETTINGS.RANDOM_DELAY_PADDING)
		entry.intro_pet_alert_threshold = random_delay
	end

	if entry.intro_end_tick and not entry.intro_notification_sent then
		if now > entry.intro_pet_alert_threshold then
			local direction = position_util.get_direction_of_position(player.position, pet.position)
			notifications.notify(player, pet, {
				type = "entity",
				name = BITER_MAP[entry.biter_tier].base_equivalent
			}, string.format("I heard a scream to the %s...", direction))
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
			debug.info(string.format("%s %s", "Pet thirst attribute unlocked for player", t.f(player.index, "f")))
			local s = pet_state.ensure_state(player.index)
			s.has_fluid_handling = true
		end
	end
end

return pet_behavior
