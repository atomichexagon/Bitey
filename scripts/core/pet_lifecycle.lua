local debug = require("scripts.util.debug")
local pet_state = require("scripts.core.pet_state")
local position_util = require("scripts.util.position")
local pet_visuals = require("scripts.core.pet_visuals")
local pet_growth = require("scripts.core.pet_growth")
local pet_spawn = require("scripts.core.pet_spawn")

local pet_lifecycle = {}

local PET_FOLLOW_RADIUS = 5.0
local FOLLOW_RADIUS_BY_TIER = {
    ["pet-biter-baby"] = 2.0,
    ["pet-biter-small"] = 3.0,
    ["pet-biter-large"] = 5.0
}

local BONDING_HUNGER_THRESHOLD = 20
local FOOD_SEARCH_RADIUS = 10
local EAT_RADIUS = 2

function pet_lifecycle.get_pet_entry(player_index)
    storage.biter_pet = storage.biter_pet or {}

    if not storage.biter_pet[player_index] then
        storage.biter_pet[player_index] = {
            is_orphaned = true,
            biter_tier = "pet-biter-baby",
			was_alive = true,
            unit = nil
            -- Any other pet lifecycle fields should go here.
        }
    end

    return storage.biter_pet[player_index]
end

local function find_nearest_fish(pet)
    if not (pet and pet.valid) then return nil end

    local surface = pet.surface
    local pos = pet.position

    -- Detect items on ground near pet.
    local items = surface.find_entities_filtered {
        position = pos,
        radius = FOOD_SEARCH_RADIUS,
        type = "item-entity"
    }

    local nearest = nil
    local best_dist = math.huge

    for _, item in ipairs(items) do
        if item.valid and item.stack and item.stack.name == "raw-fish" then
            local d = position_util.distance(pos, item.position)
            if d < best_dist then
                best_dist = d
                nearest = item
            end
        end
    end

    return nearest
end

local function handle_feeding_behavior(player_index, player, pet)

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

    if dist_sq <= (EAT_RADIUS * EAT_RADIUS) then

        -- Stop moving.
        pet.commandable.set_command {
            type = defines.command.stop,
            distraction = defines.distraction.none
        }

        -- Eat the food.
        local amount = target.stack.count
        target.destroy()

        pet_state.add_hunger(player_index, -10)
        pet_state.add_loyalty(player_index, 5)
        pet_state.set_feeding_target(player_index, nil)
        return true
    end

    -- Otherwise path to the food.
    pet.commandable.set_command {
        type = defines.command.go_to_location,
        destination = target.position,
        radius = EAT_RADIUS * 0.5,
        distraction = defines.distraction.none
    }
    return false
end

function pet_lifecycle.on_tick(event)
    if (event.tick % 30) ~= 0 then return end
    if not storage.biter_pet then return end

    for player_index, entry in pairs(storage.biter_pet) do
        pet_lifecycle.process_pet(player_index, entry)
    end
end

function pet_lifecycle.process_pet(player_index, entry)
    local player = game.get_player(player_index)
    if not pet_lifecycle.is_player_valid(player) then return end

    local pet = pet_lifecycle.ensure_pet(player_index, entry)
    if not pet then return end

    -- Update hunger value.
    pet_state.tick_hunger(player_index)

    -- Skip other behaviors if paused.
    if pet_lifecycle.handle_pause(player_index, entry, pet) then return end

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
    local dist = position_util.distance(pet.position, player.position)
    local radius = FOLLOW_RADIUS_BY_TIER[pet.name] or PET_FOLLOW_RADIUS
    if dist > radius then
        pet_state.set_state(player_index, "follow")
        return
    end

    local destination = player.position

    if entry.is_orphaned then desintation = storage.pet_spawn_point end
    -- Resume idle behavior.
    -- pet.commandable.set_command {
    --     type = defines.command.wander,
    --     radius = 4,
    --     distraction = defines.distraction.none
    -- }
    -- Resume idle behvaior.
    pet.commandable.set_command {
        type = defines.command.go_to_location,
        destination = destination,
        radius = radius,
        distraction = defines.distraction.none
    }
end

