local position = {}


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

-- TODO: Make intermediate directions less sensitive.
function position.get_direction_of_position(origin, destination)
	local distance_x = destination.x - origin.x
	local distance_y = destination.y - origin.y

	-- Determine primary axis.
	local vertical
	if distance_y < -1 then
		vertical = "north"
	elseif distance_y > 1 then
		vertical = "south"
	else
		vertical = nil
	end

	local horizontal
	if distance_x > 1 then
		horizontal = "east"
	elseif distance_x < -1 then
		horizontal = "west"
	else
		horizontal = nil
	end

	-- Return intermediate direction.
	if vertical and horizontal then return vertical .. horizontal end
	-- Return cardinal direction.
	return vertical or horizontal or "here"
end

return position
