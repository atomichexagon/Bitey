-- TODO: Add small random chance for biter to investigate entity while idle and pause for a second or two.
-- This should take precedence over following, eating and sleeping, but not combat or fleeing.
-- TODO: On player death; biter happiness should go to zero if friendship was high.
-- Biter should follow corpse until it is picked up.
-- TODO: Go through project and make sure all functions only used locally are actually local.
-- TODO: Add morph logic and validate spitter evolution.
local debug = require("scripts.utilities.debug")
local notifications = require("scripts.utilities.notifications")
local pet_behavior = require("scripts.core.pet_behavior")
local pet_growth = require("scripts.core.pet_growth")
local pet_reactions = require("scripts.core.pet_reactions")
local pet_spawn = require("scripts.core.pet_spawn")
local pet_state = require("scripts.core.pet_state")
local pet_visuals = require("scripts.core.pet_visuals")
local position_util = require("scripts.utilities.position_util")
local pet_modifiers = require("scripts.core.pet_modifiers")
local pet_state_machine = require("scripts.core.pet_state_machine")

local t = require("scripts.utilities.text_format")

local FD = require("scripts.constants.reactions").FOOD_DEFINITIONS
local BM = require("scripts.constants.biters").BITER_MAP
local DC = require("scripts.constants.debug")
local LC = require("scripts.constants.lifecycle")
local TF = require("scripts.constants.text_format")

local pet_lifecycle = {}

function pet_lifecycle.get_pet_entry(player_index)
	storage.biter_pet = storage.biter_pet or {}

	local entry = storage.biter_pet[player_index]

	-- This table is mainly for pet lifecycle data.
	if not entry then
		entry = {
			intro_notification_sent = false,
			intro_end_tick = nil,
			intro_pet_alert_threshold = nil,
			is_orphaned = true,
			biter_tier = "pet-small-biter-baby",
			was_alive = true,
			unit = nil,
			current_form = "active"
		}
		storage.biter_pet[player_index] = entry
	else
		-- Migration safety.
		entry.intro_notification_sent = entry.intro_notification_sent ~= nil and entry.intro_notification_sent or false
		entry.intro_end_tick = entry.intro_end_tick ~= nil and entry.intro_end_tick or nil
		entry.intro_pet_alert_threshold = entry.intro_pet_alert_threshold ~= nil and entry.intro_pet_alert_threshold or nil
		entry.is_orphaned = entry.is_orphaned ~= nil and entry.is_orphaned or true
		entry.biter_tier = entry.biter_tier or "pet-small-biter-baby"
		entry.was_alive = entry.was_alive ~= nil and entry.was_alive or true
		entry.unit = entry.unit or nil
		entry.current_form = entry.current_form or "active"
	end

	return entry
end

local function set_behavior_state(player_index, pet, entry, behavior)
	if behavior == "idle" then
		pet_state_machine.enter_idle(player_index, pet, entry)
	elseif behavior == "active" then
		pet_state_machine.enter_active(player_index, entry)
	elseif behavior == "sleeping" then
		pet_state_machine.enter_sleep(player_index, entry)
	end
end

local function find_nearest_food(pet)
	if not (pet and pet.valid) then return nil end

	local surface = pet.surface
	local position = pet.position

	-- Detect items on ground near pet.
	local items = surface.find_entities_filtered {
		position = position,
		radius = LC.FOOD_SEARCH_RADIUS,
		type = "item-entity"
	}

	local nearest = nil
	local best_distance_squared = math.huge

	for _, item in ipairs(items) do
		if item.valid and item.stack and item.stack.valid_for_read then
			local name = item.stack.name
			local food_type = FD[name]
			if food_type then
				local distance_squared = position_util.distance_squared(position, item.position)
				if distance_squared < best_distance_squared then
					best_distance_squared = distance_squared
					nearest = item
				end
			end
		end
	end

	return nearest
end

