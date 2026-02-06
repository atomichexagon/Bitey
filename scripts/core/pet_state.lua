local debug = require("scripts.util.debug")
local pet_visuals = require("scripts.core.pet_visuals")
local t = require("scripts.util.text_format")

local TF = require("scripts.constants.text_format") -- Text color constants.

local NEEDS_CONSTANTS = require("scripts.constants.needs")
local PET_NEEDS = NEEDS_CONSTANTS.NEEDS_CONSTANTS

local PET_VISUALS_CONSTANTS = require("scripts.constants.visuals")
local RENDER_SETTINGS = PET_VISUALS_CONSTANTS.RENDER_SETTINGS

local FOOD_CONSTANTS = require("scripts.constants.food")
local FOOD_DEFINITIONS = FOOD_CONSTANTS.FOOD_DEFINITIONS

local THRESHOLD_CONSTANTS = require("scripts.constants.thresholds")
local MOOD_THRESHOLDS = THRESHOLD_CONSTANTS.MOOD_THRESHOLDS

local pet_state = {}

-- State functions.
local function ensure_state(player_index)
	storage.pet_state = storage.pet_state or {}
	local s = storage.pet_state[player_index]

	if not s then
		-- Brand new pet state.
		s = {
			boredom = 50,
			evolution = 0,
			friendship = 0,
			happiness = 0,
			hunger = 100,
			morph = 0,
			thirst = 100,
			tiredness = 0,
			feeding_target = nil
		}
		storage.pet_state[player_index] = s
	else
		-- NOTE: Stop forgetting to update migrations if you don't want existing saves to break.
		s.boredom = s.boredom or 50
		s.evolution = s.evolution or 0
		s.friendship = s.friendship or 0
		s.happiness = s.happiness or 0
		s.hunger = s.hunger or 100
		s.morph = s.morph or 0
		s.thirst = s.thirst or 100
		s.tiredness = s.tiredness or 0
		if s.feeding_target == nil then s.feeding_target = nil end
	end

	return s
end

local function ensure_queue(player_index)
	local es = storage.emote_state[player_index]
	if not es then
		es = {
			queue = {},
			forced_queue = {},
			active_emote = nil,
			ends_at_tick = nil,
			sprite_render = nil
		}
		storage.emote_state[player_index] = es
	end
	return es
end

function pet_state.get(player_index)
	return ensure_state(player_index)
end

function pet_state.set_state(player_index, new_state)
	local s = ensure_state(player_index)
	s.state = new_state
end

function pet_state.get_state(player_index)
	local s = ensure_state(player_index)
	return s.state or "idle"
end

