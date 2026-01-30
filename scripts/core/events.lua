local debug = require("scripts.util.debug")
local pet_lifecycle = require("scripts.core.pet_lifecycle")
local pet_state = require("scripts.core.pet_state")
local pet_ai = require("scripts.core.pet_ai")
local pet_spawn = require("scripts.core.pet_spawn")

debug.trace("events", "on_tick fired")

local events = {}

function events.on_init()
    storage.biter_pet = storage.biter_pet or {}
    storage.pet_spawn_point = storage.pet_spawn_point or nil
end

function events.on_load()
    -- Rebind metatables at some point.
end

function events.on_configuration_changed(cfg)
    -- Future migration logic.
end

function events.on_player_created(event)
    local player = game.get_player(event.player_index)
    local entry = pet_lifecycle.get_pet_entry(player.index)
    -- Find a point to spawn the biter at.
    if not storage.pet_spawn_point then
        storage.pet_spawn_point = pet_spawn.choose_orphan_spawn(player.surface,
                                                                player.position)
    end

    -- Spawn the biter.
    pet_spawn.spawn_orphan_baby(player, entry)
end

function events.on_tick(event) pet_lifecycle.on_tick(event) end

function events.on_entity_died(event) pet_lifecycle.on_entity_died(event) end

return events
