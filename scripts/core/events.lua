local debug = require("scripts.utilities.debug")
local pet_lifecycle = require("scripts.core.pet_lifecycle")
local pet_state = require("scripts.core.pet_state")
local pet_spawn = require("scripts.core.pet_spawn")
local pet_init = require("scripts.core.pet_init")
local pet_behavior = require("scripts.core.pet_behavior")
local pet_memorial = require("scripts.core.pet_memorial")
local pet_visuals = require("scripts.core.pet_visuals")
local pet_animation = require("scripts.core.pet_animation")
local pet_gui = require("scripts.core.pet_gui")
local notifications = require("scripts.utilities.notifications")

local DC = require("scripts.constants.debug")
local LC = require("scripts.constants.lifecycle")

local events = {}

function events.on_init()
	pet_init.initialize_storage()
	pet_init.create_orphan_force()
	pet_init.check_existing_research()

	for _, player in pairs(game.players) do
		storage.mod_initialized = true
		pet_lifecycle.ensure_initial_pet(player.index)
	end
end

-- TODO: Test mod on existing save that didn't have mod enabled to make sure this prevent pet cloning bug.
function events.on_configuration_changed(cfg)
	pet_init.initialize_storage()
	pet_init.create_orphan_force()
	pet_init.check_existing_research()

	if not storage.mod_initialized then
		storage.mod_initialized = true
		for _, player in pairs(game.players) do pet_lifecycle.ensure_initial_pet(player.index) end
	end
end

function events.on_load()
	-- Rebind metatables at some point.
end

local function evaluate_pet_damage(player_index, entry, event, entity)
	if entry.unit ~= entity then return end
	pet_behavior.on_pet_damaged(player_index, entry, event, entity)
end

local function compute_diminished_total(buff_list)
	local count = #buff_list
	local magnitude = buff_list[1].magnitude

	local total = 0
	local factor = 1.0

	for i = 1, count do
		total = total + magnitude * factor
		factor = factor * 0.5
	end

	return total
end

local function apply_damage_buffs(entry, event)
	local pet = entry.unit
	if event.cause ~= pet then return end
	if not entry.combat_buffs then return end

	local buff_type = "damage"
	local grouped
	for _, buff in ipairs(entry.combat_buffs) do
		if buff.type == "damage" then
			grouped = grouped or {}
			table.insert(grouped, buff)
		end
	end

	if grouped then
		local total = compute_diminished_total(grouped)
		local bonus = event.final_damage_amount * total
		event.entity.damage(bonus, pet.force, event.damage_type)
	end
end

local function apply_damage_resistances(player_index, entry, event)
	local pet = entry.unit
	if event.entity ~= pet then return end

	debug.render_damage_type(player_index, event.damage_type.name)
	if not entry.combat_buffs then return end
	local damage_type = event.damage_type.name

	local grouped
	for _, buff in ipairs(entry.combat_buffs) do
		if buff.type == damage_type or buff.type == "all" then
			grouped = grouped or {}
			table.insert(grouped, buff)
		end
	end

	if grouped then
		local total = compute_diminished_total(grouped)
		local reduction = event.final_damage_amount * total
		pet.health = pet.health + reduction
	end
end

function events.on_entity_damaged(event)
	local entity = event.entity
	if not (entity and entity.valid) then return end

	for player_index, entry in pairs(storage.biter_pet) do
		evaluate_pet_damage(player_index, entry, event, entity)
		apply_damage_buffs(entry, event)
		apply_damage_resistances(player_index, entry, event)
	end
end

function events.on_player_created(event)
	pet_lifecycle.ensure_initial_pet(event.player_index)
end

function events.on_tick(event)
	pet_lifecycle.on_tick(event)
	pet_animation.animate_pet_reaction_icon()
end

function events.on_entity_died(event)
	pet_lifecycle.on_entity_died(event)
end

function events.on_cutscene_cancelled(event)
	local entry = pet_lifecycle.ensure_pet_entry(event.player_index)
	pet_behavior.record_intro_cinematic_end_tick(event.player_index, entry)
	local player = game.get_player(event.player_index)

	-- Find a suitable position to spawn the biter and nest.
	if not storage.pet_spawn_point then
		storage.pet_spawn_point = pet_spawn.choose_orphan_spawn(player.surface, player.position)
	end
	if not entry.unit or not entry.unit.valid then pet_spawn.spawn_orphan_baby(player, entry, true) end
end

function events.on_research_finished(event)
	pet_behavior.on_research_finished(event)
end

function events.on_marked_for_deconstruction(event)
	local entry = pet_lifecycle.ensure_pet_entry(event.player_index)
	local entity = event.entity
	if entity.type ~= "tree" then return end

	for player_index, entry in pairs(storage.biter_pet) do
		if (entry.fetch_plays and entry.fetch_plays >= 10) or DC.DEBUG_BYPASS_DECONSTRUCTION_GATE then
			pet_state.set_tree_target(player_index, entity)
		end
	end
end

function events.pet_open_gui(event)
	local player = game.get_player(event.player_index)
	if not (player and player.valid) then return end

	local target = player.selected
	if not (target and target.valid and target.type == "unit") then return end

	local entry = storage.biter_pet[event.player_index]
	entry.gui = entry.gui or {}
	entry.gui.stats = entry.gui.stats or {}
	entry.gui.camera = entry.gui.camera or nil

	if not (entry and entry.unit and entry.unit.valid) then return end
	if not (entry.unit.unit_number == target.unit_number) then return end

	pet_gui.open_pet_gui(player, entry.unit, entry.gui)
end

