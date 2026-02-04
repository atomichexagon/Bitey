local pet_state = require("scripts.core.pet_state")
local debug = require("scripts.util.debug")

local GC = require("scripts.constants.growth") -- Pet growth constants.

local pet_growth = {}

-- Get current tier index.
local function get_tier_index(name)
	for i, tier in ipairs(GC.TIERS) do
		if tier == name then
			return i
		end
	end
	return 1
end

-- Upgrade entity prototype.
local function upgrade_pet(entry, new_name)
	local old = entry.unit
	if not (old and old.valid) then
		return
	end
	if old.name == new_name then
		return
	end

	local surface = old.surface
	local pos = old.position
	local force = old.force

	old.destroy()

	local new_pet = surface.create_entity {
		name = new_name,
		position = pos,
		force = force
	}

	new_pet.ai_settings.allow_destroy_when_commands_fail = false
	new_pet.ai_settings.allow_try_return_to_spawner = false

	entry.unit = new_pet
	entry.biter_tier = new_name -- Ensure this matches the new name for respawn logic.
end

-- Called immediately after eating.
function pet_growth.try_grow(player_index, entry)
	local pet = entry.unit
	if not (pet and pet.valid) then
		return
	end

	-- Biter must meet hunger threshold before growth is triggered.
	local hunger = pet_state.get_hunger(player_index) or 0
	if hunger >= 15 then
		return
	end

	local surface = pet.surface
	local evo = game.forces.enemy.get_evolution_factor(surface)
	local current = pet.name
	local tier = get_tier_index(current)

	-- Baby to Small biter.
	if current == "pet-biter-baby" then
		if evo > GC.BABY_TO_SMALL_THRESHOLD and math.random() < GC.PET_GROWTH_CHANCE then
			upgrade_pet(entry, "pet-biter-small")
			entry.biter_tier = "pet-biter-small"
			entry.biter_tier_friendly_name = "pet_biter_small"
		end
		return
	end

	-- Small to Large biter.
	if current == "pet-biter-small" then
		if evo > GC.SMALL_TO_LARGE_THRESHOLD and math.random() < GC.PET_GROWTH_CHANCE then
			upgrade_pet(entry, "pet-biter-large")
			entry.biter_tier = "pet-biter-large"
			entry.biter_tier_friendly_name = "pet_biter_large"
		end
		return
	end

	-- Large to worry about this later...
end

return pet_growth
