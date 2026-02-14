local debug = require("scripts.utilities.debug")
local audio = require("scripts.utilities.audio")

local BM = require("scripts.constants.biters").BITER_MAP

local pet_audio = {}

function pet_audio.play_for_size(player_index, entry)
	local player = game.get_player(player_index)
	local biter_size = entry.biter_tier or "pet_small_biter_baby"
	local sound = BM[biter_size].sound

	if sound then audio.play_pet_sound(player, entry, sound) end
end

return pet_audio
