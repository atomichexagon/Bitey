-- TODO: On player death; biter happiness should go to zero if friendship was high.
-- Biter should follow corpse until it is picked up.
local debug = require("scripts.utilities.debug")
local notifications = require("scripts.utilities.notifications")
local pet_behavior = require("scripts.core.pet_behavior")
local pet_birthday = require("scripts.core.pet_birthday")
local pet_growth = require("scripts.core.pet_growth")
local pet_modifiers = require("scripts.core.pet_modifiers")
local pet_morph = require("scripts.core.pet_morph")
local pet_reactions = require("scripts.core.pet_reactions")
local pet_spawn = require("scripts.core.pet_spawn")
local pet_state = require("scripts.core.pet_state")
local pet_state_machine = require("scripts.core.pet_state_machine")
local pet_visuals = require("scripts.core.pet_visuals")
local position_util = require("scripts.utilities.position_util")

local t = require("scripts.utilities.text_format")

local BM = require("scripts.constants.biters").BITER_MAP
local ID = require("scripts.constants.reactions").ITEM_DEFINITIONS
local SS = require("scripts.constants.spawn").SPAWN_SETTINGS
local BG = require("scripts.constants.gifts").BIRTHDAY_GIFTS
local DC = require("scripts.constants.debug")
local LC = require("scripts.constants.lifecycle")
local TF = require("scripts.constants.text_format")

local pet_lifecycle = {}

function pet_lifecycle.peek_pet_entry(player_index)
	local pets = storage.biter_pet
	return pets and pets[player_index] or nil
end

function pet_lifecycle.ensure_pet_entry(player_index)
	storage.biter_pet = storage.biter_pet or {}
	local entry = storage.biter_pet[player_index]

	-- This table is mainly for pet lifecycle data.
	if not entry then
		entry = {
			intro_notification_sent = false,
			is_orphaned = true,
			was_alive = true,

			biter_tier = "pet-small-biter-baby",
			current_form = "active",
			current_species = "biter",
			unit = nil
		}
		storage.biter_pet[player_index] = entry
	else
		-- Lua, your falsy nils have caused be nothing but pain.
		if entry.intro_notification_sent == nil then entry.intro_notification_sent = false end
		if entry.is_orphaned == nil then entry.is_orphaned = true end
		if entry.was_alive == nil then entry.was_alive = true end

		entry.biter_tier = entry.biter_tier or "pet-small-biter-baby"
		entry.current_form = entry.current_form or "active"
		entry.current_species = entry.current_species or "biter"
	end

	return entry
end

function pet_lifecycle.ensure_initial_pet(player_index)
	local player = game.get_player(player_index)
	if not player then return end

	local entry = pet_lifecycle.ensure_pet_entry(player_index)
	if entry.unit and entry.unit.valid then return entry.unit end

	-- Find a suitable position to spawn the biter and nest.
	local generate_decoratives = false
	if not storage.pet_spawn_point then
		storage.pet_spawn_point = pet_spawn.choose_orphan_spawn(player.surface, player.position)
		generate_decoratives = true
	end

	pet_spawn.spawn_orphan_baby(player, entry, generate_decoratives)
	return entry.unit
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

local function find_nearest_interactable_item(player_index, pet, entry)
	if not (pet and pet.valid) then return nil end

	local surface = pet.surface
	local position = pet.position

	-- Find all item entities within search radius.
	local items = surface.find_entities_filtered {
		position = position,
		radius = LC.ITEM_SEARCH_RADIUS,
		type = "item-entity"
	}

	local nearest = nil
	local best_distance_squared = math.huge

	local needs = {
		hunger = pet_state.get_hunger(player_index),
		thirst = pet_state.get_thirst(player_index),
		boredom = pet_state.get_boredom(player_index),
		tiredness = pet_state.get_tiredness(player_index)
	}

	local returnable_item = pet_state.get_returnable_item(player_index)

	-- Return the nearest interactable item.
	for _, item in ipairs(items) do
		if not (item.stack and item.stack.valid_for_read) then goto continue end
		local name = item.stack.name
		if name == returnable_item then goto continue end

		local interactable_item = ID[name]
		if not interactable_item then goto continue end

		local passes_need_check = (not interactable_item.need_check) or interactable_item.need_check(needs)
		if not passes_need_check then goto continue end

		if interactable_item.interaction == "fetch" and entry.is_orphaned then goto continue end

		local distance_squared = position_util.distance_squared(position, item.position)
		if distance_squared < best_distance_squared then
			best_distance_squared = distance_squared
			nearest = item
		end
		::continue::
	end

	return nearest
end

