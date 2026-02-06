local debug = require("scripts.util.debug")
local audio = require("scripts.util.audio")

local BITER_CONSTANTS = require("scripts.constants.biters")
local BITER_MAP = BITER_CONSTANTS.BITER_MAP

local pet_audio = {}

function pet_audio.play_for_size(player_index, entry)
	local player = game.get_player(player_index)
	local biter_size = entry.biter_tier_friendly_name or "pet_biter_baby"
	local sound = BITER_MAP[biter_size].sound

	if sound then audio.play_pet_sound(player, entry, sound) end
end

return pet_audio
