-- TODO: Add audio function to map correct sounds for biter size and type.
-- TODO: Start tracking biter size and type in storage or somewhere appropriate.
local debug = require("scripts.util.debug")
local audio = require("scripts.util.audio")

local pet_audio = {}

local BITER_SOUND_BY_SIZE = {
	pet_biter_baby = "biter-roar",
	pet_biter_small = "biter-roar",
	pet_biter_large = "biter-roar",

	pet_medium_biter_baby = "biter-roar-mid",
	pet_medium_biter_small = "biter-roar-mid",
	pet_medium_biter_large = "biter-roar-mid",

	pet_big_biter_baby = "biter-roar-big",
	pet_big_biter_small = "biter-roar-big",
	pet_big_biter_large = "biter-roar-big",

	pet_behemoth_biter_baby = "biter-roar-behemoth",
	pet_behemoth_biter_small = "biter-roar-behemoth",
	pet_behemoth_biter_large = "biter-roar-behemoth",

	pet_spitter_baby = "spitter-call-small",
	pet_spitter_small = "spitter-call-small",
	pet_spitter_large = "spitter-call-small",

	pet_medium_spitter_baby = "spitter-call-med",
	pet_medium_spitter_small = "spitter-call-med",
	pet_medium_spitter_large = "spitter-call-med",

	pet_large_spitter_baby = "spitter-call-big",
	pet_large_spitter_small = "spitter-call-big",
	pet_large_spitter_large = "spitter-call-big",

	pet_behemoth_spitter_baby = "spitter-call-behemoth",
	pet_behemoth_spitter_small = "spitter-call-behemoth",
	pet_behemoth_spitter_large = "spitter-call-behemoth"
}

function pet_audio.play_for_size(player_index, entry)
	local player = game.get_player(player_index)
	local biter_size = entry.biter_tier_friendly_name or "pet_biter_baby"
	local sound = BITER_SOUND_BY_SIZE[biter_size]

	if sound then
		audio.play_pet_sound(player, entry, sound)
	end
end

return pet_audio