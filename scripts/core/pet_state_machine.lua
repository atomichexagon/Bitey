local debug = require("scripts.utilities.debug")
local normalize = require("scripts.utilities.normalize")
local pet_state = require("scripts.core.pet_state")
local position_util = require("scripts.utilities.position_util")
local t = require("scripts.utilities.text_format")

local SS = require("__biter-pet__.shared.scaling").SLEEP_SCALE
local LC = require("scripts.constants.lifecycle")


local pet_state_machine = {}

function pet_state_machine.reapply_glow(entry)
	if not (entry.unit and entry.unit.valid) then return end
	if not entry.active_glow then return end
	if (entry.active_glow.expire_tick - game.tick) <= 60 then return end

	if entry.glow_id then
		entry.glow_id.destroy()
		entry.glow_id = nil
	end

	local glow_id = rendering.draw_light {
		sprite = "utility/light_medium",
		target = entry.unit,
		surface = entry.unit.surface,
		color = entry.active_glow.color,
		intensity = entry.active_glow.intensity,
		scale = entry.active_glow.scale,
		minimum_darkness = entry.active_glow.minimum_darkness,
		time_to_live = entry.active_glow.expire_tick - game.tick
	}
end

function pet_state_machine.enter_idle(player_index, pet, entry, destination)
	if entry.current_form == "idle" then return end
	if not (pet and pet.valid) then return end

	local surface = pet.surface
	local pos = pet.position
	local force = pet.force
	local name = pet.name .. "-idle"
	normalize.clear_emote_queue(player_index)

	local orientation = pet.orientation or 0
	local direction_index = position_util.direction_from_orientation(orientation)
	pet.destroy()

	local idler = surface.create_entity {
		name = name,
		position = pos,
		force = force,
		direction = direction_index
	}

	idler.commandable.set_command {
		type = defines.command.wander,
		destination = destination,
		radius = radius,
		distraction = defines.distraction.none
	}

	entry.unit = idler
	entry.current_form = "idle"
	pet_state_machine.reapply_glow(entry)
end

function pet_state_machine.enter_active(player_index, entry)
	if not entry.current_form then return end
	if entry.current_form == "active" then return end

	local pet = entry.unit
	if not (pet and pet.valid) then return end

	local surface = pet.surface
	local position = pet.position
	local force = pet.force

	local name = normalize.name(pet.name)
	normalize.clear_emote_queue(player_index)

	local orientation = pet.orientation or 0
	local direction_index = position_util.direction_from_orientation(orientation)
	pet.destroy()

	local active = surface.create_entity {
		name = name,
		position = position,
		force = force,
		direction = direction_index
	}

	entry.unit = active
	entry.current_form = "active"
	pet_state_machine.reapply_glow(entry)
end

local function get_sleep_animation_name(orientation, species)
	local suffix = (orientation <= 0.5) and "right" or "left"
	return string.format("sleeping-%s-%s", suffix, species)
end

function pet_state_machine.enter_sleep(player_index, entry)
	if entry.current_form == "sleeping" then return end
	local pet = entry.unit
	if not (pet and pet.valid) then return end

	local surface = pet.surface
	local position = pet.position
	local force = pet.force
	local name = normalize.name(pet.name)
	local scale_factor = SS[name] * 0.5
	local sleeper_name = string.format("%s%s", name, "-sleeping")
	local species = entry.current_species or "biter"
	local animation = get_sleep_animation_name(pet.orientation, species)
	entry.sleep_direction = pet.orientation
	normalize.clear_emote_queue(player_index)
	pet.destroy()

	local sleeper = surface.create_entity {
		name = sleeper_name,
		position = position,
		force = force
	}

	local id = rendering.draw_animation {
		animation = animation,
		target = sleeper,
		surface = sleeper.surface,
		x_scale = scale_factor,
		y_scale = scale_factor,
		render_layer = "object-under",
		direction = entry.sleep_direction

	}
	entry.sleep_animation_id = id

	sleeper.commandable.set_command {
		type = defines.command.stop,
		distraction = defines.distraction.none
	}

	entry.unit = sleeper
	entry.current_form = "sleeping"
	pet_state_machine.reapply_glow(entry)
	pet_state.force_emote(player_index, entry, "sleeping", false)
end

function pet_state_machine.enter_desconstruct_tree(player_index, entry, target)
	local state = pet_state.get_state(player_index)
	state.tree_target = target
	pet_state.set_behavior(player_index, "desconstruct_tree")
end

return pet_state_machine
