local position = {}

local DIRECTIONAL_OFFSETS = {
	[defines.direction.north] = {
		x = 0,
		y = -1
	},
	[defines.direction.northeast] = {
		x = 0.7,
		y = -0.7
	},
	[defines.direction.east] = {
		x = 1,
		y = 0
	},
	[defines.direction.southeast] = {
		x = 0.7,
		y = 0.7
	},
	[defines.direction.south] = {
		x = 0,
		y = 1
	},
	[defines.direction.southwest] = {
		x = -0.7,
		y = 0.7
	},
	[defines.direction.west] = {
		x = -1,
		y = 0
	},
	[defines.direction.northwest] = {
		x = -0.7,
		y = -0.7
	}
}

function position.distance(position_a, position_b)
	local distance_x = position_a.x - position_b.x
	local distance_y = position_a.y - position_b.y
	return math.sqrt(distance_x * distance_x + distance_y * distance_y)
end

function position.distance_squared(position_a, position_b)
	local distance_x = position_a.x - position_b.x
	local distance_y = position_a.y - position_b.y
	return distance_x * distance_x + distance_y * distance_y
end

local function get_entity_radius(entity)
	local box = entity.prototype.collision_box
	local width = box.right_bottom.x - box.left_top.x
	local height = box.right_bottom.y - box.left_top.y
	return math.max(width, height) * 0.5
end

function position.get_offset_position(origin, target)
	local radius = get_entity_radius(target)
	local origin_position = origin.position
	local target_position = target.position

	local distance_x = origin_position.x - target_position.x
	local distance_y = origin_position.y - target_position.y
	local distance = position.distance(origin_position, target_position)

	if distance == 0 then
		return {
			x = target_position.x + radius + 1,
			y = target_position.y
		}
	end

	distance_x = distance_x / distance
	distance_y = distance_y / distance

	return {
		x = target_position.x + distance_x * (radius + 0.5),
		y = target_position.y + distance_y * (radius + 0.5)
	}
end

function position.get_forward_offset(player, distance)
	if not (player and player.valid) then return nil end

	local direction = player.character.direction
	local offset = DIRECTIONAL_OFFSETS[direction]

	if not offset then return player.position end

	return {
		x = player.position.x + offset.x * distance,
		y = player.position.y + offset.y * distance
	}
end

function position.direction_from_orientation(orientation)
	return math.floor(orientation * 16 + 0.5) % 16
end

function position.pick_idle_target(pet_position, tether, radius)
	for i = 1, 20 do

		local angle = math.random() * math.pi * 2
		local distance = radius * (0.5 + math.random() * 0.5)

		local candidate = {
			x = pet_position.x + math.cos(angle) * distance,
			y = pet_position.y + math.sin(angle) * distance
		}

		if position.distance_squared(candidate, tether) <= radius * radius then return candidate end
	end

	return pet_position
end

function position.randomly_offset(pos, distance)
	local angle = math.random() * math.pi * 2
	return {
		x = pos.x + math.cos(angle) * distance,
		y = pos.y + math.sin(angle) * distance
	}
end

function position.get_direction_of_position(origin, destination)
	local distance_x = destination.x - origin.x
	local distance_y = destination.y - origin.y

	local axis_x = math.abs(distance_x)
	local axis_y = math.abs(distance_y)

	-- Nest spawned too close to player so notification is unncessary.
	if axis_x < 10 and axis_y < 10 then return false end

	local vertical = (distance_y < -1 and "north") or (distance_y > 1 and "south") or nil

	local horizontal = (distance_x > 1 and "east") or (distance_x < -1 and "west") or nil

	if vertical and horizontal then
		local dominant = math.max(axis_x, axis_y)
		local minor = math.min(axis_x, axis_y)

		if dominant / minor >= 1.5 then return (axis_y > axis_x) and vertical or horizontal end
		return vertical .. horizontal
	end
	return vertical or horizontal
end

return position
