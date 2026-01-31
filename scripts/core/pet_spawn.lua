local debug = require("scripts.util.debug")

local SC = require("scripts.constants.spawn") -- Pet spawn constants.

local pet_spawn = {}

function pet_spawn.choose_orphan_spawn(surface, origin)
    for i = 1, 60 do
        local angle = math.random() * math.pi * 2
        local dist = SC.MINIMUM_SPAWN_DISTANCE + math.random() ^ 0.5 *
                         SC.MAXIMUM_SPAWN_OFFSET

        local pos = {
            x = origin.x + math.cos(angle) * dist,
            y = origin.y + math.sin(angle) * dist
        }

        -- Check if the chunk is actually generated before looking at tiles.
        if surface.is_chunk_generated({pos.x / 32, pos.y / 32}) then
            if not surface.get_tile(pos).collides_with("water_tile") then

                -- Attempt to find a valid spot for the baby biter.
                local valid = surface.find_non_colliding_position(
                                  "pet-biter-baby", pos, SC.SPAWN_SEARCH_RADIUS,
                                  SC.SEARCH_PRECISION)

                if valid then return valid end
            end
        end
    end

    -- Fallback: Spawn closer if the outer edge is blocked for whatever reason.
    return
        surface.find_non_colliding_position("pet-biter-baby", origin, 20, 1) or
            origin
end

function pet_spawn.spawn_orphan_baby(player, entry)
    local surface = player.surface

    if not storage.pet_spawn_point then
        storage.pet_spawn_point = pet_spawn.choose_orphan_spawn(surface,
                                                                player.position)
    end

    -- Safety: ensure the tile is walkable
    local pos = surface.find_non_colliding_position("pet-biter-baby",
                                                    storage.pet_spawn_point, 10,
                                                    0.5)

    if not pos then
        debug.info("pet_spawn",
                   "Could not find a valid spawn location for the orphaned baby biter.")
        return
    end

    local pet = surface.create_entity {
        name = "pet-biter-baby",
        position = pos,
        force = player.force
    }
    pet.ai_settings.allow_destroy_when_commands_fail = false
    pet.ai_settings.allow_try_return_to_spawner = false

    entry.unit = pet
    entry.is_orphaned = true
    entry.biter_tier = "pet-biter-baby" -- Reset pet tier for new orphans.
    debug.info("pet_spawn",
               "Orphaned baby biter spawned at: " .. serpent.line(pos))
end

function pet_spawn.spawn_pet_for_player(player, entry)
    local player_index = player.index
    local current_tick = game.tick

    -- 1. Check if the biter should have been alive but is missing (Despawn/Bug recovery)
    -- We assume if entry.unit is nil but entry.was_alive was true, it's a "lost" pet.
    if entry.was_alive and (not entry.unit or not entry.unit.valid) then
        local tier = entry.biter_tier or "pet-biter-baby"
        local pos = player.surface.find_non_colliding_position(tier,
                                                               player.position,
                                                               15, 0.5)

        if pos then
            entry.unit = player.surface.create_entity {
                name = tier,
                position = pos,
                force = player.force
            }
            debug.info("pet_spawn", "Recovered lost pet of tier: " .. tier)
            return
        end
    end

    -- 2. If the biter is dead (legitimately), check the one-day cooldown
    if not (entry.unit and entry.unit.valid) then
        entry.was_alive = false

        local last_death = entry.last_death_tick or 0
        if (current_tick - last_death) >= SC.TICKS_PER_DAY then
            pet_spawn.spawn_orphan_baby(player, entry)
            entry.was_alive = true
        else
            local remaining = math.floor((SC.TICKS_PER_DAY -
                                             (current_tick - last_death)) / 60)
            debug.info("pet_spawn",
                       "Waiting for next spawn cycle. Seconds remaining: " ..
                           remaining)
        end
    end
end

return pet_spawn
