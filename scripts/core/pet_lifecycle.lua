-- TODO: Move some functions out of this file and clean it up.
-- TODO: Add small random chance for biter to investigate entity and pause for a second or two. This should take precedence over everything else.
-- TODO: Player defense may be automatic based on force alliance, but test it out anyway.
-- TODO: Biter should only attack lower weaker biters unless it is behemoth tier.
-- TODO: Biter happiness should go to zero and they should stay by corpse until it is picked up.
local debug = require("scripts.util.debug")
local pet_state = require("scripts.core.pet_state")
local position_util = require("scripts.util.position")
local pet_visuals = require("scripts.core.pet_visuals")
local pet_growth = require("scripts.core.pet_growth")
local pet_spawn = require("scripts.core.pet_spawn")
local notifications = require("scripts.util.notifications")
local pet_events = require("scripts.core.pet_events")
local t = require("scripts.util.text_format")

local DC = require("scripts.constants.debug") -- Debug constants.
local LC = require("scripts.constants.lifecycle") -- Pet lifecycle constants.
local BM = require("scripts.constants.biters") -- Pet tier to biter map.
local TF = require("scripts.constants.text_format") -- Text color constants.

local pet_lifecycle = {}

function pet_lifecycle.get_pet_entry(player_index)
	storage.biter_pet = storage.biter_pet or {}

	if not storage.biter_pet[player_index] then
		storage.biter_pet[player_index] = {
			is_orphaned = true,
			biter_tier = "pet-biter-baby",
			biter_tier_friendly_name = "pet_biter_baby",
			was_alive = true,
			unit = nil
			-- Any other pet lifecycle fields should go here.
		}
	end

	return storage.biter_pet[player_index]
end

local function find_nearest_fish(pet)
	if not (pet and pet.valid) then
		return nil
	end

	local surface = pet.surface
	local pos = pet.position

	-- Detect items on ground near pet.
	local items = surface.find_entities_filtered {
		position = pos,
		radius = LC.FOOD_SEARCH_RADIUS,
		type = "item-entity"
	}

	local nearest = nil
	local best_distance = math.huge

	for _, item in ipairs(items) do
		if item.valid and item.stack and item.stack.name == "raw-fish" then
			local d = position_util.distance(pos, item.position)
			if d < best_distance then
				best_distance = d
				nearest = item
			end
		end
	end

	return nearest
end

local function handle_feeding_behavior(player_index, player, pet, entry)
	local target = pet_state.get_feeding_target(player_index)
	if not (target and target.valid) then
		pet_state.set_feeding_target(player_index, nil)
		return false
	end

	-- The target disappeared.
	if not target then
		pet_state.set_feeding_target(player_index, nil)
		return false
	end

	-- Check if pet is near edible food.
	local dx = pet.position.x - target.position.x
	local dy = pet.position.y - target.position.y
	local dist_sq = dx * dx + dy * dy

	if dist_sq <= (LC.EAT_RADIUS * LC.EAT_RADIUS) then

		-- Stop moving.
		pet.commandable.set_command {
			type = defines.command.stop,
			distraction = defines.distraction.none
		}

		-- Eat the food.
		local amount = target.stack.count
		target.destroy()

		pet_state.ate_good_food(player_index, entry)
		pet_state.set_feeding_target(player_index, nil)
		return true
	end

	-- Otherwise path to the food.
	pet.commandable.set_command {
		type = defines.command.go_to_location,
		destination = target.position,
		radius = LC.EAT_RADIUS * 0.5,
		distraction = defines.distraction.none
	}
	return false
end

function pet_lifecycle.on_tick(event)
	if (event.tick % 30) ~= 0 then
		return
	end

	if not storage.biter_pet then
		return
	end
	for player_index, entry in pairs(storage.biter_pet) do
		pet_lifecycle.process_pet(player_index, entry)
		pet_events.process_events(player_index, entry)
	end
end

