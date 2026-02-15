local t = require("scripts.utilities.text_format")

local DC = require("scripts.constants.debug")
local TF = require("scripts.constants.text_format")
local LC = require("scripts.constants.lifecycle")

local pet_debug = {}

-- Debug levels.
pet_debug.level = {
	none = 0,
	error = 1,
	warn = 2,
	info = 3,
	trace = 4
}

pet_debug.visualizers_enabled = DC.DEBUG_VISUALIZERS_ENABLED
pet_debug.mood_debugging_enabled = DC.DEBUG_MOOD_ENABLED

pet_debug.level_name = {}

-- Debug levels reverse map.
for name, value in pairs(pet_debug.level) do pet_debug.level_name[value] = name end

pet_debug.current_level = DC.DEBUG_DEFAULT_LEVEL

local last_print_tick = {}

local function safe_print(key, message)
	local tick = game and game.tick or 0

	-- Rate limit by message key.
	if DC.DEBUG_ENABLE_RATE_LIMITER then
		if last_print_tick[key] and tick - last_print_tick[key] < DC.DEBUG_RATE_LIMIT then return end
	end

	last_print_tick[key] = tick

	if game and game.print then game.print(message) end
end

local function get_caller_module()
	-- Get the source path of this file to avoid reporting own functions.
	local self_source = debug.getinfo(1, "S").source

	-- Start at level 3 to skip debug.getinfo and this function and iterate up call stack.
	local level = 3
	while true do
		local info = debug.getinfo(level, "Sln")

		-- If we're past the end of the call stack then we can't find a suitable caller.
		if not info then
			return {
				filename = "unknown",
				func = "?"
			}
		end

		-- Looking for frame that comes from a loaded Lua file outside of this module.
		if info.source and info.source:sub(1, 1) == "@" and info.source ~= self_source then
			local filename = info.source:match("([^/\\]+)$") or info.source
			filename = filename:gsub("%.lua$", "")
			local func_name = info.name or "?"
			return {
				filename = filename,
				func = func_name
			}
		end

		-- Move up the stack if wrong frame.
		level = level + 1
	end
end

local function log(level, message)
	if level > pet_debug.current_level then return end

	local module_info = get_caller_module()
	local tick = game and game.tick or 0
	local formatted_prefix = string.format("%s %s %s.%s", DC.ICON,
			(level < 0 and t.f("COMMAND", "a")) or (level == pet_debug.level.error and t.f("ERROR", "e")) or
					(level == pet_debug.level.warn and t.f("WARN", "w")) or (level == pet_debug.level.info and t.f("INFO", "i")) or
					t.f("TRACE", "t"), t.f(module_info.filename, "c"), t.f(module_info.func .. "()", "f"))
	local formatted_message = string.format("%s", t.f(message))
	local assembled_console_line = string.format("%s %s", formatted_prefix, formatted_message)
	safe_print(module_info.filename, assembled_console_line)
end

-- Public helpers.
function pet_debug.error(message)
	log(pet_debug.level.error, message)
end

function pet_debug.warn(message)
	log(pet_debug.level.warn, message)
end

function pet_debug.info(message)
	log(pet_debug.level.info, message)
end

function pet_debug.trace(message)
	log(pet_debug.level.trace, message)
end

function pet_debug.always(message)
	log(-1, message)
end

local function get_font_color_from_level(level)
	if level == pet_debug.level.none then
		return TF.LABEL_COLOR
	elseif level == pet_debug.level.error then
		return TF.ERROR_COLOR
	elseif level == pet_debug.level.warn then
		return TF.WARN_COLOR
	elseif level == pet_debug.level.info then
		return TF.INFO_COLOR
	elseif level == pet_debug.level.trace then
		return TF.TRACE_COLOR
	else
		return TF.MESSAGE_COLOR
	end
end

local function update_player_speed(player)
	if pet_debug.current_level > pet_debug.level.none then
		player.character_running_speed_modifier = 2
	else
		player.character_running_speed_modifier = 0
	end
end

-- Allows debug level configuration via command console.
function pet_debug.set_level(new_level, player)
	if not player then return end

	pet_debug.current_level = new_level

	local level_color = get_font_color_from_level(new_level)
	local uc_level_name = string.upper(pet_debug.level_name[pet_debug.current_level])
	local formatted_message = string.format(t.f("%s Debug logging level set to %s - [color=%s]%s[/color] "), DC.ICON,
			tostring(pet_debug.current_level), level_color, uc_level_name)
	player.print(formatted_message)
