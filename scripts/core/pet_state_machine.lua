local debug = require("scripts.utilities.debug")
local normalize = require("scripts.utilities.normalize")
local pet_state = require("scripts.core.pet_state")
local position_util = require("scripts.utilities.position_util")
local t = require("scripts.utilities.text_format")

local LC = require("scripts.constants.lifecycle")

local SCALING = require("__biter-pet__.shared.scaling")
local SCALE = SCALING.SIZE_SCALE
local SLEEP_SCALE = SCALING.SLEEP_SCALE

local pet_state_machine = {}

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
end

local function get_sleep_animation_name(orientation)
	local suffix = (orientation <= 0.5) and "right" or "left"
	return string.format("pet-sleeping-animation-%s", suffix)
end

function pet_state_machine.enter_sleep(player_index, entry)
	if entry.current_form == "sleeping" then return end
	local pet = entry.unit
	if not (pet and pet.valid) then return end

	local surface = pet.surface
	local position = pet.position
	local force = pet.force
	local name = normalize.name(pet.name)
	local scale_factor = SLEEP_SCALE[name] * 0.5
	local sleeper_name = string.format("%s%s", name, "-sleeping")
	local animation = get_sleep_animation_name(pet.orientation)
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

	-- TODO: Add play_sound=true/false to emote table.
	-- TODO: Add custom fade_rate key to emote table.
	-- TODO: Add biter snoring sound if doable or just lower roar sound when sleeping.
	-- TODO: Switch from default biter emote roars to snoring sounds if current_form="sleeping"
	-- TODO: Maybe add custom light color to mood emotes when biter is "dreaming".
	pet_state.force_emote(player_index, entry, "sleeping", false)
end

return pet_state_machine
