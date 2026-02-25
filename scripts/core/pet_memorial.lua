local debug = require("scripts.utilities.debug")
local position_util = require("scripts.utilities.position_util")

local pet_memorial = {}

pet_memorial.memorials = {}

local function get_worm_turret_size(bond_level)
	if bond_level >= 75 then return "memorial-behemoth-worm" end
	if bond_level >= 50 then return "memorial-big-worm" end
	if bond_level >= 25 then return "memorial-medium-worm" end
	return "memorial-small-worm"
end

local function get_turret_positions(entity)
	return {
		{
			entity.bounding_box.left_top.x - 2,
			entity.bounding_box.left_top.y - 1
		},
		{
			entity.bounding_box.right_bottom.x + 2,
			entity.bounding_box.left_top.y - 1
		},
		{
			entity.bounding_box.left_top.x - 2,
			entity.bounding_box.right_bottom.y + 2
		},
		{
			entity.bounding_box.right_bottom.x + 2,
			entity.bounding_box.right_bottom.y + 2
		}
	}
end

-- TODO: Worms attack any player that damages.
local function spawn_guardians(entity, data)
	local bond_level = data.bond_level
	local force = data.force

	local turret_name = get_worm_turret_size(data.bond_level)
	for _, position in ipairs(data.spawn_positions) do
		entity.surface.create_entity {
			name = turret_name,
			position = position,
			force = force,
			raised_built = true
		}
	end
end

local function players_near_memorial(entity)
	local radius_squared = 40 * 40
	local position = entity.position
	for _, blocking_entity in pairs(entity.surface.find_entities_filtered {
		type = {
			"character",
			"car",
			"tank",
			"spider-vehicle"
		}
	}) do
		if position_util.distance_squared(blocking_entity.position, position) <= (radius_squared) then
			return true
		end
	end
	return false
end

function pet_memorial.monitor_memorials(event)
	if (event.tick % 60) ~= 0 then return end

	for id, data in pairs(pet_memorial.memorials) do
		local entity = data.entity

		if not entity.valid then
			pet_memorial.memorials[id] = nil
		else
			local crafting = entity.is_crafting()

			if data.was_crafting and not crafting then
				data.pending_spawn = true
				data.spawn_positions = get_turret_positions(entity)
			end

			if data.pending_spawn then
				if not players_near_memorial(entity) then
					spawn_guardians(entity, data)
					pet_memorial.memorials[id] = nil
				end
			end

			data.was_crafting = crafting
		end
	end
end

return pet_memorial
