local debug = require("scripts.utilities.debug")
local normalize = require("scripts.utilities.normalize")
local pet_lifecycle = require("scripts.core.pet_lifecycle")
local pet_state = require("scripts.core.pet_state")
local pet_state_machine = require("scripts.core.pet_state_machine")
local t = require("scripts.utilities.text_format")

local MA = require("scripts.constants.state").MUTABLE_ATTRIBUTE_FIELDS
local DC = require("scripts.constants.debug")

local console_commands = {}

local function clamp(value, minimum, maximum)
	if value < minimum then return minimum end
	if value > maximum then return maximum end
	return value
end

local ideal_state = {
	boredom = 0,
	evolution = 100,
	friendship = 100,
	happiness = 100,
	hunger = 0,
	morph = 50,
	thirst = 0,
	tiredness = 0
}

-- Console commands.
commands.add_command("bpset", string.format("%s %s", DC.ICON, t.f("Set pet attributes.")), function(command)
	if not command.player_index then return end
	local player = game.get_player(command.player_index)
	if not player then return end

	local args = {}
	for token in string.gmatch(command.parameter or "", "%S+") do table.insert(args, token) end

	if #args == 0 or #args > 2 then
		player.print(string.format("%s %s", DC.ICON,
				t.f("Usage: /bpset <" .. t.f("field", "f") .. "> <" .. t.f("value", "f") .. ">")))
		return
	end

	local field = string.lower(args[1])

	-- Set pet attributes to ideal values.
	if #args == 1 and field == "ideal" then
		local state = pet_state.get_state(player.index)
		for key, value in pairs(ideal_state) do if MA[key] then state[key] = value end end
		player.print(string.format("%s %s", DC.ICON, t.f("Pet attributes set to ideal state.")))
		return
	end

	local raw_value = tonumber(args[2])

	if not raw_value then
		player.print(string.format("%s %s", DC.ICON, t.f(t.f("Value", "f") .. " parameter must be a number.")))
		return
	end

	local new_value = clamp(raw_value, 0, 100)

	if not MA[field] and field ~= "all" then
		player.print(string.format("%s %s", DC.ICON, t.f(t.f("Field", "f") .. " parameter was not a valid attribute.")))
		return
	end

	local state = pet_state.get_state(player.index)
	local old_value = state[field]

	state[field] = new_value

	-- Batch set pet attributes.
	if field == "all" then
		for attribute, _ in pairs(MA) do
			state[attribute] = new_value
			player.print(string.format("%s %s", DC.ICON, t.f("All attributes set to " .. t.f(new_value, "f") .. ".")))
		end
	else
		player.print(string.format("%s %s", DC.ICON, t.f(
				"Updated " .. t.f(field, "f") .. " from " .. t.f(old_value, "f") .. " to " .. t.f(new_value, "f") .. ".")))
	end
end)

commands.add_command("bpinfo", string.format("%s %s", DC.ICON, t.f("Show pet status for the calling player.")),
		function(command)
			if not command.player_index then return end
			local player = game.get_player(command.player_index)
			if not player then return end

			local state = pet_state.get(player.index)
			local ps_dump = pet_state.debug_dump(player.index)
			local pl_dump = pet_lifecycle.debug_dump(player)

			player.print(string.format("%s%s\n%s\n%s", DC.ICON, t.fh("Pet state:", "i"), ps_dump, pl_dump))
		end)

commands.add_command("bpdebug", string.format("%s %s", DC.ICON, t.f("Set debug level for biter-pet mod.")),
		function(command)
			if not command.player_index then return end
			local player = game.get_player(command.player_index)
			if not player then return end

			local level = tonumber(command.parameter)
			if level then
				debug.set_level(level, player)
			else
				player.print(string.format("%s %s", DC.ICON, t.f("Usage: /bpdebug <" .. t.f("0-4", "f") .. ">")))
			end
		end)

commands.add_command("bpsleep", "Put the pet to sleep.", function(command)
	if not command.player_index then return end
	local player = game.get_player(command.player_index)
	if not player then return end

	local entry = storage.biter_pet[command.player_index]
	if not entry then return end

	if entry.current_form == "sleeping" then
		player.print(string.format("%s %s", DC.ICON, t.f("The pet is already sleeping.")))
	else
		player.print(string.format("%s %s", DC.ICON, t.f("Putting the pet to sleep.")))
		pet_state_machine.enter_sleep(command.player_index, entry)
	end
end)

commands.add_command("bpwake", "Wake the pet up from sleep.", function(command)
	if not command.player_index then return end
	local player = game.get_player(command.player_index)
	if not player then return end

	local entry = storage.biter_pet[command.player_index]
	if not entry then return end

	if entry.current_form == "active" then
		player.print(string.format("%s %s", DC.ICON, t.f("The pet is already awake.")))
	else
		player.print(string.format("%s %s", DC.ICON, t.f("Waking the pet up from sleep.")))
		pet_state_machine.enter_active(command.player_index, entry)
	end
end)

commands.add_command("bpvisual", string.format("%s %s", DC.ICON, t.f("Visualize pet triggers, pathing and behaviors.")),
		function(command)
			if not command.player_index then return end
			local player = game.get_player(command.player_index)
			if not player then return end

			local enabled = debug.toggle_visualizer()
			if enabled then
				player.print(string.format("%s %s %s", DC.ICON, t.f("Visualizer"), t.f("enabled", "f")))
			else
				player.print(string.format("%s %s %s", DC.ICON, t.f("Visualizer"), t.f("disabled", "e")))
			end
		end)

commands.add_command("bpmoods", string.format("%s %s", DC.ICON, t.f("Decrease mood emote interval for debugging.")),
		function(command)
			if not command.player_index then return end
			local player = game.get_player(command.player_index)
			if not player then return end

			local enabled = debug.toggle_mood_debugging()
			if enabled then
				player.print(string.format("%s %s %s", DC.ICON, t.f("Mood debugging"), t.f("enabled", "f")))
			else
				player.print(string.format("%s %s %s", DC.ICON, t.f("Mood debugging"), t.f("disabled", "e")))
			end
		end)

return console_commands
