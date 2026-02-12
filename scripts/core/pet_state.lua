local debug = require("scripts.util.debug")
local pet_visuals = require("scripts.core.pet_visuals")
local t = require("scripts.util.text_format")

local TF = require("scripts.constants.text_format")
local DC = require("scripts.constants.debug")
local SC = require("scripts.constants.spawn").PET_DEFAULTS
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
			boredom = SC.boredom,
			evolution = SC.evolution,
			friendship = SC.friendship,
			happiness = SC.happiness,
			hunger = SC.hunger,
			morph = SC.morph,
			thirst = SC.thirst,
			tiredness = SC.tiredness,
			current_form = SC.current_form,
			feeding_target = SC.feeding_target
		}
		storage.pet_state[player_index] = state
	else
		state.boredom = state.boredom or SC.boredom
		state.evolution = state.evolution or SC.evolution
		state.friendship = state.friendship or SC.friendship
		state.happiness = state.happiness or SC.happiness
		state.hunger = state.hunger or SC.hunger
		state.morph = state.morph or SC.morph
		state.thirst = state.thirst or SC.thirst
		state.tiredness = state.tiredness or SC.tiredness
		state.current_form = state.current_form or SC.current_form
		state.feeding_target = state.feeding_target or SC.feeding_target
	end

	return state
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
	if pet and pet.valid then
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

	-- Destroy any random mood emote to clear way for event driven emotes.
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

	-- Don't queue duplicate emotes for fast rendering.
	for _, queued in ipairs(emote_state.forced_queue) do
		if queued == emote then
			debug.trace(string.format("Render request ignored because %s is already queued.", t.f(emote, "f")))
			return
		end
	end

	table.insert(emote_state.forced_queue, emote)

	-- If nothing is active then render the emote immediately.
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

local function calculate_dreams(player_index)
	local state = ensure_state(player_index)
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

