local debug = require("scripts.util.debug")
local events = require("scripts.core.events")
local pet_circadian = require("scripts.core.pet_circadian")
local pet_lifecycle = require("scripts.core.pet_lifecycle")
local pet_state = require("scripts.core.pet_state")
local t = require("scripts.util.text_format")

local DC = require("scripts.constants.debug")

-- Console commands.
commands.add_command("bpstatus", string.format("%s %s", DC.ICON, t.f("Show pet status for the calling player.")),
		function(command)
			if not command.player_index then return end
			local player = game.get_player(command.player_index)
			if not player then return end

			local state = pet_state.get(player.index)
			local ps_dump = pet_state.debug_dump(player.index)
			local pl_dump = pet_lifecycle.debug_dump(player)

			game.print(string.format("%s%s\n%s\n%s", DC.ICON, t.fh("Pet state:", "i"), ps_dump, pl_dump))
		end)

commands.add_command("bpdebug", string.format("%s %s", DC.ICON, t.f("Set debug level for biter-pet mod.")),
		function(command)
			if not command.player_index then return end
			local player = game.get_player(command.player_index)
			if not player then return end

			local level = tonumber(command.parameter)
			if level then
				debug.set_level(level, player)
			else
				game.print(string.format("%s %s", DC.ICON, t.f("Usage: /bpdebug [" .. t.f("0-4", "f") .. "]")))
			end
		end)

commands.add_command("bpsleep", "Put the pet to sleep.", function(command)
	if not command.player_index then return end
	local player_index = command.player_index
	local entry = storage.biter_pet[command.player_index]
	if not entry then return end

	if entry.wake_state == "sleeping" then
		game.print(string.format("%s %s", DC.ICON, "The pet is already sleeping."))
	else
		game.print(string.format("%s %s", DC.ICON, "Putting the pet to sleep."))
		pet_circadian.enter_sleep(player_index, entry)
	end
end)

commands.add_command("bpwake", "Wake the pet up from sleep.", function(command)
	if not command.player_index then return end
	local player_index = command.player_index
	local entry = storage.biter_pet[command.player_index]
	if not entry then return end
	
	if entry.wake_state == "awake" then
		game.print(string.format("%s %s", DC.ICON, "The pet is already awake."))
	else
		game.print(string.format("%s %s", DC.ICON, "Waking the pet up from sleep."))
		pet_circadian.exit_sleep(player_index, entry)
	end
end)

commands.add_command("bpvisual", string.format("%s %s", DC.ICON, t.f("Visualize pet triggers, pathing and behaviors.")),
		function(command)
			local enabled = debug.toggle_visualizer()
			if enabled then
				game.print(string.format("%s %s %s", DC.ICON, "Visualizer", t.f("enabled", "f")))
			else
				game.print(string.format("%s %s %s", DC.ICON, "Visualizer", t.f("disabled", "e")))
			end
		end)

-- Event wiring.
local function register_runtime_events()
	script.on_event(defines.events.on_tick, events.on_tick)
	script.on_event(defines.events.on_player_created, events.on_player_created)
	script.on_event(defines.events.on_entity_died, events.on_entity_died)
	script.on_event(defines.events.on_cutscene_cancelled, events.on_cutscene_cancelled)
	script.on_event(defines.events.on_research_finished, events.on_research_finished)
end

script.on_init(function()
	events.on_init()
	register_runtime_events()
end)

script.on_load(function()
	events.on_load()
	register_runtime_events()
end)

script.on_configuration_changed(function(cfg)
	events.on_configuration_changed(cfg)
end)
