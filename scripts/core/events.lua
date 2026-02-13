local debug = require("scripts.utilities.debug")
local pet_lifecycle = require("scripts.core.pet_lifecycle")
local pet_state = require("scripts.core.pet_state")
local pet_spawn = require("scripts.core.pet_spawn")
local pet_init = require("scripts.core.pet_init")
local pet_behavior = require("scripts.core.pet_behavior")
local pet_visuals = require("scripts.core.pet_visuals")
local pet_animation = require("scripts.core.pet_animation")

local events = {}

local function ensure_pet_exists(player)
	local entry = pet_lifecycle.get_pet_entry(player.index)

	-- Find a suitable position to spawn the biter and nest.
	if not entry.unit or not entry.unit.valid then
		local generate_decoratives = false
		if not storage.pet_spawn_point then
			storage.pet_spawn_point = pet_spawn.choose_orphan_spawn(player.surface, player.position)
			generate_decoratives = true
		end
		pet_spawn.spawn_orphan_baby(player, entry, generate_decoratives)
	end
end

function events.on_init()
	pet_init.initialize_storage()
	pet_init.create_orphan_force()
	pet_init.check_existing_research()
end

function events.on_configuration_changed(cfg)
	pet_init.initialize_storage()
	pet_init.create_orphan_force()
	pet_init.check_existing_research()
	for _, player in pairs(game.players) do ensure_pet_exists(player) end
end

function events.on_load()
	-- Rebind metatables at some point.
end

function events.on_entity_damaged(event)
	local entity = event.entity
	if not (entity and entity.valid) then return end
	for player_index, entry in pairs(storage.biter_pet) do
		if entry.unit == entity then
			pet_behavior.on_pet_damaged(player_index, entry, event)
			return
		end
	end
end

function events.on_player_created(event)
	local player = game.get_player(event.player_index)
	local entry = pet_lifecycle.get_pet_entry(player.index)
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
	local player = game.get_player(event.player_index)

	-- Find a suitable position to spawn the biter and nest.
	if not storage.pet_spawn_point then
		storage.pet_spawn_point = pet_spawn.choose_orphan_spawn(player.surface, player.position)
	end
	pet_spawn.spawn_orphan_baby(player, entry, true)
end

function events.on_research_finished(event)
	pet_behavior.on_research_finished(event)
end

return events