local function handle_feeding_behavior(player_index, player, pet, entry)
	local target = pet_state.get_feeding_target(player_index)
	-- Food disappeared.
	if not (target and target.valid) then
		pet_state.set_feeding_target(player_index, nil)
		return false
	end

	-- Check if pet is near edible food.
	local distance = position_util.distance_squared(pet.position, target.position)

	if distance <= (LC.EAT_RADIUS * LC.EAT_RADIUS) then
		pet.commandable.set_command {
			type = defines.command.stop,
			distraction = defines.distraction.none
		}

		local stack = target.stack
		local food_item = stack.name
		local food = FD[food_item]

		if not food then
			pet_state.set_feeding_target(player_index, nil)
			return false
		end

		-- Eat the food.
		target.destroy()
		pet_modifiers.apply_food_modifiers(player_index, entry, food_item)
		pet_reactions.food_trigger(player_index, entry, food_item)
		pet_state.set_feeding_target(player_index, nil)
		return true
	end

	-- Otherwise path to the food.
	pet.commandable.set_command {
		type = defines.command.go_to_location,
		destination = target.position,
		radius = LC.EAT_RADIUS,
		distraction = defines.distraction.none
	}
	return false
end

-- TODO: Randomize idle state between wandering, pausing and investigating for random intervals.
-- TODO: Ignore follow radius when behaivor is investigate.
local function state_idle(player_index, player, pet, entry)
	if not (pet and pet.valid) then return end

	local radius = LC.FOLLOW_RADIUS_BY_TIER[pet.name] or LC.PET_FOLLOW_RADIUS
	local tether = entry.is_orphaned and (storage.pet_spawn_point or pet.position) or player.position
	local distance_square_to_tether = position_util.distance_squared(pet.position, tether)

	-- Revert back to following if beyond extended idle radius.
	if distance_square_to_tether > (radius * radius * LC.IDLE_RADIUS_MULTIPLIER) then
		pet_state.set_behavior(player_index, "follow")
		return
	end

	-- Get random pathing target within idle radius.
	local idle_target = pet_state.get_idle_target(player_index)

	if not idle_target then
		idle_target = position_util.pick_idle_target(pet.position, tether, radius)
		pet_state.set_idle_target(player_index, idle_target)
	end

	-- Clear idle target and find a new one on the next tick.
	if position_util.distance_squared(pet.position, idle_target) < 1 then
		pet_state.set_idle_target(player_index, nil)
		return
	end

	pet.commandable.set_command {
		type = defines.command.go_to_location,
		destination = idle_target,
		radius = 2,
		distraction = defines.distraction.none
	}

	set_behavior_state(player_index, pet, entry, "idle")
end

local function is_player_valid(player)
	return player and player.valid and player.character and player.character.valid
end

local function state_flee(player_index, player, pet, entry)
	local state = pet_state.get(player_index)
	local emote_state = pet_state.get_queue(player_index)

	if not state.flee_started_at then
		state.fleet_started_at = game.tick
		if emote_state.active_type ~= "forced" then pet_state.force_emote(player_index, entry, "scared") end
	end

	local target = pet_state.get_enemy_target(player_index)

	if not (target and target.valid) then
		pet_state.clear_attack_target(player_index)
		pet_state.set_behavior(player_index, "follow")
		return
	end

	local distance_squared = position_util.distance_squared(pet.position, target.position)
	local safe_distance_squared = (LC.PET_FLEE_SAFE_DISTANCE * LC.PET_FLEE_SAFE_DISTANCE)

	if debug.current_level >= 4 then
		local distance_normalized = position_util.distance(pet.position, target.position)
		local distance_to_escape = LC.PET_FLEE_SAFE_DISTANCE - distance_normalized
		debug.trace(string.format("Fleeing %s tiles to safe distance.", t.f(distance_to_escape, "f")))
	end

	if (distance_squared >= (safe_distance_squared)) then
		debug.info(string.format("Safe distance reached from target %s", t.f(target.name, "f")))
		pet_state.clear_attack_target(player_index)
		pet_state.set_behavior(player_index, "follow")
		pet_modifiers.apply_cowardice_modifiers(player_index, entry)
		pet_reactions.combat_trigger(player_index, entry, "cowardice")
		return
	end

	if target and target.valid then
		pet.commandable.set_command {
			type = defines.command.flee,
			from = target,
			distraction = defines.distraction.by_enemy
		}
	end