function pet_lifecycle.process_pet(player_index, entry)
	local player = game.get_player(player_index)
	if not pet_lifecycle.is_player_valid(player) then
		return
	end

	local pet = pet_lifecycle.ensure_pet(player_index, entry)
	if not pet then
		return
	end

	-- Update hunger value.
	pet_state.tick_pet_state(player_index, entry)

	-- Skip other behaviors if paused.
	if pet_lifecycle.handle_pause(player_index, entry, pet) then
		return
	end

	local target = pet_state.get_feeding_target(player_index)
	pet_lifecycle.evaluate_target(player_index, pet, target)

	local state = pet_state.get_state(player_index)
	if state == "seek_food" then
		pet_lifecycle.state_seek_food(player_index, player, pet, entry)
		return
	end

	-- Lower priority behaviors.
	local state = pet_state.get_state(player_index)
	if state == "idle" then
		pet_lifecycle.state_idle(player_index, player, pet, entry)
	elseif state == "follow" then
		pet_lifecycle.state_follow(player_index, player, pet, entry)
	elseif state == "seek_food" then
		pet_lifecycle.state_seek_food(player_index, player, pet, entry)
		return
	elseif state == "eat" then
		pet_lifecycle.state_eat(player_index, player, pet)
		return
	elseif state == "defend" then
		pet_lifecycle.state_defend(player_index, player, pet)
		return
	end
	pet_state.set_state(player_index, "idle")
	pet_lifecycle.state_idle(player_index, player, pet, entry)
end

function pet_lifecycle.evaluate_target(player_index, pet, target)
	if not (target and target.valid) then
		target = find_nearest_fish(pet)
		if target then
			pet_state.set_feeding_target(player_index, target)
			pet_state.set_state(player_index, "seek_food")
		end
	end
end

function pet_lifecycle.state_idle(player_index, player, pet, entry)
	local distance = position_util.distance(pet.position, player.position)
	local radius = LC.FOLLOW_RADIUS_BY_TIER[pet.name] or LC.PET_FOLLOW_RADIUS
	if distance > radius then
		pet_state.set_state(player_index, "follow")
		return
	end

	local destination = player.position

	if entry.is_orphaned then
		desintation = storage.pet_spawn_point
	end

	pet.commandable.set_command {
		type = defines.command.go_to_location,
		destination = destination,
		radius = radius,
		distraction = defines.distraction.none
	}
end

function pet_lifecycle.is_player_valid(player)
	return player and player.valid and player.character and player.character.valid
end

function pet_lifecycle.ensure_pet(player_index, entry)
	if not (entry.unit and entry.unit.valid) then
		pet_spawn.spawn_pet_for_player(game.get_player(player_index), entry)
		return entry.unit
	end

	local pet = entry.unit
	if not (pet and pet.valid and pet.type == "unit") then
		pet_spawn.spawn_pet_for_player(game.get_player(player_index), entry)
		return entry.unit
	end

	return pet
end

function pet_lifecycle.handle_pause(player_index, entry, pet)
	local paused_now = pet_state.is_paused(player_index)
	local was_paused = entry.was_paused or false

	-- Still paused; skip all behaviors.
	if paused_now then
		debug.info("Pet movement has paused.")
		entry.was_paused = true
		return true
	end

	-- Pause just ended; resume idle behvaior.
	if was_paused and not paused_now then
		entry.was_paused = false
		pet_state.set_state(player_index, "idle")
		debug.info("Pet movement has resumed.")
	end
	return false
end

local function check_for_adoption(player, player_index, pet, entry)
	local hunger = pet_state.get_hunger(player_index)
	if entry.is_orphaned and hunger < LC.BONDING_HUNGER_THRESHOLD then
		if math.random() < LC.CHANCE_TO_ADOPT_BITER then
			entry.is_orphaned = false
			pet.force = player.force
			debug.info("Pet has been successfully adopted.")
			notifications.notify(player, pet, {
				type = "entity",
				name = BM[entry.biter_tier_friendly_name].game_eq
			}, "It seems attached to you now.", "utility/achievement_unlocked")
			return true
		end
	end
end

function pet_lifecycle.state_seek_food(player_index, player, pet, entry)
	local target = pet_state.get_feeding_target(player_index)
	if not (target and target.valid) then
		pet_state.set_state(player_index, "idle")
		return
	end

	local ate = handle_feeding_behavior(player_index, player, pet, entry)

	if ate then
		check_for_adoption(player, player_index, pet, entry)

		-- Growth check happens immediately after eating.
		pet_growth.try_grow(player_index, entry)
		pet_state.pause(player_index, 60)
		pet_state.set_state(player_index, "eat")
		return
	end

	pet.commandable.set_command {
		type = defines.command.go_to_location,
		destination = target.position,
		radius = LC.EAT_RADIUS,
		distraction = defines.distraction.none
	}
