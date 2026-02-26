local debug = require("scripts.utilities.debug")
local pet_visuals = require("scripts.core.pet_visuals")
local t = require("scripts.utilities.text_format")

local GUARDING_MULTIPLIER = require("scripts.constants.modifiers").GUARDING_INTERVAL_MULTIPLIER

local TF = require("scripts.constants.text_format")
local DC = require("scripts.constants.debug")
local SD = require("scripts.constants.spawn").STATE_DEFAULTS
local SS = require("scripts.constants.spawn").SPAWN_SETTINGS
local NI = require("scripts.constants.needs").NEED_INTERVALS
local NR = require("scripts.constants.needs").NEED_RATES
local RS = require("scripts.constants.visuals").RENDER_SETTINGS
local MT = require("scripts.constants.thresholds").MOOD_THRESHOLDS
local TM = require("scripts.constants.thresholds").THRESHOLD_TO_SPRITE_MAP
local BD = require("scripts.constants.dreams").BITER_DREAMS

local pet_state = {}

-- State functions.
local function ensure_state(player_index)
	storage.pet_state = storage.pet_state or {}
	local state = storage.pet_state[player_index]

	if not state then
		-- Brand new pet state.
		state = {
			boredom = SD.boredom,
			evolution = SD.evolution,
			friendship = SD.friendship,
			happiness = SD.happiness,
			hunger = SD.hunger,
			morph = SD.morph,
			thirst = SD.thirst,
			tiredness = SD.tiredness
		}
		storage.pet_state[player_index] = state
	else
		state.boredom = state.boredom or SD.boredom
		state.evolution = state.evolution or SD.evolution
		state.friendship = state.friendship or SD.friendship
		state.happiness = state.happiness or SD.happiness
		state.hunger = state.hunger or SD.hunger
		state.morph = state.morph or SD.morph
		state.thirst = state.thirst or SD.thirst
		state.tiredness = state.tiredness or SD.tiredness
	end

	return state
end

function pet_state.reset_state_to_defaults(player_index)
	local state = ensure_state(player_index)
	for key, value in pairs(SD) do state[key] = value end
end

function pet_state.get_state(player_index)
	return ensure_state(player_index)
end

local function clamp(value, minimum, maximum)
	if value < minimum then return minimum end
	if value > maximum then return maximum end
	return value
end

local function ensure_queue(player_index)
	local emote_state = storage.emote_state[player_index]
	if not emote_state then
		emote_state = {
			queue = {},
			forced_queue = {},
			active_emote = nil,
			ends_at_tick = nil,
			sprite_render = nil
		}
		storage.emote_state[player_index] = emote_state
	end
	return emote_state
end

function pet_state.get_queue(player_index)
	return ensure_queue(player_index)
end

function pet_state.get(player_index)
	return ensure_state(player_index)
end

function pet_state.set_behavior(player_index, new_behavior)
	local state = ensure_state(player_index)
	debug.render_pet_behavior(player_index, new_behavior)
	state.behavior = new_behavior
end

function pet_state.get_behavior(player_index)
	local state = ensure_state(player_index)
	return state.behavior or "idle"
end

