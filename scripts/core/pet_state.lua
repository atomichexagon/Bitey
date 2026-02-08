local debug = require("scripts.util.debug")
local pet_visuals = require("scripts.core.pet_visuals")
local t = require("scripts.util.text_format")

local TF = require("scripts.constants.text_format") -- Text color constants.

local NEEDS_CONSTANTS = require("scripts.constants.needs")
local PET_NEEDS = NEEDS_CONSTANTS.NEEDS_CONSTANTS

local PET_VISUALS_CONSTANTS = require("scripts.constants.visuals")
local RENDER_SETTINGS = PET_VISUALS_CONSTANTS.RENDER_SETTINGS

local THRESHOLD_CONSTANTS = require("scripts.constants.thresholds")
local MOOD_THRESHOLDS = THRESHOLD_CONSTANTS.MOOD_THRESHOLDS

local pet_state = {}

-- State functions.
local function ensure_state(player_index)
	storage.pet_state = storage.pet_state or {}
	local state = storage.pet_state[player_index]

	if not state then
		-- Brand new pet state.
		state = {
			boredom = 50,
			evolution = 0,
			friendship = 0,
			happiness = 0,
			hunger = 100,
			morph = 0,
			thirst = 100,
			tiredness = 0,
			wake_state = "awake",
			feeding_target = nil
		}
		storage.pet_state[player_index] = state
	else
		-- NOTE: Stop forgetting to update migrations if you don't want existing saves to break.
		state.boredom = state.boredom or 50
		state.evolution = state.evolution or 0
		state.friendship = state.friendship or 0
		state.happiness = state.happiness or 0
		state.hunger = state.hunger or 100
		state.morph = state.morph or 0
		state.thirst = state.thirst or 100
		state.tiredness = state.tiredness or 0
		state.wake_state = state.wake_state or "awake"
		state.feeding_target = state.feeding_target or nil
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

function pet_state.start_next_forced_emote(player_index, entry, fast_render)
	local emote_state = ensure_queue(player_index)
	local next_emote = table.remove(emote_state.forced_queue, 1)
	if not next_emote then return end

	local sprite_render = pet_visuals.emote(player_index, entry, next_emote, fast_render)
	emote_state.sprite_render = sprite_render
	emote_state.active_emote = next_emote
	emote_state.active_type = "forced"
	emote_state.ends_at_tick = game.tick + 180 + RENDER_SETTINGS.EMOTE_DURATION or 180
end

function pet_state.on_emote_finished(player_index, entry)
	local emote_state = ensure_queue(player_index)

	-- If this was a forced emote, start the next one immediately.
	if emote_state.active_type == "forced" then
		emote_state.active_emote = nil
		emote_state.active_type = nil
		emote_state.ends_at_tick = nil

		pet_state.start_next_forced_emote(player_index, entry)
		return
	end

	-- Otherwise, mood emotes will be handled by tick_emotes().
end

function pet_state.force_emote(player_index, entry, emote, fast_render)
	local emote_state = ensure_queue(player_index)

	-- Destroy any mood emote render to clear way for event-driven emote.
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

	-- Clear current emote queue.
	emote_state.queue = {}

	table.insert(emote_state.forced_queue, emote)

	-- If nothing is active, fire emote immediately.
	if not emote_state.active_type then
		debug.info(string.format("An event has triggered a forced emote [%s].", t.f(emote, "f")))
		pet_state.start_next_forced_emote(player_index, entry, fast_render)
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
		emote_state.ends_at_tick = now + (RENDER_SETTINGS.EMOTE_DURATION or 180)
	end
end

function pet_state.tick_pet_state(player_index, entry)
	local state = ensure_state(player_index)
	local now = game.tick
	local pet = entry.unit

	state.next_hunger_tick = state.next_hunger_tick or (now + PET_NEEDS.HUNGER_INTERVAL)
	if now >= state.next_hunger_tick then
		pet_state.add_hunger(player_index, PET_NEEDS.HUNGER_INCREMENT)
		state.next_hunger_tick = now + PET_NEEDS.HUNGER_INTERVAL

		if state.hunger >= MOOD_THRESHOLDS.STARVING then
			debug.info(string.format("Severe %s has incurred %s penalty", t.f("hunger", "e"), t.f("happiness", "f")))
			pet_state.add_happiness(player_index, PET_NEEDS.SEVERE_HUNGER_PENALTY)
		end
	end

	state.next_thirst_tick = state.next_thirst_tick or (now + PET_NEEDS.THIRST_INTERVAL)
	if now >= state.next_thirst_tick then
		pet_state.add_thirst(player_index, PET_NEEDS.THIRST_INCREMENT)
		state.next_thirst_tick = now + PET_NEEDS.THIRST_INTERVAL

		if state.thirst >= MOOD_THRESHOLDS.DEHYDRATED then
			debug.info(string.format("Severe %s has incurred %s penalty", t.f("thirst", "e"), t.f("happiness", "f")))
			pet_state.add_happiness(player_index, PET_NEEDS.SEVERE_THIRST_PENALTY)
		end
	end

	state.next_boredom_tick = state.next_boredom_tick or (now + PET_NEEDS.BOREDOM_INTERVAL)
	if now >= state.next_boredom_tick then
		pet_state.add_boredom(player_index, PET_NEEDS.BOREDOM_INCREMENT)
		state.next_boredom_tick = now + PET_NEEDS.BOREDOM_INTERVAL

		if state.boredom >= MOOD_THRESHOLDS.FRUSTRATED then
			debug.info(string.format("Severe %s has incurred %s penalty", t.f("boredom", "e"), t.f("happiness", "f")))
			pet_state.add_happiness(player_index, PET_NEEDS.SEVERE_BOREDOM_PENALTY)
		end
	end

	state.next_mood_calc_tick = state.next_mood_calc_tick or (now + PET_NEEDS.MOOD_RECALCULATION_INTERVAL)
	if now >= state.next_mood_calc_tick then
		-- Recalculate mood.
		state.mood = pet_state.calculate_mood(player_index)
		debug.info(string.format("%s [%s]", "A new mood has been calculated and queued", t.f(state.mood, "f")))
		pet_state.queue_emote(player_index, pet, state.mood)
		state.next_mood_calc_tick = now + PET_NEEDS.MOOD_RECALCULATION_INTERVAL

		if state.friendship <= MOOD_THRESHOLDS.DEPRESSED then
			debug.info(string.format("Severe %s has incurred %s penalty", t.f("happiness", "e"), t.f("friendship", "f")))
			pet_state.add_friendship(player_index, PET_NEEDS.SEVERE_SADNESS_PENALTY)
		end

		-- Add mood to queue if no forced emote is currently not active.
		local emote_state = ensure_queue(player_index)
		if (emote_state.active_type ~= "forced") then tick_emotes(player_index, entry) end
	end
