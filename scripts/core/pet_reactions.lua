local debug = require("scripts.utilities.debug")
local pet_state = require("scripts.core.pet_state")

local REACTIONS_CONSTANTS = require("scripts.constants.reactions")
local FOOD_REACTIONS = REACTIONS_CONSTANTS.FOOD_REACTIONS
local COMBAT_REACTIONS = REACTIONS_CONSTANTS.COMBAT_REACTIONS

local pet_reactions = {}

local function process_reactions(player_index, entry, reactions)
	if not reactions then return end
	if reactions.emotes then
		for _, emote in ipairs(reactions.emotes) do pet_state.force_emote(player_index, entry, emote.name, emote.fast_render) end
	end
end

function pet_reactions.food_trigger(player_index, entry, food)
	local reactions = FOOD_REACTIONS[food]
	process_reactions(player_index, entry, reactions)
end

function pet_reactions.combat_trigger(player_index, entry, action)
	local reactions = COMBAT_REACTIONS[action]
	process_reactions(player_index, entry, reactions)
end

return pet_reactions
