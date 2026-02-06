local pet_state = require("scripts.core.pet_state")

local PR = require("scripts.constants.reactions")
local FOOD_REACTIONS = PR.FOOD_REACTIONS

local pet_reactions = {}

function pet_reactions.trigger(player_index, entry, food)

	local reaction = FOOD_REACTIONS[food]
	if not reaction then return end

	if reaction.emotes then
		for _, emote in ipairs(reaction.emotes) do pet_state.force_emote(player_index, entry, emote.name, emote.fast_render) end
	end
end

return pet_reactions
