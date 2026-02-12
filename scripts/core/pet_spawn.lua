local debug = require("scripts.util.debug")
local pet_nest = require("scripts.core.pet_nest")
local position_util = require("scripts.util.position_util")
local t = require("scripts.util.text_format")

local SC = require("scripts.constants.spawn")

local pet_spawn = {}

function pet_spawn.choose_orphan_spawn(surface, origin)
	local attempts = 0
	local successes = 0

	local position_candidates = {}
	for i = 1, 60 do
		attempts = attempts + 1

		local angle = math.random() * math.pi * 2
		local distance = SC.MINIMUM_SPAWN_DISTANCE + math.random() ^ 0.5 * SC.MAXIMUM_SPAWN_OFFSET

		local position = {
			x = origin.x + math.cos(angle) * distance,
			y = origin.y + math.sin(angle) * distance
		}

		-- Ensure chunks exist for spawning.
		surface.request_to_generate_chunks(position, 0)
		surface.force_generate_chunk_requests()

		if not surface.get_tile(position).collides_with("water_tile") then
			local valid = surface.find_non_colliding_position("pet-small-biter-baby", position, SC.SPAWN_SEARCH_RADIUS, SC.SEARCH_PRECISION)
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

	-- Store orphan respawn point in the event pet dies.
	if not storage.pet_spawn_point then storage.pet_spawn_point = pet_spawn.choose_orphan_spawn(surface, player.position) end

	-- Ensure the tile is actually walkable.
	local position = surface.find_non_colliding_position("pet-small-biter-baby", storage.pet_spawn_point, 10, 0.5)

	if not position then
		debug.info("Could not find a valid spawn location for the orphaned biter.")
		return
	end

	if generate_decoratives then pet_nest.decorate(surface, storage.pet_spawn_point) end

	-- Spawn the orphaned pet.
	local pet = surface.create_entity {
		name = "pet-small-biter-baby",
		position = position,
		force = game.forces["pet_orphan"]
	}

	pet.ai_settings.allow_destroy_when_commands_fail = false
	pet.ai_settings.allow_try_return_to_spawner = false

	entry.unit = pet
	entry.is_orphaned = true
	entry.biter_tier = "pet-small-biter-baby" -- Reset pet tier for new orphans.
	debug.info("Orphaned biter has spawned.")
end

function pet_spawn.spawn_pet_for_player(player, entry)
	local player_index = player.index
	local now = game.tick

	-- Check if biter was alive but is now missing (despawn and bug recovery).
	-- Assume that if entry.unit is nil and entry.was_alive is true, it's a lost pet.
	if entry.was_alive and (not entry.unit or not entry.unit.valid) then
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

	-- If the biter is was legitimately killed, spawn a new one after one game day.
	if not (entry.unit and entry.unit.valid) then
		entry.was_alive = false
		local last_death = entry.last_death_tick or 0
		--		if (now - last_death) >= SC.TICKS_PER_DAY then
		if (now - last_death) >= 300 then
			debug.info("Spawning replacement orphan.")
			pet_spawn.spawn_orphan_baby(player, entry, false)
			entry.was_alive = true
		else
			local remaining = math.floor((SC.TICKS_PER_DAY - (now - last_death)) / 60)
			debug.trace(string.format("Pet spawn will trigger in %s seconds.", t.f(remaining, "f")))
		end
	end
end

return pet_spawn
