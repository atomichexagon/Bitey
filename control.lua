local console_commands = require("scripts.utilities.commands")
local debug = require("scripts.utilities.debug")
local events = require("scripts.core.events")

-- Event wiring.
local function register_runtime_events()
	script.on_event(defines.events.on_tick, events.on_tick)
	script.on_event(defines.events.on_player_created, events.on_player_created)
	script.on_event(defines.events.on_entity_died, events.on_entity_died)
	script.on_event(defines.events.on_cutscene_cancelled, events.on_cutscene_cancelled)
	script.on_event(defines.events.on_research_finished, events.on_research_finished)
	script.on_event(defines.events.on_entity_damaged, events.on_entity_damaged)
end

script.on_init(function()
	events.on_init()
	register_runtime_events()
end)

script.on_load(function()
	events.on_load()
	register_runtime_events()
end)

-- TODO: Try to reproduce bug that caused nest remnants to no spawn after new game start.
script.on_configuration_changed(function(cfg)
	events.on_configuration_changed(cfg)
end)
