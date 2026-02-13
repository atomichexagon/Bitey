local debug = require("scripts.utilities.debug")
local pet_state = require("scripts.core.pet_state")
local normalize = require("scripts.utilities.normalize")
local notifications = require("scripts.utilities.notifications")
local position_util = require("scripts.utilities.position_util")
local t = require("scripts.utilities.text_format")

local BM = require("scripts.constants.biters").BITER_MAP
local GS = require("scripts.constants.growth").GROWTH_SETTINGS
local GR = require("scripts.constants.growth").GROWTH_RULES
local DC = require("scripts.constants.debug")

local pet_growth = {}

-- Set evolution factor for testing: /c game.forces["enemy"].set_evolution_factor(0.99, game.player.surface)
local function upgrade_pet(player_index, entry, new_name)
	local old_unit = entry.unit
	if not (old_unit and old_unit.valid) then return end
	if normalize.name(old_unit.name) == new_name then return end

	local surface = old_unit.surface
	local position = old_unit.position
	local force = old_unit.force
	local orientation = old_unit.orientation or 0
	local direction_index = position_util.direction_from_orientation(orientation)

	debug.info(string.format("Pet evolving from %s to %s.", t.f(old_unit.name, "f"), t.f(new_name, "f")))
	normalize.clear_emote_queue(player_index)

	old_unit.destroy()

	local new_pet = surface.create_entity {
		name = new_name,
		position = position,
		force = force,
		direction = direction_index
	}
	new_pet.ai_settings.allow_destroy_when_commands_fail = false
	new_pet.ai_settings.allow_try_return_to_spawner = false

	new_pet.commandable.set_command {
		type = defines.command.wander,
		destination = position,
		radius = 0.1,
		distraction = defines.distraction.none
	}

	entry.unit = new_pet
	entry.biter_tier = new_name
	entry.current_form = "active"
	return entry
end

--[[
 /c game.forces["enemy"].set_evolution_factor(0.99, game.player.surface)
 ]]

function pet_growth.try_grow(player_index, entry)
	local pet = entry.unit
	if not (pet and pet.valid) then return end

	local name = normalize.name(pet.name)
	local rule = GR[name]
	if not rule then return end

	if not rule.next then return end

	-- Pet growth hunger gate.
	local hunger = pet_state.get_hunger(player_index) or 0
	if hunger >= rule.hunger_threshold and not GS.DEBUG_IGNORE_EVOLUTION_GATES then return end

	-- Pet growth evolution factor gate.
	local surface = pet.surface
	local evolution_factor = (GS.DEBUG_IGNORE_EVOLUTION_GATES and 1) or game.forces.enemy.get_evolution_factor(surface)
	if evolution_factor < rule.evo_factor_threshold then return end

	-- Pet growth chance gate.
	local chance = (GS.DEBUG_IGNORE_EVOLUTION_GATES and 1) or rule.chance
	if math.random() >= chance then return end

	-- Pet growth evolution state gate.
	local evolution = pet_state.get_evolution(player_index) or 0
	if evolution < rule.evo_state_threshold and not GS.DEBUG_IGNORE_EVOLUTION_GATES then return end

	-- All gate checks passed so perform upgrade.
	entry = upgrade_pet(player_index, entry, rule.next)
	if entry then
		pet_state.force_emote(player_index, entry, "ecstatic")
		pet = entry.unit
		if not pet or not pet.valid then return end
		local player = game.get_player(player_index)
		notifications.notify(player, pet, {
			type = "entity",
			name = BM[entry.biter_tier].base_equivalent
		}, string.format("The biter seems to be getting stronger..."), "utility/achievement_unlocked")
	end
end

return pet_growth
