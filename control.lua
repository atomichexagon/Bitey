local console_commands = require("scripts.utilities.commands")
local debug = require("scripts.utilities.debug")
local events = require("scripts.core.events")
local pet_animation = require("scripts.core.pet_animation")
local pet_lifecycle = require("scripts.core.pet_lifecycle")
local pet_init = require("scripts.core.pet_init")
local pet_memorial = require("scripts.core.pet_memorial")

local memorial_filter = require("scripts.utilities.event_filters").memorial_filter
local remains_filter = require("scripts.utilities.event_filters").remains_filter
local pet_filter = require("scripts.utilities.event_filters").pet_filter
local tree_filter = require("scripts.utilities.event_filters").tree_filter

local death_filter = pet_filter
table.insert(death_filter, tree_filter)

local function register_runtime_events()
	script.on_event(defines.events.on_cutscene_cancelled, events.on_cutscene_cancelled)
	script.on_event(defines.events.on_entity_damaged, events.on_entity_damaged, pet_filter)
	script.on_event(defines.events.on_entity_died, events.on_entity_died, death_filter)
	script.on_event(defines.events.on_gui_click, events.on_gui_click)
	script.on_event(defines.events.on_gui_closed, events.on_gui_closed)
	script.on_event(defines.events.on_gui_confirmed, events.on_gui_confirmed)
	script.on_event(defines.events.on_gui_text_changed, events.on_gui_text_changed)
	script.on_event(defines.events.on_gui_switch_state_changed, events.on_gui_switch_state_changed)
	script.on_event(defines.events.on_marked_for_deconstruction, events.on_marked_for_deconstruction, tree_filter)
	script.on_event(defines.events.on_player_created, events.on_player_created)
	script.on_event(defines.events.on_player_died, events.on_player_died)
	script.on_event(defines.events.on_research_finished, events.on_research_finished)
	script.on_event(defines.events.on_player_mined_entity, events.on_player_mined_entity, remains_filter)
	script.on_event(defines.events.on_built_entity, events.on_built_entity, memorial_filter)
	script.on_event(defines.events.on_unit_group_finished_gathering, events.on_unit_group_finished_gathering)
	script.on_event(defines.events.on_player_driving_changed_state, events.on_player_driving_changed_state)
	script.on_event("pet-close-gui", events.pet_close_gui)
	script.on_event("pet-interact", events.pet_interact)
	script.on_event("pet-open-gui", events.pet_open_gui)
end

script.on_nth_tick(4, function(event)
	pet_animation.animate_pet_reaction_icon()
end)

script.on_nth_tick(17, function(event)
	pet_memorial.on_tick(event)
end)

script.on_nth_tick(29, function(event)
	pet_lifecycle.on_tick(event)
end)

script.on_nth_tick(3601, function(event)
	pet_init.check_existing_research(event)
end)

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
