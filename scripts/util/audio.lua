local debug = require("scripts.util.debug")
local audio = {}

function audio.play_pet_sound(player, entry, sound, volume)
	local pet = entry.unit
	if not (pet and pet.valid and player and player.valid and sound) then
		return
	end

	-- Play audio local to the biter.
	player.play_sound {
		path = sound,
		position = pet.position,
		volume_modifier = volume or 1.0
	}
end

function audio.play_global_sound(player, sound, volume)

	if not (player and player.valid and sound) then
		return
	end

	player.play_sound {
		path = sound,
		volume_modifier = volume or 1.0
	}
end

return audio