function pet_state.queue_emote(player_index, pet, emote)
	local es = ensure_queue(player_index)
	if pet and pet.valid then
		local es = storage.emote_state[player_index]
		es.queue[#es.queue + 1] = emote
	end
end

function pet_state.start_next_forced_emote(player_index, entry, fast_render)
	local es = ensure_queue(player_index)
	local next_emote = table.remove(es.forced_queue, 1)
	if not next_emote then return end

	local sprite_render = pet_visuals.emote(player_index, entry, next_emote, fast_render)
	es.sprite_render = sprite_render
	es.active_emote = next_emote
	es.active_type = "forced"
	es.ends_at_tick = game.tick + 180 + RENDER_SETTINGS.EMOTE_DURATION or 180
end

function pet_state.on_emote_finished(player_index, entry)
	local es = ensure_queue(player_index)

	-- If this was a forced emote, start the next one immediately.
	if es.active_type == "forced" then
		es.active_emote = nil
		es.active_type = nil
		es.ends_at_tick = nil

		pet_state.start_next_forced_emote(player_index, entry)
		return
	end

	-- Otherwise, mood emotes will be handled by tick_emotes().
end

function pet_state.force_emote(player_index, entry, emote, fast_render)
	local es = ensure_queue(player_index)

	-- Destroy any mood emote render to clear way for event-driven emote.
	if (es.sprite_render and es.active_type ~= "forced") then
		if es.sprite_render.sprite and es.sprite_render.sprite.valid then es.sprite_render.sprite.destroy() end
		if es.sprite_render.light and es.sprite_render.light.valid then es.sprite_render.light.destroy() end
		es.sprite_render = nil
	end

	es.active_emote = nil
	es.ends_at_tick = nil

	-- Clear current emote queue.
	es.queue = {}

	table.insert(es.forced_queue, emote)

	-- If nothing is active, fire emote immediately.
	if not es.active_type then
		debug.info("An event has triggered a forced emote [" .. emote .. "].")
		pet_state.start_next_forced_emote(player_index, entry, fast_render)
	end
end

local function tick_emotes(player_index, entry)
	local es = ensure_queue(player_index)

	local now = game.tick

	-- Check active is emote is finished.
	if es.active then
		if now >= es.ends_at_tick then
			es.active_emote = nil
			es.ends_at_tick = nil
		else
			return
		end
	end

	-- Start the next queued emote if none active.
	local next_emote = es.queue[1]
	if next_emote then
		table.remove(es.queue, 1)

		local sprite_render = pet_visuals.emote(player_index, entry, next_emote)
		es.sprite_render = sprite_render
		es.active_emote = next_emote
		es.ends_at_tick = now + (RENDER_SETTINGS.EMOTE_DURATION or 180)
	end
end

function pet_state.tick_pet_state(player_index, entry)
	local s = ensure_state(player_index)
	local now = game.tick
	local pet = entry.unit

	-- | Hunger |--------------------------------------
	s.next_hunger_tick = s.next_hunger_tick or (now + PET_NEEDS.HUNGER_INTERVAL)
	if now >= s.next_hunger_tick then
		pet_state.add_hunger(player_index, PET_NEEDS.HUNGER_INCREMENT)
		s.next_hunger_tick = now + PET_NEEDS.HUNGER_INTERVAL

		if s.hunger >= MOOD_THRESHOLDS.STARVING then
			debug.info(string.format("Severe %s has incurred %s penalty", t.f("hunger", "e"), t.f("happiness", "f")))
			pet_state.add_happiness(player_index, PET_NEEDS.SEVERE_HUNGER_PENALTY)
		end
	end

	-- | Thirst |------------------------------------------
	s.next_thirst_tick = s.next_thirst_tick or (now + PET_NEEDS.THIRST_INTERVAL)
	if now >= s.next_thirst_tick then
		pet_state.add_thirst(player_index, PET_NEEDS.THIRST_INCREMENT)
		s.next_thirst_tick = now + PET_NEEDS.THIRST_INTERVAL

		if s.thirst >= MOOD_THRESHOLDS.DEHYDRATED then
			debug.info(string.format("Severe %s has incurred %s penalty", t.f("thirst", "e"), t.f("happiness", "f")))
			pet_state.add_happiness(player_index, PET_NEEDS.SEVERE_THIRST_PENALTY)
		end
	end

	-- | Boredom |-----------------------------------------
	s.next_boredom_tick = s.next_boredom_tick or (now + PET_NEEDS.BOREDOM_INTERVAL)
	if now >= s.next_boredom_tick then
		pet_state.add_boredom(player_index, PET_NEEDS.BOREDOM_INCREMENT)
		s.next_boredom_tick = now + PET_NEEDS.BOREDOM_INTERVAL

		if s.boredom >= MOOD_THRESHOLDS.FRUSTRATED then
			debug.info(string.format("Severe %s has incurred %s penalty", t.f("boredom", "e"), t.f("happiness", "f")))
			pet_state.add_happiness(player_index, PET_NEEDS.SEVERE_BOREDOM_PENALTY)
		end
	end

	-- | Mood |--------------------------------------------
	s.next_mood_calc_tick = s.next_mood_calc_tick or (now + PET_NEEDS.MOOD_RECALCULATION_INTERVAL)
	if now >= s.next_mood_calc_tick then
		-- Recalculate mood.
		s.mood = pet_state.calculate_mood(player_index)
		debug.info(string.format("%s [%s]", "A new mood has been calculated and queued", t.f(s.mood, "f")))
		pet_state.queue_emote(player_index, pet, s.mood)
		s.next_mood_calc_tick = now + PET_NEEDS.MOOD_RECALCULATION_INTERVAL

		if s.friendship <= MOOD_THRESHOLDS.DEPRESSED then
			debug.info(string.format("Severe %s has incurred %s penalty", t.f("happiness", "e"), t.f("friendship", "f")))
			pet_state.add_friendship(player_index, PET_NEEDS.SEVERE_SADNESS_PENALTY)
		end

		-- Add mood to queue if no forced emote is currently not active.
		local es = ensure_queue(player_index)
		if (es.active_type ~= "forced") then tick_emotes(player_index, entry) end
	end
end

-- General mood functions.
local function pick_random_mood(player_index, mood_table)
	local n = #mood_table
	if n == 0 then return nil end

	local last = storage.last_mood[player_index]

	-- Initial pick from available options.
	local idx = math.random(n)
	local mood = mood_table[idx]

	-- If pick same as last time and more than one option, retry once.
	if mood == last and n > 1 then
		idx = math.random(n)
		mood = mood_table[idx]
	end

	storage.last_mood[player_index] = mood
	return mood
end

-- Evaluate each tier of potential mood states and return dictionary of most extreme tier for emoting.

--[[
		TODO: Add event reactions.
		Possible in-game events the pet can react to:
			Incoming biter attack party.
			Player is attacked.
			Thresholds of enemy biter evolution (20%, 25%, 40%).
			Senses entity is on fire or current on fire themself.
			Small random chance to ride on belt.
			Small random chance to attack tree.
			Small random chance to investigate entity.
			Etc.
	]]

function pet_state.calculate_mood(player_index)
	local s = ensure_state(player_index)

	local mood_table = {}
	-- All pet needs are met and stats are above average.
	if (s.hunger < MOOD_THRESHOLDS.CONTENT and s.boredom < MOOD_THRESHOLDS.ALERT and s.happiness > MOOD_THRESHOLDS.HAPPY and
			s.friendship > MOOD_THRESHOLDS.DEVOTED) then
		mood_table[#mood_table + 1] = "ecstatic"
		return pick_random_mood(player_index, mood_table)
	end

	-- Extreme states.
	if s.hunger >= MOOD_THRESHOLDS.STARVING then mood_table[#mood_table + 1] = "hungry" end
	if s.boredom >= MOOD_THRESHOLDS.FRUSTRATED then mood_table[#mood_table + 1] = "angry" end
	if s.happiness <= MOOD_THRESHOLDS.DEPRESSED then mood_table[#mood_table + 1] = "very-sad" end
	if s.friendship >= MOOD_THRESHOLDS.DEVOTED then mood_table[#mood_table + 1] = "love" end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	-- Alarming states.
	if s.hunger >= MOOD_THRESHOLDS.HUNGRY then mood_table[#mood_table + 1] = "hungry" end
	if s.boredom >= MOOD_THRESHOLDS.APATHETIC then mood_table[#mood_table + 1] = "bored" end
	if s.happiness <= MOOD_THRESHOLDS.SAD then mood_table[#mood_table + 1] = "sad" end
	if s.friendship >= MOOD_THRESHOLDS.LOYAL then mood_table[#mood_table + 1] = "happy" end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	-- Mild states.
	if s.hunger >= MOOD_THRESHOLDS.CONTENT then mood_table[#mood_table + 1] = "happy" end
	if s.boredom >= MOOD_THRESHOLDS.ALERT then mood_table[#mood_table + 1] = "investigate" end
	if s.happiness <= MOOD_THRESHOLDS.HAPPY then mood_table[#mood_table + 1] = "happy" end
	if s.friendship >= MOOD_THRESHOLDS.FRIENDLY then mood_table[#mood_table + 1] = "love" end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	-- Contented states.
	if s.hunger >= MOOD_THRESHOLDS.FULL then mood_table[#mood_table + 1] = "happy" end
	if s.boredom >= MOOD_THRESHOLDS.FOCUSED then mood_table[#mood_table + 1] = "investigate" end
	if s.happiness <= MOOD_THRESHOLDS.OVERJOYED then mood_table[#mood_table + 1] = "very-happy" end
	if s.friendship >= MOOD_THRESHOLDS.WARY then mood_table[#mood_table + 1] = "scared" end
	if next(mood_table) ~= nil then return pick_random_mood(player_index, mood_table) end

	return "confused"
end

function pet_state.set_mood(player_index, mood)
	local s = ensure_state(player_index)
	s.mood = tostring(mood or "neutral")
end

-- Hunger functions.
function pet_state.get_hunger(player_index)
	local s = ensure_state(player_index)
	return s.hunger
end

function pet_state.set_hunger(player_index, value)
	local s = ensure_state(player_index)
	s.hunger = math.max(0, math.min(100, value))
end

function pet_state.add_hunger(player_index, delta)
	local s = ensure_state(player_index)
	delta = delta or PET_NEEDS.HUNGER_INCREMENT
	local new_hunger = math.max(0, math.min(100, s.hunger + (delta)))

	debug.info(string.format("[color=%s]Hunger[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", s.hunger, new_hunger))
	s.hunger = new_hunger
end

function pet_state.set_feeding_target(player_index, entity)
	local s = ensure_state(player_index)
	s.feeding_target = entity or nil
end

function pet_state.get_feeding_target(player_index)
	local s = ensure_state(player_index)
	return s.feeding_target
end

function pet_state.ate_food(player_index, entry, food)
	debug.info(string.format("%s %s", "Eating food item ", food))

	local food_mod_table = FOOD_DEFINITIONS[food]
	if not food_mod_table then
		debug.warn(string.format("%s %s", "FOOD_DEFINITIONS missing entry for: ", t.f(food, "w")))
		return
	end

	local s = ensure_state(player_index)

	-- Mood scaling based on hunger severity.
	local mood_bonus = math.floor((s.hunger ^ 1.2) * 0.025)

	local bordome = food_mod_table.boredom or 0
	local evolution = food_mod_table.evolution or 0
	local friendship = food_mod_table.friendship or 0
	local happiness = food_mod_table.happiness or 0
	local hunger = food_mod_table.hunger or 0
	local morph = food_mod_table.morph or 0
	local thirst = food_mod_table.thirst or 0
	local tiredness = food_mod_table.tiredness or 0

	-- Mood state effects.
	pet_state.add_boredom(player_index, food_mod_table.boredom - mood_bonus)
	pet_state.add_friendship(player_index, food_mod_table.friendship + mood_bonus)
	pet_state.add_happiness(player_index, food_mod_table.happiness + mood_bonus)

	-- Pysiological state effects.
	pet_state.add_evolution(player_index, food_mod_table.evolution)
	pet_state.add_hunger(player_index, food_mod_table.hunger)
	pet_state.add_morph(player_index, food_mod_table.morph)
	pet_state.add_thirst(player_index, food_mod_table.thirst)
	pet_state.add_tiredness(player_index, food_mod_table.tiredness)
end

-- Thirst functions.
function pet_state.get_thirst(player_index)
	local s = ensure_state(player_index)
	return s.thirst
end

function pet_state.set_thirst(player_index, value)
	local s = ensure_state(player_index)
	s.thirst = math.max(0, math.min(100, value))
end

function pet_state.add_thirst(player_index, delta)
	local s = ensure_state(player_index)
	local new_thirst = math.max(0, math.min(100, s.thirst + delta))
	debug.info(string.format("[color=%s]Thirst[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", s.thirst, new_thirst))
	s.thirst = new_thirst
end

-- Tiredness functions.
function pet_state.get_tiredness(player_index)
	local s = ensure_state(player_index)
	return s.tiredness
end

function pet_state.set_tiredness(player_index, value)
	local s = ensure_state(player_index)
	s.tiredness = math.max(0, math.min(100, value))
end

function pet_state.add_tiredness(player_index, delta)
	local s = ensure_state(player_index)
	local new_tiredness = math.max(0, math.min(100, s.tiredness + delta))
	debug.info(string.format("[color=%s]Tireness[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", s.tiredness, new_tiredness))
	s.thirst = new_tiredness
end

-- Morph functions.
function pet_state.get_morph(player_index)
	local s = ensure_state(player_index)
	return s.morph
end

function pet_state.set_morph(player_index, value)
	local s = ensure_state(player_index)
	s.morph = math.max(0, math.min(100, value))
end

function pet_state.add_morph(player_index, delta)
	local s = ensure_state(player_index)
	local new_morph = math.max(0, math.min(100, s.morph + delta))
	debug.info(string.format("[color=%s]Morph[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", s.morph, new_morph))
	s.morph = new_morph
end

-- Evolution functions.
function pet_state.get_evolution(player_index)
	local s = ensure_state(player_index)
	return s.evolution
end

function pet_state.set_evolution(player_index, value)
	local s = ensure_state(player_index)
	s.evolution = math.max(0, math.min(100, value))
end

function pet_state.add_evolution(player_index, delta)
	local s = ensure_state(player_index)
	local new_evolution = math.max(0, math.min(100, s.evolution + delta))
	debug.info(string.format("[color=%s]Evolution[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", s.evolution, new_evolution))
	s.evolution = new_evolution
end

-- Boredom functions.
function pet_state.get_boredom(player_index)
	local s = ensure_state(player_index)
	return s.boredom
end

function pet_state.set_boredom(player_index, value)
	local s = ensure_state(player_index)
	s.boredom = math.max(0, math.min(100, value))
end

function pet_state.add_boredom(player_index, delta)
	local s = ensure_state(player_index)
	local new_boredom = math.max(0, math.min(100, s.boredom + delta))
	debug.info(string.format("[color=%s]Boredom[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", s.boredom, new_boredom))
	s.boredom = new_boredom
end

-- Happiness functions.
function pet_state.get_happiness(player_index)
	local s = ensure_state(player_index)
	return s.happiness
end

function pet_state.set_happiness(player_index, value)
	local s = ensure_state(player_index)
	s.happiness = math.max(0, math.min(100, value))
end

function pet_state.add_happiness(player_index, delta)
	local s = ensure_state(player_index)
	local new_happiness = math.max(0, math.min(100, s.happiness + delta))
	debug.info(string.format("[color=%s]Happiness[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", s.happiness, new_happiness))
	s.happiness = new_happiness
end

-- Friendship functions.
function pet_state.get_friendship(player_index)
	local s = ensure_state(player_index)
	return s.friendship
end

function pet_state.set_friendship(player_index, value)
	local s = ensure_state(player_index)
	s.friendship = math.max(0, math.min(100, value))
end

function pet_state.add_friendship(player_index, delta)
	local s = ensure_state(player_index)
	local new_friendship = math.max(0, math.min(100, s.friendship + delta))
	debug.info(string.format("[color=%s]Friendship[/color] %s from %s to %s.", TF.INFO_COLOR,
			(delta > 0 and "increased") or "decreased", s.friendship, new_friendship))
	s.friendship = new_friendship
end

-- Pause functions.
function pet_state.pause(player_index, ticks)
	if ticks < 60 then ticks = 60 end
	local s = ensure_state(player_index)
	s.pause_end_tick = game.tick + ticks
end

function pet_state.is_paused(player_index)
	local s = ensure_state(player_index)
	return s.pause_end_tick and game.tick < s.pause_end_tick
end

function pet_state.debug_dump(player_index)
	local s = ensure_state(player_index)
	local boredom = string.format("%s %s", t.fm("Boredeom:", "f"), t.fm(s.boredom, "m", 1))
	local evolution = string.format("%s %s", t.fm("Evolution:", "f"), t.fm(s.evolution, "m", 1))
	local friendship = string.format("%s %s", t.fm("Friendship:", "f"), t.fm(s.friendship, "m", 1))
	local happiness = string.format("%s %s", t.fm("Happiness:", "f"), t.fm(s.happiness, "m", 1))
	local hunger = string.format("%s %s", t.fm("Hunger:", "f"), t.fm(s.hunger, "m", 1))
	local morph = string.format("%s %s", t.fm("Morph:", "f"), t.fm(s.morph, "m", 1))
	local thirst = string.format("%s %s", t.fm("Thirst:", "f"), t.fm(s.thirst, "m", 1))
	return string.format("%s\n%s\n%s\n%s\n%s\n%s\n%s", boredom, evolution, friendship, happiness, hunger, morph, thirst)
end

return pet_state
