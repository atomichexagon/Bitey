local debug = {}

-- Debug levels.
debug.level = {none = 0, error = 1, warn = 2, info = 3, trace = 4}

-- Default level (change this to control verbosity).
debug.current_level = debug.level.info

-- Optional: rate limiting (in ticks).
local RATE_LIMIT = 30
local last_print_tick = {}

-- Internal safe message printer.
local function safe_print(key, msg)
	local tick = game and game.tick or 0

	-- Rate limit by key.
	if last_print_tick[key] and tick - last_print_tick[key] < RATE_LIMIT then
		return
	end

	last_print_tick[key] = tick

	-- Safe print (won't crash if game isn't ready).
	if game and game.print then game.print(msg) end
end

-- Core logging function.
local function log(level, subsystem, message)
	if level > debug.current_level then return end

	local tick = game and game.tick or 0
	local prefix = string.format("[BP][%s][%d][%s] ",
								 (level == debug.level.error and "ERROR") or
									 (level == debug.level.warn and "WARN") or
									 (level == debug.level.info and "INFO") or
									 "TRACE", tick, subsystem or "core")

	safe_print(subsystem or "core", prefix .. tostring(message))
end

-- Public helpers.
function debug.error(subsystem, message)
	log(debug.level.error, subsystem, message)
end

function debug.warn(subsystem, message) log(debug.level.warn, subsystem, message) end

function debug.info(subsystem, message) log(debug.level.info, subsystem, message) end

function debug.trace(subsystem, message)
	log(debug.level.trace, subsystem, message)
end

-- Allow runtime toggling via /petdebuglevel console command.
function debug.set_level(level)
	debug.current_level = level
	debug.info("debug", "Debug level set to " .. tostring(level))
end

return debug