end

function pet_lifecycle.state_paused(player_index, player, pet)
	-- Do nothing except idle animation
	pet.commandable.set_command {
		type = defines.command.go_to_location,
		destination = pet.position,
		radius = 0.1,
		distraction = defines.distraction.none
	}

	if not pet_state.is_paused(player_index) then
		pet_state.set_state(player_index, "idle")
	end
end

function pet_lifecycle.state_eat(player_index, player, pet)
	-- Eating is handled in handle_feeding_behavior.
	-- This state exists only to transition into pause.
end

function pet_lifecycle.state_follow(player_index, player, pet, entry)
	-- Determine the target position.
	local target_pos
	if entry.is_orphaned then
		-- Fallback to current position if spawn point is missing to prevent crash.
		target_pos = storage.pet_spawn_point or pet.position
	else
		target_pos = player.position
	end

	-- Calculate distances.
	local distance = position_util.distance(pet.position, target_pos)
	local radius = LC.FOLLOW_RADIUS_BY_TIER[pet.name] or LC.PET_FOLLOW_RADIUS

	-- If close switch to idle.
	if distance <= radius then
		pet_state.set_state(player_index, "idle")
		return
	end

	-- Move toward relevant target.
	pet.commandable.set_command {
		type = defines.command.go_to_location,
		destination = target_pos,
		radius = radius,
		distraction = defines.distraction.by_enemy
	}
end

function pet_lifecycle.on_entity_died(event)
	local entity = event.entity
	if not (entity and entity.valid and entity.type == "unit") then
		return
	end

	for player_index, entry in pairs(storage.biter_pet) do
		if entry.unit == entity then
			debug.info("Pet death event has been triggered.");
			entry.unit = nil
			entry.was_alive = false
			entry.last_death_tick = game.tick -- Record the time of death

			local player = game.get_player(player_index)
			if player then
				notifications.notify(player, pet, {
					type = "entity",
					name = BM[entry.biter_tier_friendly_name].game_eq
				}, "Your faithful companion has died. Perhaps a new friend may appear one day.", "utility/achievement_unlocked")
			end
			break
		end
	end
end

function pet_lifecycle.debug_dump(player)
	-- Valdidate player and pet.
	if not (player and player.valid) then
		game.print(string.format("%s %s", DC.ICON, t.f("No valid player.", "l")))
	end

	storage.biter_pet = storage.biter_pet or {}
	local entry = storage.biter_pet[player.index]

	if not entry then
		game.print(string.format("%s %s", DC.ICON, t.f("No pet entry for player.", "l")))
		return
	end

	local pet = entry.unit
	if not (pet and pet.valid) then
		game.print(string.format("%s %s %s\n", DC.ICON, t.f("Pet is missing or invalid for player:", "l"), t.f(player.index)))
		return
	end

	-- Collect and preformat pet data.
	local position = string.format("[gps=%s,%s]", pet.position.x, pet.position.y)
	local distance = string.format("%.2f", position_util and position_util.distance and
			position_util.distance(pet.position, player.position) or "N/A")
	local h_color = TF.FULL_HEALTH

	if (pet.health and pet.prototype and pet.prototype.get_max_health) then
		if pet.health < pet.prototype.get_max_health() then
			local h_color = TFS.DAMAGED_HEALTH
		end
	end

	local health = string.format("[color=%s]%.1f[/color] | [color=%s]%.1f[/color]", h_color, pet.health or -1,
			TF.FULL_HEALTH, pet.prototype and pet.prototype.get_max_health() or -1)

	-- Final format of alignment of pet data.
	local p_name = string.format("%s %s", t.fm("Tier:", "l"), t.fm(pet.name or "<?>", "m", 1))
	local p_type = string.format("%s %s", t.fm("Type:", "l"), t.fm(pet.type or "<?>", "m", 1))
	local p_position = string.format("%s %s", t.fm("Position:", "l"), t.fm(position, "m", 1))
	local p_distance = string.format("%s %s", t.fm("Distance:", "l"), t.fm(distance, "m", 1))
	local p_health = string.format("%s %s", t.fm("Health:", "l"), t.fm(health, "m", 1))

	return string.format("%s\n%s\n%s\n%s\n%s", p_name, p_type, p_position, p_distance, p_health)
end

return pet_lifecycle
