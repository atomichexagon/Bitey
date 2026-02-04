local debug = require("scripts.util.debug")
local pet_lifecycle = require("scripts.core.pet_lifecycle")
local pet_state = require("scripts.core.pet_state")
local pet_spawn = require("scripts.core.pet_spawn")
local pet_events = require("scripts.core.pet_events")
local pet_visuals = require("scripts.core.pet_visuals")
local pet_animation = require("scripts.core.pet_animation")

local VC = require("scripts.constants.visuals") -- Visuals constants.

local events = {}

function events.on_init()
	pet_events.initialize_storage()
	pet_events.create_orphan_force()
end

function events.on_configuration_changed(cfg)
	pet_events.initialize_storage()
	pet_events.create_orphan_force()
end

function events.on_load()
	-- Rebind metatables at some point.
end

function events.on_player_created(event)
	local player = game.get_player(event.player_index)
	local entry = pet_lifecycle.get_pet_entry(player.index)

	-- Find a suitable position to spawn the biter.
	if not storage.pet_spawn_point then
		storage.pet_spawn_point = pet_spawn.choose_orphan_spawn(player.surface, player.position)
	end

	-- Spawn the biter.
	pet_spawn.spawn_orphan_baby(player, entry)
end

function events.on_tick(event)
	pet_lifecycle.on_tick(event)
	pet_animation.animate_pet_reaction_icon()
end

function events.on_entity_died(event)
	pet_lifecycle.on_entity_died(event)
end

function events.on_cutscene_cancelled(event)
	local entry = pet_lifecycle.get_pet_entry(event.player_index)
	pet_events.record_intro_cinematic_end_tick(event.player_index, entry)
end

return events