function pet_lifecycle.is_player_valid(player)
    return player and player.valid and player.character and
               player.character.valid
end

-- I don't even remember why this function exists?
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
        debug.info("pet_lifecycle", "Pet is paused, skipping movement.")
        entry.was_paused = true
        return true
    end

    -- Pause just ended; resume idle behvaior.
    if was_paused and not paused_now then
        debug.info("pet_lifecycle", "Resuming pet movement.")
        entry.was_paused = false
        pet_state.set_state(player_index, "idle")
        debug.info("pet_lifecycle", "Pause ended, returning to idle.")
    end
    return false
end

function pet_lifecycle.state_seek_food(player_index, player, pet, entry)
    local target = pet_state.get_feeding_target(player_index)
    if not (target and target.valid) then
        pet_state.set_state(player_index, "idle")
        return
    end

    local ate = handle_feeding_behavior(player_index, player, pet)

    if ate then
        local hunger = pet_state.get_hunger(player_index)
        if entry.is_orphaned and hunger < BONDING_HUNGER_THRESHOLD then
            entry.is_orphaned = false
            debug.info("pet_lifecycle",
                       "Pet is now unorphaned: entry.is_orphaned = " ..
                           tostring(entry.is_orphaned))
            pet_visuals.show_pet_reaction(pet, "♥")
        else
			local opts = {color = {r = 1, g = 1, b = 0, a = 1.0}}
            pet_visuals.show_pet_reaction(pet, "!", opts)
        end

        -- Growth check happens immediately after eating.
        pet_growth.try_grow(player_index, entry)
        pet_state.pause(player_index, 60)
        pet_state.set_state(player_index, "eat")
        return
    end

    pet.commandable.set_command {
        type = defines.command.go_to_location,
        destination = target.position,
        radius = EAT_RADIUS,
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
    -- 1. Determine the target position
    local target_pos
    if entry.is_orphaned then
        -- Fallback to current position if spawn point is missing to prevent crash
        target_pos = storage.pet_spawn_point or pet.position
    else
        target_pos = player.position
    end

    -- 2. Calculate distances
    local dist = position_util.distance(pet.position, target_pos)
    local radius = FOLLOW_RADIUS_BY_TIER[pet.name] or PET_FOLLOW_RADIUS

    -- 3. If close enough, switch to idle
    if dist <= radius then
        pet_state.set_state(player_index, "idle")
        return
    end

    -- 4. Move toward the relevant target
    pet.commandable.set_command {
        type = defines.command.go_to_location,
        destination = target_pos,
        radius = radius,
        distraction = defines.distraction.by_enemy
    }
end

function pet_lifecycle.on_entity_died(event)
    debug.info("pet_lifecycle", "on_entity_died fired");

    local entity = event.entity
    if not (entity and entity.valid and entity.type == "unit") then return end

    for player_index, entry in pairs(storage.biter_pet) do
        if entry.unit == entity then
            entry.unit = nil
            entry.was_alive = false
            entry.last_death_tick = game.tick -- Record the time of death

            local player = game.get_player(player_index)
            if player then
                player.print(
                    "Your loyal companion has died. A new orphan may appear one day.")
            end
            break
        end
    end
end

function pet_lifecycle.print_status_for_players(player)
    if not (player and player.valid) then game.print("[BP] No valid player.") end

    storage.biter_pet = storage.biter_pet or {}
    local entry = storage.biter_pet[player.index]

    if not entry then
        game.print("[BP] No pet entry for player.")
        return
    end

    local pet = entry.unit
    if not (pet and pet.valid) then
        game.print("[BP] Pet is missing or invalid for player: " .. player.index)
        return
    end

    local dist = position_util and position_util.distance and
                     position_util.distance(pet.position, player.position) or
                     "n/a"

    game.print(string.format(
                   "[BP] Pet status for player %d: name=%s, type=%s, pos=(%.2f,%.2f), dist=%.2f, health=%.1f/%.1f",
                   player.index, pet.name or "<?>", pet.type or "<?>",
                   pet.position.x, pet.position.y, tostring(dist),
                   pet.health or -1,
                   pet.prototype and pet.prototype.get_max_health() or -1))
end

return pet_lifecycle
