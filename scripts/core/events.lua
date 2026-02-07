local debug = require("scripts.util.debug")
local pet_lifecycle = require("scripts.core.pet_lifecycle")
local pet_state = require("scripts.core.pet_state")
local pet_spawn = require("scripts.core.pet_spawn")
local pet_init = require("scripts.core.pet_init")
local pet_behavior = require("scripts.core.pet_behavior")
local pet_visuals = require("scripts.core.pet_visuals")
local pet_animation = require("scripts.core.pet_animation")

local events = {}

function events.on_init()
	pet_init.initialize_storage()
	pet_init.create_orphan_force()
	pet_init.check_existing_research()
end

function events.on_configuration_changed(cfg)
	pet_init.initialize_storage()
	pet_init.create_orphan_force()
	pet_init.check_existing_research()
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

	-- Spawn the biter and nest.
	pet_spawn.spawn_orphan_baby(player, entry, true)
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
	pet_behavior.record_intro_cinematic_end_tick(event.player_index, entry)
end

function events.on_research_finished(event)
	pet_behavior.on_research_finished(event)
end

return events
