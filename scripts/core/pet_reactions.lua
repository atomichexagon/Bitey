local debug = require("scripts.utilities.debug")
local pet_state = require("scripts.core.pet_state")
local pet_modifiers = require("scripts.core.pet_modifiers")
local pet_morph = require("scripts.core.pet_morph")
local pet_growth = require("scripts.core.pet_growth")

local ID = require("scripts.constants.reactions").ITEM_DEFINITIONS
local CR = require("scripts.constants.reactions").COMBAT_REACTIONS

local pet_reactions = {}

local function process_reactions(player_index, entry, reactions)
	if not reactions then return end
	if reactions then
		for _, emote in ipairs(reactions) do pet_state.force_emote(player_index, entry, emote.name, emote.fast_render) end
	end
end

function pet_reactions.process_item_interaction(player_index, pet, entry, item_name)
	local item = ID[item_name]
	if not item then return end

	local reactions = item.emotes
	local modifiers = item.modifiers

	pet_modifiers.apply_modifiers(player_index, entry, modifiers)
	process_reactions(player_index, entry, reactions)

	if item.interaction == "eat" then
		if not entry.is_orphaned then
			pet_growth.try_grow(player_index, entry)
			pet_morph.evaluate_morph_state(player_index, pet, entry, item_name)
		end
		pet_state.set_behavior(player_index, "eat")

	elseif item.interaction == "fetch" then
		entry.fetch_plays = (entry.fetch_plays or 0) + 1
		pet_state.set_behavior(player_index, "return_item")
		pet_state.set_returnable_item(player_index, item_name)
	end

	pet_state.set_item_target(player_index, nil)
end

function pet_reactions.combat_trigger(player_index, entry, action)
	local reactions = CR[action]
	process_reactions(player_index, entry, reactions)
end

return pet_reactions
