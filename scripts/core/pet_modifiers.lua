local debug = require("scripts.utilities.debug")
local pet_state = require("scripts.core.pet_state")

local t = require("scripts.utilities.text_format")

local MOOD_BONUS_SCALER = require("scripts.constants.modifiers").MOOD_BONUS_SCALER

local ID = require("scripts.constants.reactions").ITEM_DEFINITIONS
local CM = require("scripts.constants.modifiers").COMBAT_MODIFIERS
local BM = require("scripts.constants.modifiers").BEHAVIORAL_MODIFIERS

local DC = require("scripts.constants.debug")

local pet_modifiers = {}

local STATE_APPLIERS = {
	boredom = pet_state.add_boredom,
	friendship = pet_state.add_friendship,
	happiness = pet_state.add_happiness,
	evolution = pet_state.add_evolution,
	hunger = pet_state.add_hunger,
	morph = pet_state.add_morph,
	thirst = pet_state.add_thirst,
	tiredness = pet_state.add_tiredness
}

local function batch_modify_state(player_index, modifiers, mood_bonus)
	local mood_bonus = mood_bonus or 0

	for key, value in pairs(modifiers) do
		local target_function = STATE_APPLIERS[key]

		if target_function then
			if key == "boredom" then
				target_function(player_index, value - mood_bonus)
			elseif key == "happiness" then
				target_function(player_index, value + mood_bonus)
			elseif key == "friendship" then
				target_function(player_index, value + mood_bonus)
			else
				target_function(player_index, value)
			end
		end
	end
end

function pet_modifiers.apply_cowardice_modifiers(player_index, entry)
	debug.info("Apply modifiers for fleeing from combat.")

	local modifiers = CM["cowardice"]
	if not modifiers then
		debug.warn("Combat modifer table missing entry for cowardice.")
		return
	end
	batch_modify_state(player_index, modifiers)
end

function pet_modifiers.apply_friendly_fire_modifiers(player_index, entry, key)
	debug.info("Apply modifiers for incurring damage.")

	local modifiers = BM[key]
	if not modifiers then
		debug.warn("Behavioral modifer table missing entry for " .. t.f(key, "f") .. ".")
		return
	end

	batch_modify_state(player_index, modifiers)
end

function pet_modifiers.apply_modifiers(player_index, entry, modifiers)
	if DC.DEBUG_SHOW_NEEDS_UPDATES then debug.trace(string.format("Applying modifiers for eating %s", food)) end

	if not modifiers then
		debug.warn(string.format("Food modifier table missing entry for %s", t.f(food, "w")))
		return
	end
	-- Scale modifiers based on hunger severity.
	local state = pet_state.get(player_index)
	local mood_bonus = math.floor((state.hunger ^ 1.1) * (MOOD_BONUS_SCALER / 1000))

	batch_modify_state(player_index, modifiers, mood_bonus)
end

return pet_modifiers
