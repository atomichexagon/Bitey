local debug = require("scripts.util.debug")
local pet_state = require("scripts.core.pet_state")

local t = require("scripts.util.text_format")

local MODIFIER_CONSTANTS = require("scripts.constants.modifiers")
local FOOD_MODIFIERS = MODIFIER_CONSTANTS.FOOD_MODIFIERS
local COMBAT_MODIFIERS = MODIFIER_CONSTANTS.COMBAT_MODIFIERS
local MOOD_BONUS_SCALER = MODIFIER_CONSTANTS.MOOD_BONUS_SCALER

local REACTION_CONSTANTS = require("scripts.constants.reactions")
local FOOD_DEFINITIONS = REACTION_CONSTANTS.FOOD_DEFINITIONS
local COMBAT_REACTIONS = REACTION_CONSTANTS.COMBAT_REACTIONS

local pet_modifiers = {}

local STATE_MODIFIER_KEYS = {
	"boredom",
	"evolution",
	"friendship",
	"happiness",
	"hunger",
	"morph",
	"thirst",
	"tiredness"
}

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

local function ensure_all_modifiers_have_values(modifiers)
	local safe_modifiers = {}
	for _, key in ipairs(STATE_MODIFIER_KEYS) do safe_modifiers[key] = modifiers[key] or 0 end
	return safe_modifiers
end

local function batch_modify_state(player_index, modifiers, mood_bonus)
	local mood_bonus = mood_bonus or 0
	local safe_modifiers = ensure_all_modifiers_have_values(modifiers)

	for key, value in pairs(safe_modifiers) do
		local func = STATE_APPLIERS[key]
		if func then
			if key == "boredom" then
				func(player_index, value - mood_bonus)
			elseif key == "happiness" then
				func(player_index, value + mood_bonus)
			elseif key == "friendship" then
				func(player_index, value + mood_bonus)
			else
				func(player_index, value)
			end
		end
	end
end

function pet_modifiers.apply_cowardice_modifiers(player_index, entry)
	debug.info("Apply modifiers for fleeing from combat.")

	local modifiers = COMBAT_MODIFIERS["cowardice"]
	if not modifiers then
		debug.warn("Combat modifer table missing entry for cowardice.")
		return
	end
	batch_modify_state(player_index, modifiers)
end

function pet_modifiers.apply_food_modifiers(player_index, entry, food)
	debug.info(string.format("Applying modifiers for eating %s", food))

	local modifiers = FOOD_MODIFIERS[food]
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