function events.pet_close_gui(event)
	local player = game.get_player(event.player_index)
	local screen = player.gui.screen
	if screen.pet_main_window then
		screen.pet_main_window.destroy()
		local entry = storage.biter_pet[event.player_index]
		entry.gui = nil
		return
	end
end

function events.on_gui_closed(event)
	if event.element and event.element.name == "pet_main_window" then
		local player = game.get_player(event.player_index)
		event.element.destroy()
		local entry = storage.biter_pet[event.player_index]
		entry.gui = nil
		if player.opened == event.element then player.opened = nil end
	end
end

function events.pet_interact(event)
	local player = game.get_player(event.player_index)
	if not (player and player.valid) then return end

	local target = player.selected
	if not (target and target.valid and target.type == "unit") then return end

	local entry = storage.biter_pet[event.player_index]

	if entry and entry.unit and entry.unit.valid then
		if entry.unit.unit_number == target.unit_number then
			pet_state.pause(event.player_index, 120)
			pet_state.force_emote(event.player_index, entry, "petting")
			notifications.petting_biter_flavor_text(player, entry)
		end
	end
end

function events.on_gui_click(event)
	if event.element.name == "close_pet_gui" then
		local player = game.get_player(event.player_index)
		if player.gui.screen.pet_main_window then
			player.gui.screen.pet_main_window.destroy()
			local entry = storage.biter_pet[event.player_index]
			entry.gui = nil
		end
		return
	end

	if event.element.name == "edit_pet_name_button" then
		local header = event.element.parent
		local old_label = header.pet_name_label

		old_label.visible = false
		event.element.visible = false

		local textfield = header.add {
			type = "textfield",
			name = "pet_name_text_field",
			text = old_label.caption,
			lose_focus_on_confirm = true
		}
		textfield.style.width = 200
		textfield.style.left_margin = 47
		textfield.style.top_margin = 1
		textfield.focus()
		textfield.select_all()
	end

end

function events.on_gui_text_changed(event)
	if event.element.name == "pet_name_text_field" then
		local name = event.element.text
		local max_length = 24

		if #name > max_length then
			event.element.text = name:sub(1, max_length)
			event.element.select(#event.element.text, #event.element.text)
		end
	end
end

function events.on_gui_confirmed(event)
	if event.element.name == "pet_name_text_field" then
		local entry = storage.biter_pet[event.player_index]
		if not (entry and entry.unit) then return end

		local player_input = event.element.text
		local header = event.element.parent

		local old_name = entry.pet_given_name or LC.PET_DEFAULT_NAME or "Bitey"
		local new_name = player_input:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")

		if new_name == "" or not new_name then new_name = LC.PET_DEFAULT_NAME or "Bitey" end
		entry.pet_given_name = new_name

		header.pet_name_label.caption = entry.pet_given_name
		header.pet_name_label.visible = true

		event.element.destroy()
		header.edit_pet_name_button.visible = true

		if old_name ~= new_name then
			events.pet_close_gui(event)
			local player = game.get_player(event.player_index)
			notifications.rename_pet_flavor_text(player, entry, new_name)
		end
	end
end

function events.on_built_entity(event)
	local entity = event.entity
	
	local memorial_names = {
		["pet-biter-memorial"] = true,
		["pet-spitter-memorial"] = true
	
	}
	if not memorial_names[entity.name] then return end

	local player = game.get_player(event.player_index)
	local entry = storage.biter_pet[player.index]

	pet_memorial.memorials[entity.unit_number] = {
		entity = entity,		
		force = player.force,
		player_index = event.player_index,
		bond_level = entry.last_death_bond_level or 1,
		species = entry.current_species,
		was_crafting = false
	}
end

function events.on_player_main_inventory_changed(event)
	local player = game.get_player(event.player_index)
	if not (player and player.valid) then return end

	local inventory = player.get_main_inventory()
	if not inventory then return end

	if inventory.get_item_count("pet-biter-remains") > 0 then
		local technology = player.force.technologies["pet-biter-grief-processing"]
		if technology and not technology.researched then
			game.print("test")
			technology.researched = true
			technology.enabled = true
			player.unlock_achievement("pet-fallen")
		end
	end

	if inventory.get_item_count("pet-spitter-remains") > 0 then
		local technology = player.force.technologies["pet-spitter-grief-processing"]
		if technology and not technology.researched then
			technology.researched = true
			technology.enabled = true
			player.unlock_achievement("pet-fallen")
		end
	end
end

function events.on_player_mined_entity(event)
	local entity = event.entity
	if entity.name ~= "pet-biter-remains-placeholder" and entity.name ~= "pet-spitter-remains-placeholder" then return end

	local surface = entity.surface
	local position = entity.position

	for _, corpse in pairs(surface.find_entities_filtered {
		position = position,
		type = "corpse",
		radius = 1
	}) do corpse.destroy() end
end

function events.on_gui_switch_state_changed(event)
	if event.element.name == "pet_guard" then
		local entry = storage.biter_pet[event.player_index]
		if not (entry and entry.unit) then return end

		local pet = entry.unit
		if not (pet and pet.valid) then return end

		local player_index = event.player_index
		local player = game.get_player(player_index)

		if event.element.switch_state == "left" then
			entry.lazy_guard = false
			entry.guard_position = nil
			pet_lifecycle.stop_guarding(player_index, entry, pet)
			notifications.follow_flavor_text(player, entry)
		else
			entry.lazy_guard = true
			entry.guard_position = pet.position
			pet_lifecycle.start_guarding(player_index, entry, pet)
			notifications.guard_flavor_text(player, entry)
		end
	end
	events.pet_close_gui(event)
end
return events