end

local function evaluate_target(player_index, pet, target)
	if not (target and target.valid) then
		local hunger = pet_state.get_hunger(player_index)
		local thirst = pet_state.get_thirst(player_index)
		if hunger > LC.SEEK_FOOD_THRESHOLD or thirst > LC.SEEK_WATER_THRESHOLD then
			local feeding_target = find_nearest_food(pet)
			if feeding_target then
				pet_state.set_feeding_target(player_index, feeding_target) -- Fixed variable
				pet_state.set_behavior(player_index, "seek_food")
				debug.render_path_to_target(player_index, pet, feeding_target)
			end
		end
	end
end

local function ensure_pet(player_index, entry)
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

local function handle_pause(player_index, entry, pet)
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
		pet_state.set_behavior(player_index, "idle")
		debug.info("Pet movement has resumed.")
	end
	return false
end

local function biter_was_adopted(player, player_index, pet, entry)
	if not entry.is_orphaned then return false end
	local hunger = pet_state.get_hunger(player_index)
	if (hunger < LC.BONDING_HUNGER_THRESHOLD) then
		if math.random() < LC.CHANCE_TO_ADOPT_BITER then
			pet = entry.unit
			entry.is_orphaned = false
			pet.force = player.force
			pet_state.set_idle_target(player_index, nil)
			debug.info("Pet has been successfully adopted.")
			notifications.notify(player, pet, {
				type = "entity",
				name = BM[entry.biter_tier].base_equivalent
			}, "I think it's starting to trust me...", "utility/achievement_unlocked")
			return true
		end
	end
end

local function state_seek_food(player_index, player, pet, entry)
	local target = pet_state.get_feeding_target(player_index)
	if not (target and target.valid) then
		pet_state.set_behavior(player_index, "idle")
		return
	end

	local pet_ate = handle_feeding_behavior(player_index, player, pet, entry)

	if pet_ate then
		pet_state.pause(player_index, 60)

		if biter_was_adopted(player, player_index, pet, entry) then return end
		if not entry.is_orphaned then if pet_growth.try_grow(player_index, entry) then return end end
		pet_state.set_behavior(player_index, "eat")
		return
	end
end

function pet_lifecycle.state_paused(player_index, player, pet)
	pet.commandable.set_command {
		type = defines.command.go_to_location,
		destination = pet.position,
		radius = 0.1,
		distraction = defines.distraction.none
	}

	if not pet_state.is_paused(player_index) then pet_state.set_behavior(player_index, "idle") end
end

local function state_eat(player_index, player, pet)
	-- Eating is handled in handle_feeding_behavior().
	-- This state exists only to transition into pause.
end

local function state_follow(player_index, player, pet, entry)
	if not (pet and pet.valid) then return end

	-- Determine target position.
	local target_position
	if entry.is_orphaned then
		target_position = storage.pet_spawn_point or pet.position
	else
		target_position = player.position
	end

	local distance_squared = position_util.distance_squared(pet.position, target_position)

	local radius = LC.FOLLOW_RADIUS_BY_TIER[pet.name] or LC.PET_FOLLOW_RADIUS
	if distance_squared <= (radius * radius) then
		pet_state.set_idle_target(player_index, nil)
		pet_state.set_behavior(player_index, "idle")
		return
	end

	set_behavior_state(player_index, pet, entry, "active")
	local entry = storage.biter_pet[player_index]
	pet = entry.unit

	pet.commandable.set_command {
		type = defines.command.go_to_location,
		destination = target_position,
		radius = radius * 0.5,
		distraction = defines.distraction.by_enemy
	}
end

local function find_attack_target(pet, max_distance)
	return pet.surface.find_nearest_enemy {
		position = pet.position,
		max_distance = max_distance,
		force = pet.force
	}
end

