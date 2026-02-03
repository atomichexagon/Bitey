local DC = require("scripts.constants.debug") -- Debug constants.

local dbg = {}

-- Debug levels.
dbg.level = {
	none = 0,
	error = 1,
	warn = 2,
	info = 3,
	trace = 4
}

-- Default debug level.
dbg.current_level = dbg.level.trace

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

	-- Safe print (won't crash if game isn't ready).
	if game and game.print then
		game.print(msg)
	end
end

local function get_caller_module()
	-- Get the source path of this file to avoid reporting own functions.
	local self_source = debug.getinfo(1, "S").source

	-- Iterate up the call stack. Start at level 3 to skip debug.getinfo and this function.
	local level = 3
	while true do
		local info = debug.getinfo(level, "Sln")

		-- If we're past the end of the call stack, we can't find a suitable caller.
		if not info then
			return { filename = "unknown", func = "?" }
		end

		-- Looking for frame that comes from a loaded Lua file outside this module.
		if info.source and info.source:sub(1, 1) == "@" and info.source ~= self_source then
			local filename = info.source:match("([^/\\]+)$") or info.source
			filename = filename:gsub("%.lua$", "")
			local func_name = info.name or "?"
			return { filename = filename, func = func_name }
		end

		-- Wrong frame, move up the stack.
		level = level + 1
	end
end

local function log(level, message)
	if level > dbg.current_level then
		return
	end

	local module_info = get_caller_module()
	local tick = game and game.tick or 0
	local prefix = string.format("[BP][%s][%d][%s][%s] ", (level == dbg.level.error and "ERROR") or (level == dbg.level.warn and "WARN") or
			(level == dbg.level.info and "INFO") or "TRACE", tick, module_info.filename, module_info.func)

	safe_print(module_info.filename, prefix .. tostring(message))
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

-- Allow runtime toggling via /petdebuglevel console command.
function dbg.set_level(level)
	dbg.current_level = level
	dbg.info("debug", "Debug level set to " .. tostring(level))
end

return dbg
