local t = require("scripts.util.text_format")

local DC = require("scripts.constants.debug") -- Debug constants.
local TF = require("scripts.constants.text_format") -- Text color constants.

local dbg = {}

-- Debug levels.
dbg.level = {
	none = 0,
	error = 1,
	warn = 2,
	info = 3,
	trace = 4
}

-- Debug levels reverse map.
dbg.level_name = {}
for name, value in pairs(dbg.level) do dbg.level_name[value] = name end

-- Default debug level.
dbg.current_level = dbg.level.error

local last_print_tick = {}

-- Internal safe message printer.
local function safe_print(key, msg)
	local tick = game and game.tick or 0

	-- Rate limit by key.
	if DC.DEBUG_ENABLE_RATE_LIMITER then
		if last_print_tick[key] and tick - last_print_tick[key] < DC.DEBUG_RATE_LIMIT then return end
	end

	last_print_tick[key] = tick

	if game and game.print then game.print(msg) end
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
	if level > dbg.current_level then return end

	local module_info = get_caller_module()
	local tick = game and game.tick or 0
	local formatted_prefix = string.format("%s %s %s.%s", DC.ICON,
			(level < 0 and t.f("COMMAND", "a")) or (level == dbg.level.error and t.f("ERROR", "e")) or
					(level == dbg.level.warn and t.f("WARN", "w")) or (level == dbg.level.info and t.f("INFO", "i")) or
					t.f("TRACE", "t"), t.f(module_info.filename, "c"), t.f(module_info.func .. "()", "f"))
	local formatted_message = string.format("%s", t.f(message))
	local assembled_console_line = string.format("%s %s", formatted_prefix, formatted_message)
	safe_print(module_info.filename, assembled_console_line)
end

-- Public helpers.
function dbg.error(message)
	log(dbg.level.error, message)
end

function dbg.warn(message)
	log(dbg.level.warn, message)
end

function dbg.info(message)
	log(dbg.level.info, message)
end

function dbg.trace(message)
	log(dbg.level.trace, message)
end

function dbg.always(message)
	log(-1, message)
end

local function get_font_color_from_level(level)
	if level == dbg.level.none then
		return TF.NONE_COLOR
	elseif level == dbg.level.error then
		return TF.ERROR_COLOR
	elseif level == dbg.level.warn then
		return TF.WARN_COLOR
	elseif level == dbg.level.info then
		return TF.INFO_COLOR
	elseif level == dbg.level.trace then
		return TF.TRACE_COLOR
	else
		return TF.MESSAGE_COLOR
	end
end

local function update_player_speed(player)
	if dbg.current_level > dbg.level.none then
		player.character_running_speed_modifier = 2
	else
		player.character_running_speed_modifier = 0
	end
end

-- Allows debug level configuration via command console.
function dbg.set_level(new_level, player)
	dbg.current_level = new_level

	if (player and player.valid) then
		update_player_speed(player)
		player.insert {
			name = "raw-fish",
			count = 50
		}
	end

	local level_color = get_font_color_from_level(new_level)
	local uc_level_name = string.upper(dbg.level_name[dbg.current_level])
	local formatted_message = string.format(t.f("%s Debug logging level set to %s - [color=%s]%s[/color] "), DC.ICON,
			tostring(dbg.current_level), level_color, uc_level_name)
	game.print(formatted_message)
end

return dbg
