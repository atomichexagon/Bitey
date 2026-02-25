local debug = require("scripts.utilities.debug")
local pet_state = require("scripts.core.pet_state")

local LC = require("scripts.constants.lifecycle")

local pet_gui = {}

-- Pet attributes.
local function build_stats(parent, player, pet, gui_stats)
	local table = parent.add {
		type = "table",
		column_count = 2,
		vertical_centering = false
	}
	table.style.horizontal_spacing = 20
	table.style.top_margin = 4

	local left_column = table.add {
		type = "flow",
		direction = "vertical"
	}
	left_column.style.left_margin = 20

	local right_column = table.add {
		type = "flow",
		direction = "vertical"
	}
	right_column.style.left_margin = 10
	right_column.style.right_margin = 25

	local function add_stat(flow, icon, label, value, color, bottom_margin)
		flow.add {
			type = "label",
			caption = icon .. " " .. label,
			style = "semibold_label"
		}

		local progressbar = flow.add {
			type = "progressbar",
			value = value,
			style = "burning_progressbar"
		}
		progressbar.style.width = 200
		progressbar.style.bottom_margin = bottom_margin
		progressbar.style.color = color

		return progressbar
	end

	-- Left column stats.
	gui_stats.health = add_stat(left_column, "[img=virtual-signal/signal-heart]", "Health", pet.health / pet.max_health, {
		r = 0.2,
		g = 0.8,
		b = 0.2
	}, 15)
	gui_stats.happiness = add_stat(left_column, "[img=ecstatic]", "Happiness", pet_state.get_happiness(player.index) / 100,
			{
				r = 0.2,
				g = 0.8,
				b = 0.2
			}, 15)
	gui_stats.friendship = add_stat(left_column, "[img=entity/character]", "Friendship",
			pet_state.get_friendship(player.index) / 100, {
				r = 0.2,
				g = 0.8,
				b = 0.2
			}, 15)
	gui_stats.morph = add_stat(left_column, "[img=entity/medium-spitter]", "Morph",
			pet_state.get_morph(player.index) / 100, {
				r = 0.8,
				g = 0.8,
				b = 0.2
			}, 15)

	-- Right column stats.
	gui_stats.hunger = add_stat(right_column, "[item=raw-fish]", "Hunger", pet_state.get_hunger(player.index) / 100, {
		r = 0.8,
		g = 0.2,
		b = 0.2
	}, 15)
	gui_stats.thirst = add_stat(right_column, "[img=fluid/water]", "Thirst", pet_state.get_thirst(player.index) / 100, {
		r = 0.8,
		g = 0.2,
		b = 0.2
	}, 15)
	gui_stats.tiredness = add_stat(right_column, "[img=virtual-signal/signal-battery-full]", "Tiredness",
			pet_state.get_tiredness(player.index) / 100, {
				r = 0.8,
				g = 0.2,
				b = 0.2
			}, 15)
	gui_stats.boredom = add_stat(right_column, "[item=wood]", "Boredom", pet_state.get_boredom(player.index) / 100, {
		r = 0.8,
		g = 0.2,
		b = 0.2
	}, 15)
end

-- Title bar elements.
local function build_titlebar(parent)
	local titlebar = parent.add {
		type = "flow",
		name = "title_bar",
		direction = "horizontal"
	}

	titlebar.add {
		type = "label",
		style = "frame_title",
		caption = "Pet status",
		ignored_by_interaction = true
	}

	local filler = titlebar.add {
		type = "empty-widget",
		style = "draggable_space_header"
	}
	filler.style.horizontally_stretchable = true
	filler.style.height = 24
	filler.drag_target = parent

	titlebar.add {
		type = "sprite-button",
		name = "close_pet_gui",
		sprite = "utility/close",
		style = "frame_action_button",
		mouse_button_filter = {
			"left"
		}
	}
end

-- Pet camera camera.
local function build_camera(parent, pet, gui)
	gui.camera = parent.add {
		type = "camera",
		name = "pet_camera",
		position = pet.position,
		surface_index = pet.surface.index,
		zoom = 1.5,
		entity = pet
	}
	gui.camera.style.width = 175
	gui.camera.style.height = 225
end

-- Pet attributes and camera table.
local function build_stats_and_camera(parent, player, pet, gui)
	local table = parent.add {
		type = "table",
		column_count = 2
	}
	table.style.vertical_align = "center"
	build_camera(table, pet, gui)
	build_stats(table, player, pet, gui.stats)
end

-- Subheader.
local function build_header(parent, entry)
	local pet_name = entry.pet_given_name or LC.PET_DEFAULT_NAME or "Bitey"
	local header = parent.add {
		type = "frame",
		name = "pet_header_frame",
		direction = "horizontal",
		style = "subheader_frame"
	}
	header.style.horizontally_stretchable = true
	header.style.vertical_align = "center"
	header.style.left_padding = 20

	local command_switch = header.add {
		type = "switch",
		name = "pet_guard",
		switch_state = (entry.guard_position and "right") or "left",
		left_label_caption = "Follow  ",
		right_label_caption = "  Guard"
	}
	command_switch.style.top_margin = 2

	local label = header.add {
		type = "label",
		name = "pet_name_label",
		caption = pet_name,
		style = "caption_label"
	}
	label.style.left_margin = 48

	local edit_button = header.add {
		type = "sprite-button",
		name = "edit_pet_name_button",
		sprite = "utility/rename_icon",
		style = "mini_button_aligned_to_text_vertically_when_centered",
		tooltip = "Rename your pet"
	}
	edit_button.style.right_margin = 40
end

-- Content frame.
local function build_content(parent, player, pet, entry, gui)
	local content = parent.add {
		type = "frame",
		name = "content_frame",
		direction = "vertical",
		style = "inside_shallow_frame_with_padding"
	}
	content.style.padding = 0
	build_header(content, entry)
	build_stats_and_camera(content, player, pet, gui)
end

-- Entry point.
function pet_gui.open_pet_gui(player, pet, gui)
	if not (pet and pet.valid) then return end

	local entry = storage.biter_pet[player.index]
	if not entry then return end

	local screen = player.gui.screen
	if screen.pet_main_window then screen.pet_main_window.destroy() end

	local main_frame = pet_gui.build_main_window(screen)
	player.opened = main_frame

	build_titlebar(main_frame)
	build_content(main_frame, player, pet, entry, gui)
end

-- Main window frame.
function pet_gui.build_main_window(screen)
	local frame = screen.add {
		type = "frame",
		name = "pet_main_window",
		direction = "vertical",
		style = "inset_frame_container_frame"
	}

	frame.auto_center = true
	return frame
end

local function smooth_step(current, target, speed)
	return current + (target - current) * speed
end

function pet_gui.update_pet_gui_progressbars(player_index)
	local player = game.get_player(player_index)
	if not player then return end

	local screen = player.gui.screen
	if not (screen.pet_main_window and screen.pet_main_window.valid) then return end

	local entry = storage.biter_pet[player_index]
	if not (entry and entry.unit and entry.gui) then return end

	local player_gui = entry.gui
	if player_gui.camera.entity ~= entry.unit then player_gui.camera.entity = entry.unit end

	for key, progressbar in pairs(player_gui.stats) do
		if progressbar and progressbar.valid then
			local getter = pet_state["get_" .. key]
			if key == "health" then
				progressbar.value = entry.unit.health / entry.unit.max_health
			else
				local current = progressbar.value
				local target = getter(player_index) / 100

				local new_value = smooth_step(current, target, 0.2)
				progressbar.value = new_value
			end
		end
	end
end

return pet_gui
