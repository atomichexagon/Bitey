local events = require("scripts.core.events")
local debug = require("scripts.util.debug")
local pet_lifecycle = require("scripts.core.pet_lifecycle")
local pet_state = require("scripts.core.pet_state")
local text = require("scripts.util.text_format")

local DC = require("scripts.constants.debug") -- Debug constants.

-- Console commands.
commands.add_command("bpstatus", DC.ICON .. string.format("%s %s", DC.ICON, text.format("Show pet status for the calling player.")), function(cmd)
	local player = game.get_player(cmd.player_index)
	if not player then
		return
	end
	local state = pet_state.get(player.index)
	game.print(string.format("%s %s %s", DC.ICON, text.format("Pet state:", "l"), pet_state.debug_dump(player.index)))
	pet_lifecycle.print_status_for_players(player)
end)

commands.add_command("bpdebug", DC.ICON .. string.format("%s %s", DC.ICON, text.format("Set debug level for biter-pet mod.")), function(cmd)
	local lvl = tonumber(cmd.parameter)
	if lvl then
		debug.set_level(lvl)
	else
		game.print(string.format("%s %s %s", DC.ICON, text.format("Usage:", "l"), text.format("/bpdebug [0-4]")))
	end
end)

-- Event wiring.
local function register_runtime_events()
	script.on_event(defines.events.on_tick, events.on_tick)
	script.on_event(defines.events.on_player_created, events.on_player_created)
	script.on_event(defines.events.on_entity_died, events.on_entity_died)
	script.on_event(defines.events.on_cutscene_cancelled, events.on_cutscene_cancelled)
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