local function handle_item_interaction(player_index, player, pet, entry)
	local target = pet_state.get_item_target(player_index)

	-- Pathing target disappeared.
	if not (target and target.valid) then
		pet_state.clear_item_target(player_index)
		return false
	end

	-- Path toward item until it's within interaction radius.
	local distance = position_util.distance_squared(pet.position, target.position)
	if distance > LC.INTERACT_RADIUS_SQUARED then
		pet.commandable.set_command {
			type = defines.command.go_to_location,
			destination = target.position,
			radius = LC.INTERACT_RADIUS,
			distraction = defines.distraction.none
		}
		return false
	end

	local item_name = target.stack.name

	target.destroy()

	-- Halt pet movement before interaction for visual purposes.
	pet.commandable.set_command {
		type = defines.command.stop,
		distraction = defines.distraction.none
	}

	pet_reactions.process_item_interaction(player_index, pet, entry, item_name)
	return true
end

local function notify_player_of_investigation_if_in_proximity(player, pet, item_name)
	local distance_squared = position_util.distance_squared(player.position, pet.position)
	if distance_squared <= LC.INVESTIGATION_RADIUS_SQUARED then
		notifications.investigation_flavor_text(player, item_name)
	end
end

local function finish_investigation(player_index, player, pet, entry)
	local state = pet_state.get_state(player_index)

	if state.boredom >= 90 then
		local target = entry.investigation_target
		if target and target.valid then
			target.damage(1, pet.force, "physical")
			pet_state.force_emote(player_index, entry, "angry")
		end
	end

	local item_name = entry.investigation_target.name
	notify_player_of_investigation_if_in_proximity(player, pet, item_name)

	local entity_emote = "item/" .. entry.investigation_target.name
	local emotes = LC.INVESTIGATION_EMOTES
	pet_state.force_emote(player_index, entry, entity_emote, true)
	pet_state.force_emote(player_index, entry, emotes[math.random(#emotes)])

	pet_state.pause(player_index, 120)
	entry.investigateing = false
	entry.investigation_target = nil
	pet_state.clear_idle_target(player_index)
end

local function state_investigation(player_index, player, pet, entry)
	local target = entry.investigation_target

	if not (target and target.valid) then
		entry.investigating = false
		entry.investigation_target = nil
		return
	end

	local destination = position_util.get_offset_position(pet, target)

	if position_util.distance_squared(pet.position, destination) < LC.INTERACT_RADIUS_SQUARED then
		finish_investigation(player_index, player, pet, entry)
		return
	end

	pet.commandable.set_command {
		type = defines.command.go_to_location,
		destination = destination,
		radius = 0.5,
		distraction = defines.distraction.none,
		pathfind_flags = {
			allow_paths_through_own_entities = true,
			prefer_straight_paths = true
		}
	}

end

local function orient_towards_investigation_target(pet, target)
	local distance_x = target.position.x - pet.position.x
	local distance_y = target.position.y - pet.position.y
	local angle = math.atan2(distance_y, distance_x)
	local orientation = (angle / (2 * math.pi) + 0.25) % 1
	pet.orientation = orientation
end

local function try_starting_investigation(player_index, player, pet, entry)
	local entities = pet.surface.find_entities_filtered {
		position = pet.position,
		radius = LC.INVESTIGATION_RADIUS,
		force = "player",
		type = LC.INVESTIGATION_TARGETS
	}

	if #entities == 0 then return false end

	local target = entities[math.random(#entities)]

	entry.investigating = true
	entry.investigation_target = target

	pet.commandable.set_command {
		type = defines.command.stop,
		distraction = defines.distraction.none
	}
	orient_towards_investigation_target(pet, target)
	pet_state.pause(player_index, 60)
	pet_state.force_emote(player_index, entry, "investigate")
	return true
end

local function state_idle(player_index, player, pet, entry)
	if not (pet and pet.valid) then return end

	if entry.investigating then
		state_investigation(player_index, player, pet, entry)
		return
	end

	-- Investigate some stuff.
	if math.random() < LC.INVESTIGATION_CHANCE then
		if try_starting_investigation(player_index, player, pet, entry) then return end
	end

	local radius = LC.FOLLOW_RADIUS_BY_TIER[pet.name] or LC.PET_FOLLOW_RADIUS
	local tether = entry.is_orphaned and (storage.pet_spawn_point or pet.position) or player.position
	local distance_squared_to_tether = position_util.distance_squared(pet.position, tether)

	-- Revert back to following if beyond extended idle radius.
	if distance_squared_to_tether > (radius * radius * LC.IDLE_RADIUS_MULTIPLIER) then
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
		pet_state.clear_idle_target(player_index)
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

local function evaluate_target(player_index, pet, entry, target)
	if not (target and target.valid) then
		local item_target = find_nearest_interactable_item(player_index, pet, entry)
		if item_target then
			pet_state.set_item_target(player_index, item_target)
			pet_state.set_behavior(player_index, "seek_item")
			debug.render_path_to_target(player_index, pet, item_target)
		end
	end
end

local function ensure_runtime_pet(player_index, entry)
	local player = game.get_player(player_index)

	if entry.unit and entry.unit.valid then return entry.unit end

	-- Assume if unit is gone but was preivously alive then it's a lost pet.
	if entry.was_alive then
		pet_spawn.spawn_pet_for_player(player_index, player, entry)
		return entry.unit
	end

	-- If pet was legitimately killed then spawn new one after random delay.
	local now = game.tick
	local last_death = entry.last_death_tick or 0

	local remaining = math.floor((SS.ticks_per_day - (now - last_death)) / 60)
	debug.trace(string.format("Pet spawn will trigger in %s seconds.", t.f(remaining, "f")))
	if (now - last_death) >= SS.ticks_per_day or DC.DEBUG_BYPASS_RESPAWN_DELAY then
		debug.info("Spawning replacement orphan.")
		pet_spawn.spawn_orphan_baby(player, entry, false)
		entry.was_alive = true
	end

	return entry.unit
end

local function handle_pause(player_index, entry, pet)
	local paused_now = pet_state.is_paused(player_index)
	local was_paused = entry.was_paused or false

	-- Still paused; skip all behaviors.
	if paused_now then
		pet.commandable.set_command {
			type = defines.command.stop,
			distraction = defines.distraction.none
		}

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
			pet_state.clear_idle_target(player_index)
			debug.info("Pet has been successfully adopted.")
			notifications.notify(player, "I think it's starting to trust me...", "utility/achievement_unlocked")
			return true
		end
	end
end

local function state_seek_item(player_index, player, pet, entry)

	local target = pet_state.get_item_target(player_index)
	if not (target and target.valid) then
		pet_state.set_behavior(player_index, "idle")
		return
	end

	local ate_food = handle_item_interaction(player_index, player, pet, entry)

	if ate_food then
		pet_state.pause(player_index, 60)
		if biter_was_adopted(player, player_index, pet, entry) then return end
		return
	end
end

local function state_eat(player_index, player, pet)
	-- Eating is handled in handle_feeding_behavior().
	-- This state exists only to transition into pause.
end

local function state_follow(player_index, player, pet, entry)
	if not (pet and pet.valid) then return end

	-- Don't follow the player if they're moving around in map view.
	if player.controller_type ~= defines.controllers.character then return end

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
		pet_state.clear_idle_target(player_index)
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
	if DC.DEBUG_SCAREDY_CAT or pet_should_flee then
		pet_state.set_behavior(player_index, "flee")
		return
	end

	pet.commandable.set_command {
		type = defines.command.attack,
		target = target,
		distraction = defines.distraction.by_enemy
	}
end

local function state_return_item(player_index, player, pet, entry)
	local item_name = pet_state.get_returnable_item(player_index)

	if not item_name then
		pet_state.set_behavior(player_index, "idle")
		return
	end

	-- Don't return item if player is not in direct control of player character.
	if player.controller_type ~= defines.controllers.character then return end

	local distance_squared = position_util.distance_squared(pet.position, player.position)
	local drop_position = position_util.get_forward_offset(player, 0.5)
	if distance_squared <= LC.INTERACT_RADIUS_SQUARED then
		player.surface.spill_item_stack {
			position = drop_position,
			stack = item_name,
			enabled_looted = true,
			max_radius = 2
		}
		notifications.fetch_flavor_text(player_index, player, entry, item_name)
		pet_state.set_behavior(player_index, "idle")
		pet_state.pause(player_index, 60)
	end

	pet.commandable.set_command {
		type = defines.command.go_to_location,
		destination = drop_position,
		distraction = defines.distraction.none
	}
end

local function evaluate_tiredness(player_index, pet, entry)
	if not (pet and pet.valid) then return end

	local tiredness = pet_state.get_tiredness(player_index)
	local hunger = pet_state.get_hunger(player_index)
	local thirst = pet_state.get_thirst(player_index)
	local darkness = pet.surface.darkness

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

local function evaluate_returnable_item_state(player_index, player, pet)
	local returnable = pet_state.get_returnable_item(player_index)
	if not returnable then return end
	local items = pet.surface.find_entities_filtered {
		type = "item-entity",
		position = player.position,
		radius = LC.ITEM_SEARCH_RADIUS
	}
	for _, item in ipairs(items) do if item.stack.valid_for_read and item.stack.name == returnable then return end end
	pet_state.set_returnable_item(player_index, nil)
end

local function state_deconstruct_tree(player_index, player, pet, entry)
	local target = pet_state.get_tree_target(player_index)
	if not (target and target.valid) then
		pet_state.clear_tree_target(player_index)
		pet_state.set_behavior(player_index, "idle")
		return
	end

	local distance = position_util.distance_squared(pet.position, target.position)
	if distance > LC.INTERACT_RADIUS_SQUARED then
		pet.commandable.set_command {
			type = defines.command.go_to_location,
			destination = target.position,
			radius = LC.INTERACT_RADIUS,
			distraction = defines.distraction.none
		}
		return
	end

	-- Start choppin'.
	pet.commandable.set_command {
		type = defines.command.attack,
		target = target,
		distraction = defines.distraction.none
	}
end

local function tree_target_in_deconstruct_radius(player_index, player, tree_target)
	local distance_squared = position_util.distance_squared(player.position, tree_target.position)
	if distance_squared > LC.DECONSTRUCTION_RADIUS_SQUARED then return false end
	return true
end

local function evaluate_birthday(player_index, player, entry)
	if not entry.birthday_tick then return end
	if entry.is_orphaned then return end

	local now = game.tick
	if (now - entry.birthday_tick) < SS.ticks_per_year then return end

	pet_birthday.give_birthday_gift(player_index, player, entry)
end

local function process_pet(player_index)

	local player = game.get_player(player_index)
	if not is_player_valid(player) then return end

	local entry = pet_lifecycle.ensure_pet_entry(player_index)
	local pet = ensure_runtime_pet(player_index, entry)
	if not pet then return end

	-- Sleeping branch.
	if entry.current_form == "sleeping" then
		pet_state.tick_pet_state(player_index, entry)
		evaluate_tiredness(player_index, pet, entry)
		return
	end

	-- Enable debugging visualizers.
	debug.visualize_behavioral_radii(player_index)

	evaluate_birthday(player_index, player, entry)

	local behavior = pet_state.get_behavior(player_index)

	-- Return fetched item.
	if behavior == "return_item" then
		debug.trace(string.format("Took process branch %s", t.f("RETURN_ITEM", "f")))
		return state_return_item(player_index, player, pet, entry)
	end

	evaluate_returnable_item_state(player_index, player, pet)
	-- Combat branch.
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

	local state = pet_state.get_state(player_index)
	local tree_target = pet_state.get_tree_target(player_index)
	if tree_target and tree_target.valid then

		if not tree_target_in_deconstruct_radius(player_index, player, tree_target) then
			pet_state.clear_tree_target(player_index)
			pet_state.set_behavior(player_index, "idle")
			return
		end

		if state.last_tree_target ~= tree_target then
			pet_state.force_emote(player_index, entry, "work")
			state.last_tree_target = tree_target
		end

		pet_state.set_behavior(player_index, "deconstruct_tree")
		behavior = "deconstruct_tree"
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
	if behavior ~= "return_item" then
		debug.trace(string.format("Took target evaluation branch %s", t.f("ATTACK", "f")))
		local target = pet_state.get_item_target(player_index)
		evaluate_target(player_index, pet, entry, target)
	end

	-- State branching.
	behavior = pet_state.get_behavior(player_index)
	if behavior == "seek_item" then
		debug.trace(string.format("Took process branch %s", t.f("SEEK_ITEM", "f")))
		return state_seek_item(player_index, player, pet, entry)
	elseif behavior == "deconstruct_tree" then
		debug.trace(string.format("Took process branch %s", t.f("DECONSTRUCT_TREE", "f")))
		return state_deconstruct_tree(player_index, player, pet, entry)
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
		process_pet(player_index)
		pet_behavior.process_events(player_index, entry)
	end
end

function pet_lifecycle.on_entity_died(event)
	local entity = event.entity
	if not (entity and entity.valid) then return end

	if entity.type == "tree" then
		for player_index, entry in pairs(storage.biter_pet) do
			local state = pet_state.get_state(player_index)
			if state.tree_target == entity then
				pet_state.clear_tree_target(player_index)
				state.last_tree_target = nil
				pet_state.set_behavior(player_index, "idle")
			end
		end
		return
	end

	if entity.type ~= "unit" then return end
	for player_index, entry in pairs(storage.biter_pet) do
		if entity == entry.unit then
			debug.info("Pet death event has been triggered.");
			entry.unit = nil
			entry.was_alive = false
			entry.fetch_plays = 0
			-- Record the time of death. 😭
			entry.last_death_tick = game.tick

			pet_state.reset_state_to_defaults(player_index)

			pet_state.clear_attack_target(player_index)
			pet_state.clear_tree_target(player_index)
			pet_state.clear_idle_target(player_index)
			pet_state.clear_item_target(player_index)

			local state = pet_state.get_state(player_index)
			state.last_tree_target = nil
			entry.is_orphaned = true
			entry.current_form = "active"

			local player = game.get_player(player_index)

			-- Check origin of damage.
			if event.force == player.force then
				if player then notifications.notify(player, "I'm a monster...") end
			else
				if player then notifications.notify(player, "No...") end
			end
			return
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
