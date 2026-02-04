local text = require("scripts.util.text_format")

local DC = require("scripts.constants.debug") -- Debug constants.

local dbg = {}

-- Debug levels.
dbg.level = {
	trace = 4,
	info = 3,
	warn = 2,
	error = 1,
	none = 0
}

-- Default debug level.
dbg.current_level = dbg.level.info

local last_print_tick = {}

-- Internal safe message printer.
local function safe_print(key, msg)
	local tick = game and game.tick or 0

	-- Rate limit by key.
	if DC.DEBUG_ENABLE_RATE_LIMITER then
		if last_print_tick[key] and tick - last_print_tick[key] < DC.DEBUG_RATE_LIMIT then
			return
		end
	end

	last_print_tick[key] = tick

	if game and game.print then
		game.print(msg)
	end
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
	if level > dbg.current_level then
		return
	end

	local module_info = get_caller_module()
	local tick = game and game.tick or 0
	local formatted_prefix = string.format("%s %s %s.%s", DC.ICON,
			(level == dbg.level.error and text.format("ERROR", "e")) or (level == dbg.level.warn and text.format("WARN", "w")) or
					(level == dbg.level.info and text.format("INFO", "i")) or text.format("TRACE", "t"), text.format(module_info.filename, "c"), text.format(module_info.func .. "()", "f"))
	local formatted_message = string.format("%s", text.format(message))
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

-- Allows debug level configuration via command console.
function dbg.set_level(level)
	dbg.current_level = level
	local formatted_level = text.format(level, "f")
	local formatted_message = string.format(text.format("Debug level set to [%s]"), level_string)	
	dbg.info(formatted_message)
end

return dbg