local function evaluate_attack_target(player_index, pet, entry)
	local target = pet_state.get_enemy_target(player_index)
	if (target and target.valid) then return target end
	pet_state.clear_attack_target(player_index)
	local new_target = find_attack_target(pet, LC.PET_ATTACK_RADIUS)
	if new_target then
		debug.info(string.format("Pet found new attack target %s", t.f(new_target.name, "f")))
		pet_state.set_attack_target(player_index, new_target)
		pet_state.set_behavior(player_index, "attack")
		pet_state.force_emote(player_index, entry, "attack")
		return new_target
	end
	return nil
end

local function state_attack(player_index, player, pet, entry)
	local target = pet_state.get_enemy_target(player_index)
	if not (target and target.valid) then
		pet_state.clear_attack_target(player_index)
		pet_state.set_behavior(player_index, "follow")
		return
	end

	local pet_health = pet.health or 0
	local target_health = target.health or 0
	local max_health = pet.prototype.get_max_health()

	local pet_should_flee = (pet_health < target_health) and (pet_health / max_health) < LC.PET_FLEE_THRESHOLD
	if LC.PET_IS_SCAREDY_CAT or pet_should_flee then
		pet_state.set_behavior(player_index, "flee")
		return
	end

	pet.commandable.set_command {
		type = defines.command.attack,
		target = target,
		distraction = defines.distraction.by_enemy
	}
end

local function evaluate_tiredness(player_index, pet, entry)
	if not (pet and pet.valid) then return end

	local tiredness = pet_state.get_tiredness(player_index)
	local hunger = pet_state.get_hunger(player_index)
	local thirst = pet_state.get_thirst(player_index)
	local darkness = pet.surface.darkness

	-- TODO: Test sleep cycle.
	-- Wake logic.
	if entry.current_form == "sleeping" then
		if tiredness <= LC.TIREDNESS_WAKE_THRESHOLD or hunger >= LC.HUNGER_WAKE_THRESHOLD or thirst >=
				LC.THIRST_WAKE_THRESHOLD or darkness <= LC.DARKNESS_THRESHOLD then
			debug.trace(string.format("Took process branch %s", t.f("SLEEP", "f")))
			set_behavior_state(player_index, pet, entry, "active")
		end
		return
	end

	-- Sleep logic.
	if entry.current_form == "idle" and tiredness >= LC.TIREDNESS_SLEEP_THRESHOLD and darkness >= LC.DARKNESS_THRESHOLD and
			hunger < LC.HUNGER_WAKE_THRESHOLD and thirst < LC.THIRST_WAKE_THRESHOLD then
		debug.trace(string.format("Took process branch %s", t.f("SLEEP", "f")))
		set_behavior_state(player_index, pet, entry, "sleeping")
		return
	end
end

local function process_pet(player_index, entry)
	local player = game.get_player(player_index)
	if not is_player_valid(player) then return end

	local pet = ensure_pet(player_index, entry)
	if not pet then return end

	-- Sleeping branch.
	if entry.current_form == "sleeping" then
		pet_state.tick_pet_state(player_index, entry)
		evaluate_tiredness(player_index, pet, entry)
		return
	end

	-- Enable debugging visualizers.
	debug.visualize_behavioral_radii(player_index)

	-- Combat branch.
	local behavior = pet_state.get_behavior(player_index)
	if behavior == "flee" then
		debug.trace(string.format("Took process branch %s", t.f("FLEE", "f")))
		state_flee(player_index, player, pet, entry)
		return
	end

	local attack_target = evaluate_attack_target(player_index, pet, entry)
	if attack_target then
		pet_state.set_behavior(player_index, "attack")
		behavior = "attack"
	end

	if behavior == "attack" then
		debug.trace(string.format("Took process branch %s", t.f("ATTACK", "f")))
		state_attack(player_index, player, pet, entry)
		return
	end

	-- Update time-based pet needs.
	pet_state.tick_pet_state(player_index, entry)

	-- Pause branch.
	if handle_pause(player_index, entry, pet) then
		debug.trace(string.format("Took process branch %s", t.f("PAUSE", "f")))
		return
	end

	-- Evaluate sleep needs.
	evaluate_tiredness(player_index, pet, entry)

	-- Feed and follow branch.
	local target = pet_state.get_feeding_target(player_index)
	evaluate_target(player_index, pet, target)

	-- State branching.
	behavior = pet_state.get_behavior(player_index)
	if behavior == "seek_food" then
		debug.trace(string.format("Took process branch %s", t.f("SEEK_FOOD", "f")))
		return state_seek_food(player_index, player, pet, entry)
	elseif behavior == "eat" then
		debug.trace(string.format("Took process branch %s", t.f("EAT", "f")))
		return state_eat(player_index, player, pet)
	elseif behavior == "follow" then
		debug.trace(string.format("Took process branch %s", t.f("FOLLOW", "f")))
		return state_follow(player_index, player, pet, entry)
	elseif behavior == "idle" then
		debug.trace(string.format("Took process branch %s", t.f("IDLE", "f")))
		return state_idle(player_index, player, pet, entry)
	end

	-- Fallback behavior.
	debug.trace(string.format("Took process branch %s", t.f("FALLBACK", "f")))
	pet_state.set_behavior(player_index, "idle")
	state_idle(player_index, player, pet, entry)