end

function pet_debug.render_path_to_target(player_index, pet, target)
	if not pet_debug.visualizers_enabled then return end

	local player = game.get_player(player_index)
	if not (player and player.valid) then return end

	local entry = storage.biter_pet[player_index]
	if entry.debug_line then entry.debug_line.destroy() end

	entry.debug_line = rendering.draw_line {
		color = player.color,
		width = 3,
		from = pet,
		to = target,
		surface = pet.surface,
		draw_on_ground = true,
		time_to_live = 30
	}
end

function pet_debug.render_pet_behavior(player_index, behavior)
	if not pet_debug.visualizers_enabled then return end

	local player = game.get_player(player_index)
	if not (player and player.valid) then return end

	local entry = storage.biter_pet[player_index]
	local pet = entry.unit
	if not (pet and pet.valid) then return end

	if entry.debug_text then entry.debug_text.destroy() end

	local friendly_behavior = string.gsub(behavior:upper(), "_", " ")
	entry.debug_text = rendering.draw_text {
		text = friendly_behavior,
		surface = pet.surface,
		target = {
			entity = pet,
			offset = DC.DEBUG_VISUALIZE_STATE_OFFSET
		},
		color = {
			player.color.r,
			player.color.g,
			player.color.b,
			1
		},
		use_rich_text = true,
		scale = 0.8,
		time_to_live = 30
	}
end

local function render_circle(entry, pet, radius, color)
	entry.debug_radius = rendering.draw_circle {
		color = color,
		radius = radius,
		filled = false,
		width = 1,
		target = pet,
		surface = pet.surface,
		draw_on_ground = true,
		time_to_live = 30
	}
end

function pet_debug.render_behavioral_radius(player_index, pet, radius, radius_type, color)
	if not pet_debug.visualizers_enabled then return end
	if not radius then return end

	local player = game.get_player(player_index)
	if not (player and player.valid) then return end

	local entry = storage.biter_pet[player_index]

	if radius_type == "follow" then
		if entry.debug_follow_radius then entry.debug_follow_radius.destroy() end
		render_circle(entry, pet, radius, DC.DEBUG_FOLLOW_RADIUS_COLOR)
	elseif radius_type == "food_search" then
		if entry.debug_item_search_radius then entry.debug_item_search_radius.destroy() end
		render_circle(entry, pet, radius, DC.DEBUG_ITEM_SEARCH_RADIUS_COLOR)
	elseif radius_type == "eat" then
		if entry.debug_interact_radius then entry.debug_interact_radius.destroy() end
		render_circle(entry, pet, radius, DC.DEBUG_INTERACT_RADIUS_COLOR)
	elseif radius_type == "attack" then
		if entry.debug_attack_radius then entry.debug_attack_radius.destroy() end
		render_circle(entry, pet, radius, DC.DEBUG_ATTACK_RADIUS_COLOR)
	else
		if entry.debug_radius then entry.debug_radius.destroy() end
		render_circle(entry, pet, radius, color or player.color)
	end
end

function pet_debug.visualize_behavioral_radii(player_index)
	if not pet_debug.visualizers_enabled then return end
	local entry = storage.biter_pet[player_index]
	local pet = entry.unit
	if not (pet and pet.valid) then return end

	local follow_radius = LC.FOLLOW_RADIUS_BY_TIER[pet.name] or LC.PET_FOLLOW_RADIUS
	pet_debug.render_behavioral_radius(player_index, pet, follow_radius, "follow")

	local item_search_radius = LC.ITEM_SEARCH_RADIUS
	pet_debug.render_behavioral_radius(player_index, pet, item_search_radius, "food_search")

	local interact_radius = LC.INTERACT_RADIUS
	pet_debug.render_behavioral_radius(player_index, pet, interact_radius, "eat")

	local attack_radius = LC.PET_ATTACK_RADIUS
	pet_debug.render_behavioral_radius(player_index, pet, attack_radius, "attack")
end

function pet_debug.toggle_visualizer()
	pet_debug.visualizers_enabled = not pet_debug.visualizers_enabled
	return pet_debug.visualizers_enabled
end

function pet_debug.toggle_mood_debugging()
	pet_debug.mood_debugging_enabled = not pet_debug.mood_debugging_enabled
	return pet_debug.mood_debugging_enabled
end

return pet_debug