local function calculate_mood(player_index)
	local state = ensure_state(player_index)
	local mood_table = {}

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
	if state.tirednesss >= MT.sleepy then mood_table[#mood_table + 1] = TM.sleepy end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	-- Mild states.
	if state.hunger >= MT.content then mood_table[#mood_table + 1] = TM.content end
	if state.boredom >= MT.alert then mood_table[#mood_table + 1] = TM.alert end
	if state.happiness <= MT.happy then mood_table[#mood_table + 1] = TM.happy end
	if state.friendship >= MT.friendly then mood_table[#mood_table + 1] = TM.friendly end
	if state.tirednesss >= MT.animated then mood_table[#mood_table + 1] = TM.animated end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	-- Contented states.
	if state.hunger >= MT.full then mood_table[#mood_table + 1] = TM.full end
	if state.boredom >= MT.focused then mood_table[#mood_table + 1] = TM.focused end
	if state.happiness <= MT.overjoyed then mood_table[#mood_table + 1] = TM.overjoyed end
	if state.friendship >= MT.wary then mood_table[#mood_table + 1] = TM.wary end
	if state.tirednesss >= MT.energized then mood_table[#mood_table + 1] = TM.energized end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	return "confused"
end

local function apply_penalty_if_threshold(player_index, need_name, value, threshold, penalty)
	if value >= threshold then
		debug.info(string.format("Severe %s has incurred %s penalty", t.f(need_name, "e"), t.f("happiness", "f")))
		pet_state.add_happiness(player_index, penalty)
	end
end

function pet_state.tick_pet_state(player_index, entry)
	local state = ensure_state(player_index)
	local now = game.tick
	local pet = entry.unit
	local current_form = entry.current_form
	local increments = NR[current_form].increments
	local penalties = NR[current_form].penalties
	local intervals = NI[current_form]
	local mood_function = (current_form == "sleeping") and calculate_dreams or calculate_mood

	state.next_hunger_tick = state.next_hunger_tick or now + intervals.hunger
	if now >= state.next_hunger_tick then
		pet_state.add_hunger(player_index, increments.hunger)
		state.next_hunger_tick = now + intervals.hunger
		apply_penalty_if_threshold(player_index, "hunger", state.hunger, MT.starving, penalties.hunger)
	end

	state.next_thirst_tick = state.next_thirst_tick or now + intervals.thirst
	if now >= state.next_thirst_tick then
		pet_state.add_thirst(player_index, increments.thirst)
		state.next_thirst_tick = now + intervals.thirst
		apply_penalty_if_threshold(player_index, "thirst", state.thirst, MT.dehydrated, penalties.thirst)
	end

	state.next_boredom_tick = state.next_boredom_tick or now + intervals.boredom
	if now >= state.next_boredom_tick then
		pet_state.add_boredom(player_index, increments.boredom)
		state.next_boredom_tick = now + intervals.boredom
		apply_penalty_if_threshold(player_index, "boredom", state.boredom, MT.frustrated, penalties.boredom)
	end

	state.next_tiredness_tick = state.next_tiredness_tick or now + intervals.tiredness
	if now >= state.next_tiredness_tick then
		pet_state.add_tiredness(player_index, increments.tiredness)
		state.next_tiredness_tick = now + intervals.tiredness
		apply_penalty_if_threshold(player_index, "tiredness", state.tiredness, MT.exhausted, penalties.tiredness)
	end

	state.next_mood_calc_tick = state.next_mood_calc_tick or now + intervals.mood
	if now >= state.next_mood_calc_tick then
		debug.trace("Pet state tick firing.")
		-- Recalculate mood.
		state.mood = mood_function(player_index)

		debug.info(string.format("%s [%s]", "A new mood has been calculated and queued", t.f(state.mood, "f")))
		pet_state.queue_emote(player_index, pet, state.mood)
		state.next_mood_calc_tick = now + intervals.mood

		if state.friendship <= MT.depressed then
			pet_state.add_friendship(player_index, penalties.happiness)
		end

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
	state.hunger = math.max(0, math.min(100, value))
end

local function debug_needs_update(label, new_state, old_state)
	if not DC.DEBUG_SHOW_NEEDS_UPDATES or not (debug.current_level >= 3) then return end
	local verb = (new_state > old_state and "increased") or (new_state < old_state and "decreased") or "unchanged"
	debug.info(string.format("%s %s from %s to %s.", t.f(label, "i"), verb, t.f(old_state, "f"), t.f(new_state, "f")))
end

function pet_state.add_hunger(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_hunger = math.max(0, math.min(100, state.hunger + (delta)))
	debug_needs_update("Hunger", new_hunger, state.hunger)
	state.hunger = new_hunger
end

function pet_state.set_feeding_target(player_index, entity)
	local state = ensure_state(player_index)
	state.feeding_target = entity or nil
end

function pet_state.get_feeding_target(player_index)
	local state = ensure_state(player_index)
	return state.feeding_target
end

function pet_state.set_idle_target(player_index, entity)
	local state = ensure_state(player_index)
	state.idle_target = entity or nil
end

function pet_state.get_idle_target(player_index, entity)
	local state = ensure_state(player_index)
	return state.idle_target
end

-- Thirst functions.
function pet_state.get_thirst(player_index)
	local state = ensure_state(player_index)
	return state.thirst
end

function pet_state.set_thirst(player_index, value)
	local state = ensure_state(player_index)
	state.thirst = math.max(0, math.min(100, value))
end

function pet_state.add_thirst(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_thirst = math.max(0, math.min(100, state.thirst + delta))
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
	state.tiredness = math.max(0, math.min(100, value))
end

function pet_state.add_tiredness(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_tiredness = math.max(0, math.min(100, state.tiredness + delta))
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
	state.morph = math.max(0, math.min(100, value))
end

function pet_state.add_morph(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_morph = math.max(0, math.min(100, state.morph + delta))
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
	state.evolution = math.max(0, math.min(100, value))
end

function pet_state.add_evolution(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_evolution = math.max(0, math.min(100, state.evolution + delta))
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
	state.boredom = math.max(0, math.min(100, value))
end

function pet_state.add_boredom(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_boredom = math.max(0, math.min(100, state.boredom + delta))
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
	state.happiness = math.max(0, math.min(100, value))
end

function pet_state.add_happiness(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_happiness = math.max(0, math.min(100, state.happiness + delta))
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
	state.friendship = math.max(0, math.min(100, value))
end

function pet_state.add_friendship(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	local new_friendship = math.max(0, math.min(100, state.friendship + delta))
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
