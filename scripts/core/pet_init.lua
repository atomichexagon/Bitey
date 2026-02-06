local pet_init = {}

function pet_init.initialize_storage()
	storage.biter_pet = storage.biter_pet or {}
	storage.pet_spawn_point = storage.pet_spawn_point or nil

	storage.last_mood = storage.last_mood or {}
	storage.emote_state = storage.emote_state or {}
end

function pet_init.create_orphan_force()
	if not game.forces["pet_orphan"] then game.create_force("pet_orphan") end

	local orphan = game.forces["pet_orphan"]
	local enemy = game.forces["enemy"]
	local player_force = game.forces["player"]

	orphan.set_cease_fire(enemy, true)
	enemy.set_cease_fire(orphan, true)

	orphan.set_cease_fire(player_force, true)
	player_force.set_cease_fire(orphan, true)
end

function pet_init.check_existing_research()
	for _, force in pairs(game.forces) do
		if force.technologies["fluid-handling"] and force.technologies["fluid-handling"].researched then
			for _, player in pairs(force.players) do
				local s = ensure_state(player.index)
				s.has_fluid_handling = true
			end
		end
	end
end

return pet_init
