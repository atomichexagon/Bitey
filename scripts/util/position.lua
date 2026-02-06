local position = {}

function position.distance(a, b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	return math.sqrt(dx * dx + dy * dy)
end

function position.get_direction_of_position(origin, destination)
	local dx = destination.x - origin.x
	local dy = destination.y - origin.y

	-- Determine primary axis.
	local vertical
	if dy < -1 then
		vertical = "north"
	elseif dy > 1 then
		vertical = "south"
	else
		vertical = nil
	end

	local horizontal
	if dx > 1 then
		horizontal = "east"
	elseif dx < -1 then
		horizontal = "west"
	else
		horizontal = nil
	end

	-- Intermediate direction.
	if vertical and horizontal then return vertical .. horizontal end

	-- Cardinal direction.
	return vertical or horizontal or "here"
end

return position