function pet_state.queue_emote(player_index, pet, emote)
	local emote_state = ensure_queue(player_index)
	if (pet and pet.valid) then
		local emote_state = storage.emote_state[player_index]
		emote_state.queue[#emote_state.queue + 1] = emote
	end
end

local function start_next_forced_emote(player_index, entry, fast_render)
	local emote_state = ensure_queue(player_index)
	local next_emote = table.remove(emote_state.forced_queue, 1)
	if not next_emote then return end
	local sprite_render = pet_visuals.emote(player_index, entry, next_emote, fast_render)
	emote_state.sprite_render = sprite_render
	emote_state.active_emote = next_emote
	emote_state.active_type = "forced"
	emote_state.ends_at_tick = game.tick + 180 + RS.EMOTE_DURATION or 180
end

function pet_state.on_emote_finished(player_index, entry)
	local emote_state = ensure_queue(player_index)

	-- If this was a forced emote then start the next one immediately.
	if emote_state.active_type == "forced" then
		emote_state.active_emote = nil
		emote_state.active_type = nil
		emote_state.ends_at_tick = nil

		start_next_forced_emote(player_index, entry)
		return
	end
end

function pet_state.force_emote(player_index, entry, emote, fast_render)
	local emote_state = ensure_queue(player_index)

	-- Clear tick-based emotes to clear the way for event-driven emotes.
	if (emote_state.sprite_render and emote_state.active_type ~= "forced") then
		if emote_state.sprite_render.sprite and emote_state.sprite_render.sprite.valid then
			emote_state.sprite_render.sprite.destroy()
		end
		if emote_state.sprite_render.light and emote_state.sprite_render.light.valid then
			emote_state.sprite_render.light.destroy()
		end
		emote_state.sprite_render = nil
	end

	emote_state.active_emote = nil
	emote_state.ends_at_tick = nil
	emote_state.queue = {}

	-- Don't queue up duplicate emotes for fast rendering.
	for _, queued in ipairs(emote_state.forced_queue) do
		if queued == emote then
			debug.trace(string.format("Render request ignored because %s is already queued.", t.f(emote, "f")))
			return
		end
	end

	table.insert(emote_state.forced_queue, emote)

	-- If nothing else is active then render the emote immediately.
	if not emote_state.active_type then
		debug.info(string.format("An event has triggered a forced emote [%s].", t.f(emote, "f")))
		start_next_forced_emote(player_index, entry, fast_render)
	end
end

local function tick_emotes(player_index, entry)
	local emote_state = ensure_queue(player_index)

	local now = game.tick

	-- Check active is emote is finished.
	if emote_state.active then
		if now >= emote_state.ends_at_tick then
			emote_state.active_emote = nil
			emote_state.ends_at_tick = nil
		else
			return
		end
	end

	-- Start the next queued emote if none active.
	local next_emote = emote_state.queue[1]
	if next_emote then
		table.remove(emote_state.queue, 1)
		local sprite_render = pet_visuals.emote(player_index, entry, next_emote)
		emote_state.sprite_render = sprite_render
		emote_state.active_emote = next_emote
		emote_state.ends_at_tick = now + (RS.EMOTE_DURATION or 180)
	end
end

-- A top 10 anime betrayal of all time.
function pet_state.switch_to_enemy_force(player_index, entry)
	local pet = entry.unit
	if not (pet and pet.valid) then return end
	pet.force = game.forces["enemy"]
end

-- General mood functions.
local function pick_random_mood(player_index, mood_table)
	local table_size = #mood_table
	if table_size == 0 then return "confused" end

	local last = storage.last_mood[player_index]

	-- Initial pick from available options.
	local index = math.random(table_size)
	local mood = mood_table[index]

	-- If pick same as last time and more than one option, retry once.
	if mood == last and table_size > 1 then
		index = math.random(table_size)
		mood = mood_table[index]
	end

	storage.last_mood[player_index] = mood
	return mood
end

function pet_state.set_mood(player_index, mood)
	local state = ensure_state(player_index)
	state.mood = tostring(mood or "neutral")
end

local function all_needs_above_average(player_index)
	local state = ensure_state(player_index)
	return (state.hunger < MT.content and state.boredom < MT.alert and state.happiness > MT.happy and state.friendship >
			       MT.devoted)
end

local function calculate_dreams(player_index, entry)
	local state = ensure_state(player_index)
	if entry.guarding_body then return "very-sad" end
	local dream_table = {}
	dream_table[#dream_table + 1] = "sleeping"

	if all_needs_above_average(player_index) then
		dream_table[#dream_table + 1] = "ecstatic"
		if math.random() < 0.001 then dream_table[#dream_table + 1] = pick_random_mood(player_index, BD.rare) end
		return pick_random_mood(player_index, BD.rare)
	else
		if state.hunger >= 50 then dream_table[#dream_table + 1] = BD.hunger end
		if state.thirst >= 50 then dream_table[#dream_table + 1] = BD.thirst end
		if state.boredom >= 50 then dream_table[#dream_table + 1] = BD.boredom end
		if state.happiness < 50 then dream_table[#dream_table + 1] = pick_random_mood(player_index, BD.happiness) end
		if state.friendship < 50 then dream_table[#dream_table + 1] = pick_random_mood(player_index, BD.friendship) end
		return pick_random_mood(player_index, dream_table)
	end
	return "confused"
end

local function calculate_mood(player_index, entry)
	local state = ensure_state(player_index)
	local mood_table = {}

	if entry.guarding_body then return "very-sad" end

	-- All pet needs are met and stats are above average.
	if all_needs_above_average(player_index) then return "ecstatic" end

	-- Extreme states.
	if state.hunger >= MT.starving then mood_table[#mood_table + 1] = TM.starving end
	if state.boredom >= MT.frustrated then mood_table[#mood_table + 1] = TM.frustrated end
	if state.happiness <= MT.depressed then mood_table[#mood_table + 1] = TM.depressed end
	if state.friendship >= MT.devoted then mood_table[#mood_table + 1] = TM.devoted end
	if state.tiredness >= MT.exhausted then mood_table[#mood_table + 1] = TM.exhausted end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	-- Alarming states.
	if state.hunger >= MT.hungry then mood_table[#mood_table + 1] = TM.hungry end
	if state.boredom >= MT.apathetic then mood_table[#mood_table + 1] = TM.apathetic end
	if state.happiness <= MT.sad then mood_table[#mood_table + 1] = TM.sad end
	if state.friendship >= MT.loyal then mood_table[#mood_table + 1] = TM.loyal end
	if state.tiredness >= MT.sleepy then mood_table[#mood_table + 1] = TM.sleepy end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	-- Mild states.
	if state.hunger >= MT.content then mood_table[#mood_table + 1] = TM.content end
	if state.boredom >= MT.alert then mood_table[#mood_table + 1] = TM.alert end
	if state.happiness <= MT.happy then mood_table[#mood_table + 1] = TM.happy end
	if state.friendship >= MT.friendly then mood_table[#mood_table + 1] = TM.friendly end
	if state.tiredness >= MT.animated then mood_table[#mood_table + 1] = TM.animated end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	-- Contented states.
	if state.hunger >= MT.full then mood_table[#mood_table + 1] = TM.full end
	if state.boredom >= MT.focused then mood_table[#mood_table + 1] = TM.focused end
	if state.happiness <= MT.overjoyed then mood_table[#mood_table + 1] = TM.overjoyed end
	if state.friendship >= MT.wary then mood_table[#mood_table + 1] = TM.wary end
	if state.tiredness >= MT.energized then mood_table[#mood_table + 1] = TM.energized end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	return "confused"
end

local function apply_penalty_if_threshold(player_index, need_name, value, threshold, penalty)
	if value >= threshold then
		debug.info(string.format("Severe %s has incurred %s penalty", t.f(need_name, "e"), t.f("happiness", "f")))
		pet_state.add_happiness(player_index, penalty)
	end
end

local function get_adjusted_interval(entry, interval)
	return (entry.guard_position and interval * GUARDING_MULTIPLIER) or interval
end

function pet_state.tick_pet_state(player_index, entry)
	local state = ensure_state(player_index)
	local now = game.tick
	local pet = entry.unit
	local current_form = entry.current_form
	local increments = NR[current_form].increments
	local penalties = NR[current_form].penalties
	local intervals = NI[current_form]
	local debug_int = NI.debug
	local mood_function = (current_form == "sleeping") and calculate_dreams or calculate_mood

	local hunger_interval = get_adjusted_interval(entry, intervals.hunger)
	state.next_hunger_tick = state.next_hunger_tick or now + hunger_interval
	if now >= state.next_hunger_tick then
		pet_state.add_hunger(player_index, increments.hunger)
		local next_hunger_interval = debug.mood_debugging_enabled and debug_int.hunger or hunger_interval
		state.next_hunger_tick = now + next_hunger_interval
		apply_penalty_if_threshold(player_index, "hunger", state.hunger, MT.starving, penalties.hunger)
	end

	local thirst_interval = get_adjusted_interval(entry, intervals.hunger)
	state.next_thirst_tick = state.next_thirst_tick or now + thirst_interval
	if now >= state.next_thirst_tick then
		if state.has_fluid_handling then pet_state.add_thirst(player_index, increments.thirst) end
		local next_thirst_interval = debug.mood_debugging_enabled and debug_int.thirst or thirst_interval
		state.next_thirst_tick = now + next_thirst_interval
		apply_penalty_if_threshold(player_index, "thirst", state.thirst, MT.dehydrated, penalties.thirst)
	end

	local boredom_interval = get_adjusted_interval(entry, intervals.boredom)
	state.next_boredom_tick = state.next_boredom_tick or now + boredom_interval
	if now >= state.next_boredom_tick then
		pet_state.add_boredom(player_index, increments.boredom)
		local next_boredom_interval = debug.mood_debugging_enabled and debug_int.boredom or boredom_interval
		state.next_boredom_tick = now + next_boredom_interval
		apply_penalty_if_threshold(player_index, "boredom", state.boredom, MT.frustrated, penalties.boredom)
	end

	local tiredness_interval = get_adjusted_interval(entry, intervals.tiredness)
	state.next_tiredness_tick = state.next_tiredness_tick or now + tiredness_interval
	if now >= state.next_tiredness_tick then
		pet_state.add_tiredness(player_index, increments.tiredness)
		local next_tiredness_interval = debug.mood_debugging_enabled and debug_int.tiredness or tiredness_interval
		state.next_tiredness_tick = now + next_tiredness_interval
		apply_penalty_if_threshold(player_index, "tiredness", state.tiredness, MT.exhausted, penalties.tiredness)
	end

	state.next_mood_calc_tick = state.next_mood_calc_tick or now + intervals.mood
	if now >= state.next_mood_calc_tick then

		-- Recalculate mood.
		state.mood = mood_function(player_index, entry)

		debug.info(string.format("%s [%s]", "A new mood has been calculated and queued", t.f(state.mood, "f")))
		pet_state.queue_emote(player_index, pet, state.mood)
		local next_mood_interval = debug.mood_debugging_enabled and debug_int.mood or intervals.mood
		state.next_mood_calc_tick = now + next_mood_interval

		if state.friendship <= MT.depressed then pet_state.add_friendship(player_index, penalties.happiness) end

		-- Add mood to queue if no forced emote is currently not active.
		local emote_state = ensure_queue(player_index)
		if (emote_state.active_type ~= "forced") then tick_emotes(player_index, entry) end
	end
end

-- Attack functions.
function pet_state.get_enemy_target(player_index)
	local state = ensure_state(player_index)
	return state.attack_target
end

function pet_state.set_attack_target(player_index, entity)
	local state = ensure_state(player_index)
	state.attack_target = entity
end

function pet_state.clear_attack_target(player_index)
	local state = ensure_state(player_index)
	state.attack_target = nil
end

-- Hunger functions.
function pet_state.get_hunger(player_index)
	local state = ensure_state(player_index)
	return state.hunger
end

function pet_state.set_hunger(player_index, value)
	local state = ensure_state(player_index)
	state.hunger = clamp(value, 0, 100)
end

local function debug_needs_update(label, new_state, old_state)
	if not DC.DEBUG_SHOW_NEEDS_UPDATES then return end
	local verb = (new_state > old_state and "increased") or (new_state < old_state and "decreased") or "unchanged"
	debug.info(string.format("%s %s from %s to %s.", t.f(label, "i"), verb, t.f(old_state, "f"), t.f(new_state, "f")))
end

function pet_state.add_hunger(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_hunger = clamp(state.hunger + delta, 0, 100)
	debug_needs_update("Hunger", new_hunger, state.hunger)
	state.hunger = new_hunger
end

-- World ineraction.
function pet_state.get_tree_target(player_index)
	local state = ensure_state(player_index)
	return state.tree_target
end

function pet_state.set_tree_target(player_index, entity)
	local state = ensure_state(player_index)
	state.tree_target = entity or nil
end

function pet_state.clear_tree_target(player_index)
	local state = ensure_state(player_index)
	state.tree_target = nil
end

-- Item interaction.
function pet_state.set_returnable_item(player_index, item_name)
	local state = ensure_state(player_index)
	state.returnable_item = item_name
end

function pet_state.get_returnable_item(player_index)
	local state = ensure_state(player_index)
	return state.returnable_item
end

function pet_state.get_item_interaction(player_index)
	local state = ensure_state(player_index)
	return state.item_interaction
end

function pet_state.set_item_interaction(player_index, value)
	local state = ensure_state(player_index)
	state.item_interaction = value
end

function pet_state.set_item_target(player_index, entity)
	local state = ensure_state(player_index)
	state.item_target = entity or nil
end

function pet_state.get_item_target(player_index)
	local state = ensure_state(player_index)
	return state.item_target
end

function pet_state.clear_item_target(player_index)
	local state = ensure_state(player_index)
	state.item_target = nil
end

-- Feeding functions.

function pet_state.set_idle_target(player_index, entity)
	local state = ensure_state(player_index)
	state.idle_target = entity or nil
end

function pet_state.get_idle_target(player_index, entity)
	local state = ensure_state(player_index)
	return state.idle_target
end

function pet_state.clear_idle_target(player_index)
	local state = ensure_state(player_index)
	state.idle_target = nil
end

-- Thirst functions.
function pet_state.get_thirst(player_index)
	local state = ensure_state(player_index)
	return state.thirst
end

function pet_state.set_thirst(player_index, value)
	local state = ensure_state(player_index)
	state.thirst = clamp(value, 0, 100)
end

function pet_state.add_thirst(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_thirst = clamp(state.thirst + delta, 0, 100)
	debug_needs_update("Thirst", new_thirst, state.thirst)
	state.thirst = new_thirst
end

-- Tiredness functions.
function pet_state.get_tiredness(player_index)
	local state = ensure_state(player_index)
	return state.tiredness
end

function pet_state.set_tiredness(player_index, value)
	local state = ensure_state(player_index)
	state.tiredness = clamp(value, 0, 100)
end

function pet_state.add_tiredness(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_tiredness = clamp(state.tiredness + delta, 0, 100)
	debug_needs_update("Tiredness", new_tiredness, state.tiredness)
	state.tiredness = new_tiredness
end

-- Morph functions.
function pet_state.get_morph(player_index)
	local state = ensure_state(player_index)
	return state.morph
end

function pet_state.set_morph(player_index, value)
	local state = ensure_state(player_index)
	state.morph = clamp(value, 0, 100)
end

function pet_state.add_morph(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_morph = clamp(state.morph + delta, 0, 100)
	debug_needs_update("Morph", new_morph, state.morph)
	state.morph = new_morph
end

-- Evolution functions.
function pet_state.get_evolution(player_index)
	local state = ensure_state(player_index)
	return state.evolution
end

function pet_state.set_evolution(player_index, value)
	local state = ensure_state(player_index)
	state.evolution = clamp(value, 0, 100)
end

function pet_state.add_evolution(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_evolution = clamp(state.evolution + delta, 0, 100)
	debug_needs_update("Evolution", new_evolution, state.evolution)
	state.evolution = new_evolution
end

-- Boredom functions.
function pet_state.get_boredom(player_index)
	local state = ensure_state(player_index)
	return state.boredom
end

function pet_state.set_boredom(player_index, value)
	local state = ensure_state(player_index)
	state.boredom = clamp(value, 0, 100)
end

function pet_state.add_boredom(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_boredom = clamp(state.boredom + delta, 0, 100)
	debug_needs_update("Boredom", new_boredom, state.boredom)
	state.boredom = new_boredom
end

-- Happiness functions.
function pet_state.get_happiness(player_index)
	local state = ensure_state(player_index)
	return state.happiness
end

function pet_state.set_happiness(player_index, value)
	local state = ensure_state(player_index)
	state.happiness = clamp(value, 0, 100)
end

function pet_state.add_happiness(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_happiness = clamp(state.happiness + delta, 0, 100)
	debug_needs_update("Happiness", new_happiness, state.happiness)
	state.happiness = new_happiness
end

-- Friendship functions.
function pet_state.get_friendship(player_index)
	local state = ensure_state(player_index)
	return state.friendship
end

function pet_state.set_friendship(player_index, value)
	local state = ensure_state(player_index)
	state.friendship = clamp(value, 0, 100)
end

function pet_state.add_friendship(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_friendship = clamp(state.friendship + delta, 0, 100)
	debug_needs_update("Friendship", new_friendship, state.friendship)
	state.friendship = new_friendship
end

-- Pause functions.
function pet_state.pause(player_index, ticks)
	if ticks < 60 then ticks = 60 end
	local state = ensure_state(player_index)
	state.pause_end_tick = game.tick + ticks
end

function pet_state.is_paused(player_index)
	local state = ensure_state(player_index)
	return state.pause_end_tick and game.tick < state.pause_end_tick
end

function pet_state.debug_dump(player_index)
	local state = ensure_state(player_index)
	local boredom = string.format("%s %s", t.fm("Boredeom:", "f"), t.fm(state.boredom, "m", 1))
	local evolution = string.format("%s %s", t.fm("Evolution:", "f"), t.fm(state.evolution, "m", 1))
	local friendship = string.format("%s %s", t.fm("Friendship:", "f"), t.fm(state.friendship, "m", 1))
	local happiness = string.format("%s %s", t.fm("Happiness:", "f"), t.fm(state.happiness, "m", 1))
	local hunger = string.format("%s %s", t.fm("Hunger:", "f"), t.fm(state.hunger, "m", 1))
	local morph = string.format("%s %s", t.fm("Morph:", "f"), t.fm(state.morph, "m", 1))
	local thirst = string.format("%s %s", t.fm("Thirst:", "f"), t.fm(state.thirst, "m", 1))
	local tiredness = string.format("%s %s", t.fm("Tiredness:", "f"), t.fm(state.tiredness, "m", 1))
	return string.format("%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s", hunger, thirst, happiness, friendship, boredom, tiredness,
			evolution, morph)
end

return pet_state