end

-- General mood functions.
local function pick_random_mood(player_index, mood_table)
	local table_size = #mood_table
	if table_size == 0 then return nil end

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

function pet_state.calculate_mood(player_index)
	local state = ensure_state(player_index)

	local mood_table = {}
	-- All pet needs are met and stats are above average.
	if (state.hunger < MOOD_THRESHOLDS.CONTENT and state.boredom < MOOD_THRESHOLDS.ALERT and state.happiness >
			MOOD_THRESHOLDS.HAPPY and state.friendship > MOOD_THRESHOLDS.DEVOTED) then
		mood_table[#mood_table + 1] = "ecstatic"
		return pick_random_mood(player_index, mood_table)
	end

	-- Extreme states.
	if state.hunger >= MOOD_THRESHOLDS.STARVING then mood_table[#mood_table + 1] = "hungry" end
	if state.boredom >= MOOD_THRESHOLDS.FRUSTRATED then mood_table[#mood_table + 1] = "angry" end
	if state.happiness <= MOOD_THRESHOLDS.DEPRESSED then mood_table[#mood_table + 1] = "very-sad" end
	if state.friendship >= MOOD_THRESHOLDS.DEVOTED then mood_table[#mood_table + 1] = "love" end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	-- Alarming states.
	if state.hunger >= MOOD_THRESHOLDS.HUNGRY then mood_table[#mood_table + 1] = "hungry" end
	if state.boredom >= MOOD_THRESHOLDS.APATHETIC then mood_table[#mood_table + 1] = "bored" end
	if state.happiness <= MOOD_THRESHOLDS.SAD then mood_table[#mood_table + 1] = "sad" end
	if state.friendship >= MOOD_THRESHOLDS.LOYAL then mood_table[#mood_table + 1] = "happy" end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	-- Mild states.
	if state.hunger >= MOOD_THRESHOLDS.CONTENT then mood_table[#mood_table + 1] = "happy" end
	if state.boredom >= MOOD_THRESHOLDS.ALERT then mood_table[#mood_table + 1] = "investigate" end
	if state.happiness <= MOOD_THRESHOLDS.HAPPY then mood_table[#mood_table + 1] = "happy" end
	if state.friendship >= MOOD_THRESHOLDS.FRIENDLY then mood_table[#mood_table + 1] = "love" end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	-- Contented states.
	if state.hunger >= MOOD_THRESHOLDS.FULL then mood_table[#mood_table + 1] = "happy" end
	if state.boredom >= MOOD_THRESHOLDS.FOCUSED then mood_table[#mood_table + 1] = "investigate" end
	if state.happiness <= MOOD_THRESHOLDS.OVERJOYED then mood_table[#mood_table + 1] = "very-happy" end
	if state.friendship >= MOOD_THRESHOLDS.WARY then mood_table[#mood_table + 1] = "scared" end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	return "confused"
end

function pet_state.set_mood(player_index, mood)
	local state = ensure_state(player_index)
	state.mood = tostring(mood or "neutral")
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

function pet_state.add_hunger(player_index, delta)
	if not delta then return end
	local state = ensure_state(player_index)
	delta = delta or PET_NEEDS.HUNGER_INCREMENT
	local new_hunger = math.max(0, math.min(100, state.hunger + (delta)))

	debug.info(string.format("[color=%s]Hunger[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", state.hunger, new_hunger))
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
	debug.info(string.format("[color=%s]Thirst[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", state.thirst, new_thirst))
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
	debug.info(string.format("[color=%s]Tireness[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", state.tiredness, new_tiredness))
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
	debug.info(string.format("[color=%s]Morph[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", state.morph, new_morph))
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
	debug.info(string.format("[color=%s]Evolution[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", state.evolution, new_evolution))
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
	debug.info(string.format("[color=%s]Boredom[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", state.boredom, new_boredom))
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
	debug.info(string.format("[color=%s]Happiness[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", state.happiness, new_happiness))
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
	debug.info(string.format("[color=%s]Friendship[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", state.friendship, new_friendship))
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
	return string.format("%s\n%s\n%s\n%s\n%s\n%s\n%s", boredom, evolution, friendship, happiness, hunger, morph, thirst)
end

return pet_state
