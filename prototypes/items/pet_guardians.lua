local function add_memorial_glow(prototype, intensity, size)
    prototype.light = {
		minimum_darkness = 0.2,
        color = {r = 0.7, g = 0.9, b = 1.0},
        intensity = intensity,
        size = size
    }
end

local small = table.deepcopy(data.raw["turret"]["small-worm-turret"])
small.name = "memorial-small-worm"
add_memorial_glow(small, 0.3, 6)

local medium = table.deepcopy(data.raw["turret"]["medium-worm-turret"])
medium.name = "memorial-medium-worm"
add_memorial_glow(medium, 0.45, 8)

local big = table.deepcopy(data.raw["turret"]["big-worm-turret"])
big.name = "memorial-big-worm"
add_memorial_glow(big, 0.6, 10)

local behemoth = table.deepcopy(data.raw["turret"]["behemoth-worm-turret"])
behemoth.name = "memorial-behemoth-worm"
add_memorial_glow(behemoth, 0.8, 12)

data:extend{small, medium, big, behemoth}
