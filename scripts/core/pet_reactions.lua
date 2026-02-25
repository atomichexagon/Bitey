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

local function spawn_glow(entry, glow)
	if not (entry and entry.unit and entry.unit.valid) then return end
	local pet = entry.unit

	local old_glow_id = entry.glow_id

	if old_glow_id and old_glow_id.valid then old_glow_id.destroy() end

	entry.active_glow = {
		sprite = "utility/light_medium",
		target = pet,
		surface = pet.surface,
		color = glow.color,
		intensity = glow.intensity,
		scale = glow.scale,
		minimum_darkness = glow.minimum_darkness,
		expire_tick = game.tick + glow.time_to_live
	}

	local glow_id = rendering.draw_light {
		sprite = "utility/light_medium",
		target = pet,
		surface = pet.surface,
		color = glow.color,
		intensity = glow.intensity,
		scale = glow.scale,
		minimum_darkness = glow.minimum_darkness,
		time_to_live = glow.time_to_live
	}

	if glow.combat_modifier then
		entry.combat_buffs = entry.combat_buffs or {}
		table.insert(entry.combat_buffs, {
			type = glow.combat_modifier.type,
			magnitude = glow.combat_modifier.magnitude or 1,
			expire_tick = game.tick + glow.time_to_live
		})
	end
	entry.glow_id = glow_id
end

local function applicable_to_game_configuration(item)
	if not script.active_mods["space-age"] then return true end
	if not item.combat_modifier then return true end
	if not item.combat_modifier.condition then return true end
	if item.combat_modifier.condition == "base" then return false end
	return true
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
			if item.glow and applicable_to_game_configuration(item.glow) then spawn_glow(entry, item.glow) end
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
