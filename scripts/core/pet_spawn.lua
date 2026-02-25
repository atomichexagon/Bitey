local debug = require("scripts.utilities.debug")
local pet_nest = require("scripts.core.pet_nest")
local position_util = require("scripts.utilities.position_util")
local t = require("scripts.utilities.text_format")

local SS = require("scripts.constants.spawn").SPAWN_SETTINGS
local OM = require("scripts.constants.spawn").ORPHAN_MAP

local pet_spawn = {}

function pet_spawn.choose_orphan_spawn(surface, origin)
	local attempts = 0
	local successes = 0

	local position_candidates = {}
	for i = 1, 60 do
		attempts = attempts + 1

		local angle = math.random() * math.pi * 2
		local distance = SS.minimum_spawn_distance + math.random() ^ 0.5 * SS.maximum_spawn_offset

		local position = {
			x = origin.x + math.cos(angle) * distance,
			y = origin.y + math.sin(angle) * distance
		}

		-- Ensure chunks exist for spawning.
		surface.request_to_generate_chunks(position, 0)
		surface.force_generate_chunk_requests()

		if not surface.get_tile(position).collides_with("water_tile") then
			local valid = surface.find_non_colliding_position("pet-small-biter-baby", position, SS.spawn_search_radius,
					SS.search_precision)
			if valid then
				successes = successes + 1
				position_candidates[#position_candidates + 1] = valid
			end
		end
	end

	debug.info("Polling for valid spawn locations.")
	debug.info(successes .. " of " .. attempts .. " attemps were successful.")

	-- Choose random spawn position for nest.
	if #position_candidates > 0 then
		local spawn_pos = position_candidates[math.random(1, #position_candidates)]
		debug.info("Choosing randomized spawn position from candidate positions.")
		return spawn_pos
	end

	-- Take another stab at it if all else fails.
	local fallback_pos = surface.find_non_colliding_position("pet-small-biter-baby", origin, 20, 1) or origin
	debug.info("Choosing emergency fallback spawn position.")
	debug.info("The map better be very abnormal for this message to have triggered.")
	return fallback_pos
end

function pet_spawn.spawn_orphan_baby(player, entry, generate_decoratives)
	local surface = player.surface
	local species = "pet-small-biter-baby"

	-- Store orphan respawn point in the event pet dies.
	if not storage.pet_spawn_point then storage.pet_spawn_point = pet_spawn.choose_orphan_spawn(surface, player.position) end

	-- Ensure the tile is actually walkable.
	local position = surface.find_non_colliding_position(species, storage.pet_spawn_point, 10, 0.5)

	if not position then
		debug.info("Could not find a valid spawn location for the orphaned biter.")
		return
	end

	if generate_decoratives then pet_nest.decorate(surface, storage.pet_spawn_point) end

	local pet = surface.create_entity {
		name = species,
		position = position,
		force = game.forces["pet_orphan"]
	}

	pet.ai_settings.allow_destroy_when_commands_fail = false
	pet.ai_settings.allow_try_return_to_spawner = false

	entry.unit = pet
	entry.is_orphaned = true
	entry.biter_tier = species
	debug.info("Orphaned biter has spawned.")
end

function pet_spawn.spawn_pet_for_player(player_index, player, entry)

	-- Assume that if unit is nil and it was preivously alive then it's a lost pet.
	local tier = entry.biter_tier or "pet-small-biter-baby"
	debug.info(string.format("Recovering lost pet %s", t.f(tier, "f")))

	local position = player.surface.find_non_colliding_position(tier, player.position, 15, 0.5)

	if position then
		entry.unit = player.surface.create_entity {
			name = tier,
			position = position,
			force = player.force
		}
		return
	end
end

return pet_spawn
