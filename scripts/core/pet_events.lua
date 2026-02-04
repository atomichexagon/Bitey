local debug = require("scripts.util.debug")
local notifications = require("scripts.util.notifications")
local position = require("scripts.util.position")

local EC = require("scripts.constants.events") -- Event constants.
local BM = require("scripts.constants.biters") -- Pet tier to biter map.


local pet_events = {}

local function process_intro_notification(player_index, entry)
	local now = game.tick
	local player = game.get_player(player_index)

	if not player then
		return
	end

	if not (entry.unit and entry.unit.valid) then
		return
	end

	local pet = entry.unit

	if not (entry.intro_end_tick or entry.intro_pet_alert_threshold) then
		entry.intro_end_tick = now
		local random_delay = now + EC.MININUM_DELAY_BEFORE_PET_SPAWN_AFTER_INTRO + math.random(0, EC.RANDOM_DELAY_PADDING)
		entry.intro_pet_alert_threshold = random_delay
	end

	-- TODO: Change this from an alert to a goal.
	if entry.intro_end_tick and not entry.intro_notification_sent then
		if now > entry.intro_pet_alert_threshold then
			local direction = position.get_direction_of_position(player.position, pet.position)
			notifications.notify(player, pet, {
				type = "entity",
				name = BM[entry.biter_tier_friendly_name].game_eq
			}, "You hear a strange noise coming from the " .. direction .. ".")
			entry.intro_notification_sent = true
		end
	end
end

function pet_events.process_events(player_index, entry)
	process_intro_notification(player_index, entry)
end

function pet_events.record_intro_cinematic_end_tick(player_index, entry)
	local player = game.get_player(player_index)
	if not player then
		return
	end
	if player.controller_type ~= defines.controllers.cutscene then
		entry.intro_end_tick = game.tick
	end

end

function pet_events.create_orphan_force()
	if not game.forces["pet_orphan"] then
		game.create_force("pet_orphan")
	end

	local orphan = game.forces["pet_orphan"]
	local enemy = game.forces["enemy"]
	local player_force = game.forces["player"]

	orphan.set_cease_fire(enemy, true)
	enemy.set_cease_fire(orphan, true)

	orphan.set_cease_fire(player_force, true)
	player_force.set_cease_fire(orphan, true)
end

function pet_events.initialize_storage()
	storage.biter_pet = storage.biter_pet or {}
	storage.pet_spawn_point = storage.pet_spawn_point or nil

	storage.last_mood = storage.last_mood or {}
	storage.emote_state = storage.emote_state or {}
end

return pet_events