end

function pet_lifecycle.on_tick(event)
	if (event.tick % 30) ~= 0 then return end
	if not storage.biter_pet then return end
	for player_index, entry in pairs(storage.biter_pet) do
		process_pet(player_index, entry)
		pet_behavior.process_events(player_index, entry)
	end
end

-- TODO: Change notification depending on whether biter died as orphan, killed by player, age of pet, etc.
-- Record time of adoption and calculate length of companionship.
function pet_lifecycle.on_entity_died(event)
	local entity = event.entity
	if not (entity and entity.valid and entity.type == "unit") then return end

	for player_index, entry in pairs(storage.biter_pet) do
		if entry.unit == entity then
			debug.info("Pet death event has been triggered.");
			local pet = entry.unit
			entry.unit = nil
			entry.was_alive = false
			entry.last_death_tick = game.tick -- Record the time of death.

			local player = game.get_player(player_index)
			if player then
				notifications.notify(player, pet, {
					type = "entity",
					name = BM[entry.biter_tier].base_equivalent
				}, "Your faithful companion has died. Perhaps a new friend may appear one day.", "utility/achievement_unlocked")
			end
			break
		end
	end
end

function pet_lifecycle.debug_dump(player)
	if not (player and player.valid) then return end

	storage.biter_pet = storage.biter_pet or {}
	local entry = storage.biter_pet[player.index]

	if not entry then return end

	local pet = entry.unit
	if not (pet and pet.valid) then return end

	-- Pre-format of pet data.
	local position = string.format("[%s,%s]", pet.position.x, pet.position.y)
	local distance = string.format("%.2f", position_util and position_util.distance and
			position_util.distance_squared(pet.position, player.position) or "N/A")
	local health_color = TF.FULL_HEALTH

	if (pet.health and pet.prototype and pet.prototype.get_max_health) then
		if pet.health < pet.prototype.get_max_health() then local h_color = TFS.DAMAGED_HEALTH end
	end

	local health = string.format("[color=%s]%.1f[/color] | [color=%s]%.1f[/color]", health_color, pet.health or -1,
			TF.FULL_HEALTH, pet.prototype and pet.prototype.get_max_health() or -1)

	-- Final format.
	local pet_name = string.format("%s %s", t.fm("Tier:", "l"), t.fm(pet.name or "<?>", "m", 1))
	local pet_type = string.format("%s %s", t.fm("Type:", "l"), t.fm(pet.type or "<?>", "m", 1))
	local pet_position = string.format("%s %s", t.fm("Position:", "l"), t.fm(position, "m", 1))
	local pet_distance = string.format("%s %s", t.fm("Distance:", "l"), t.fm(distance, "m", 1))
	local pet_health = string.format("%s %s", t.fm("Health:", "l"), t.fm(health, "m", 1))
	return string.format("%s\n%s\n%s\n%s\n%s", pet_name, pet_type, pet_position, pet_distance, pet_health)
end

return pet_lifecycle
