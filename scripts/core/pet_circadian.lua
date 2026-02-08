local debug = require("scripts.util.debug")
local pet_state = require("scripts.core.pet_state")

local SCALE = require("__biter-pet__.shared.scaling")

local pet_circadian = {}

function pet_circadian.enter_sleep(player_index, entry)
	if entry.state == "sleeping" then return end
	local pet = entry.unit
	if not (pet and pet.valid) then return end

	local surface = pet.surface
	local pos = pet.position
	local force = pet.force
	local scale_factor = SCALE[pet.name] * 0.5
	local name = pet.name .. "-sleeping"

	pet.destroy()

	-- Replace "pet-biter-small" → "pet-biter-small-sleeping"
	local sleeper = surface.create_entity {
		name = name,
		position = pos,
		force = force
	}

	local id = rendering.draw_animation {
		animation = "pet-sleeping-animation",
		target = sleeper,
		surface = sleeper.surface,
		x_scale = scale_factor,
		y_scale = scale_factor,
		render_layer = "corpse"
	}
	entry.sleep_animation_id = id

	sleeper.commandable.set_command {
		type = defines.command.stop,
		distraction = defines.distraction.none
	}

	entry.unit = sleeper
	entry.wake_state = "sleeping"

	-- TODO: Add play_sound=true/false to emote table.
	-- TODO: Add custom fade_rate key to emote table.
	-- TODO: Add biter snoring sound if doable.
	-- TODO: Switch from default biter emote roars to snoring sounds if wake_state="sleeping"
	-- TODO: Maybe add custom light color to mood emotes when biter is "dreaming".
	pet_state.force_emote(player_index, entry, "sleeping", false)
end

function pet_circadian.exit_sleep(player_index, entry)
	if entry.wake_state ~= "sleeping" then return end
	local unit = entry.unit
	if not (unit and unit.valid) then return end

	local surface = unit.surface
	local pos = unit.position
	local force = unit.force

	-- Replace "pet-biter-small-sleeping" → "pet-biter-small"
	local active_name = unit.name:gsub("-sleeping", "")

	-- Destroy place-holder unit.
	unit.destroy()
	if entry.sleep_animation_id then
		entry.sleep_animation_id.destroy(entry.sleep_animation_id)
		entry.sleep_animation_id = nil
	end

	local active = surface.create_entity {
		name = active_name,
		position = pos,
		force = force
	}

	entry.unit = active
	entry.wake_state = "awake"
end

return pet_circadian
