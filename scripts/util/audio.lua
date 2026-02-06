local debug = require("scripts.util.debug")
local audio = {}

function audio.play_pet_sound(player, entry, sound, volume)
	local pet = entry.unit
	if not (pet and pet.valid and player and player.valid and sound) then return end

	-- Randomize pet's emote volume.
	local random_volume = volume or (0.7 + math.random() * 0.3)

	player.play_sound {
		path = sound,
		position = pet.position,
		volume_modifier = random_volume or 1.0
	}
end

function audio.play_global_sound(player, sound, volume)
	if not (player and player.valid and sound) then return end
	game.play_sound {
		path = sound,
		volume_modifier = volume or 1.0
	}
end

return audio
