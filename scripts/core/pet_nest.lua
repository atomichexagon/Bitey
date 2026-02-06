local post_util = require("scripts.util.position")

local pet_nest = {}

local DECORATIVES = {
	"green-asterisk-mini",
	"green-bush-mini",
	"green-carpet-grass",
	"green-hairy-grass",
	"green-small-grass"
}

local function random_offset(radius)
	return {
		x = (math.random() * radius * 2) - radius,
		y = (math.random() * radius * 2) - radius
	}
end

local function clear_nest_area(surface, position, radius, types)
	local r = radius or 10
	local area = {
		{
			position.x - r,
			position.y - r
		},
		{
			position.x + r,
			position.y + r
		}
	}

	-- Clear all entities in the radius.
	local entities = surface.find_entities_filtered {
		type = types,
		area = area
	}
	for _, ent in ipairs(entities) do if post_util.distance(ent.position, position) <= r then ent.destroy() end end

	-- Throw down some dirt.
	local tiles = {}
	for x = position.x - r, position.x + r do
		for y = position.y - r, position.y + r do
			if post_util.distance({
				x = x,
				y = y
			}, position) <= r then
				tiles[#tiles + 1] = {
					name = "dirt-5",
					position = {
						x,
						y
					}
				}
			end
		end
	end
	surface.set_tiles(tiles)

	-- Remove auto-generated decoratives.
	surface.destroy_decoratives(area)
end

function pet_nest.decorate(surface, position)

	clear_nest_area(surface, position, 10, {
		"tree",
		"simple-entity"
	})

	-- Scatter decoratives around nest.
	for i = 1, 120 do
		local deco = DECORATIVES[math.random(#DECORATIVES)]
		local offset = random_offset(6)

		surface.create_decoratives {
			check_collision = false,
			decoratives = {
				{
					name = deco,
					position = {
						position.x + offset.x,
						position.y + offset.y
					},
					amount = 1
				}
			}
		}
	end

	-- Position "Martha" and "Bruce" corpses.
	offset = random_offset(4)
	surface.create_entity {
		name = "medium-biter-corpse",
		position = {
			position.x + offset.x - 1,
			position.y + offset.y - 1
		},
		force = "neutral"
	}

	surface.create_entity {
		name = "big-biter-corpse",
		position = {
			position.x + offset.x + 2,
			position.y + offset.y - 3
		},
		force = "neutral"
	}

	-- Position "Joe Chill" remnant.
	surface.create_entity {
		name = "tank-remnants",
		position = {
			position.x + offset.x + 4,
			position.y + offset.y + 5
		},
		force = "neutral"
	}

end

return pet_nest
