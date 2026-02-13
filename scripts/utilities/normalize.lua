local debug = require("scripts.utilities.debug")
local pet_state = require("scripts.core.pet_state")

local normalize = {}

function normalize.name(name)
	return name:gsub("-sleeping", ""):gsub("-idle", "")
end

function normalize.clear_emote_queue(player_index)
	local emote_state = pet_state.get_queue(player_index)
	emote_state.queue = {}
	emote_state.forced_queue = {}
	emote_state.sprite_render = nil
	emote_state.active_type = nil
	emote_state.active_emote = nil
	emote_state.ends_at_tick = nil

	if emote_state.sprite_render then
		if emote_state.sprite_render.sprite and emote_state.sprite_render.sprite.valid then
			emote_state.sprite_render.sprite.destroy()
		end
		if emote_state.sprite_render.light and emote_state.sprite_render.light.valid then
			emote_state.sprite_render.light.destroy()
		end

	end

	emote_state.sprite_render = nil
end

return normalize
