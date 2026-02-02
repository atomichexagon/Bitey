-- TODO: Have boredom slowly increase if the pet is not orphaned.
-- TODO: Implement thirst.
local debug = require("scripts.util.debug")
local pet_visuals = require("scripts.core.pet_visuals")

local HC = require("scripts.constants.hunger") -- Hunger constants.
local FC = require("scripts.constants.food") -- Food constants.
local MC = require("scripts.constants.mood") -- Mood constants.
local VC = require("scripts.constants.visuals") -- Visuals constants.

local pet_state = {}

-- State functions.
local function ensure_state(player_index)
	storage.pet_state = storage.pet_state or {}
	local s = storage.pet_state[player_index]

	if not s then
		-- Brand new pet state.
		s = {
			hunger = 100,
			loyalty = 0,
			sadness = 100,
			boredom = 0,
			feeding_target = nil
		}
		storage.pet_state[player_index] = s
	else
		-- Migration fallback.
		s.hunger = s.hunger or 100
		s.loyalty = s.loyalty or 0
		s.sadness = s.sadness or 100
		s.boredom = s.boredom or 0
		if s.feeding_target == nil then
			s.feeding_target = nil
		end
	end

	return s
end

local function ensure_queue(player_index)
	local es = storage.emote_state[player_index]
	if not es then
		es = {
			queue = {},
			active_emote = nil,
			ends_at_tick = nil,
			render_id = nil
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

function pet_state.force_emote(player_index, entry, emote)
	local es = ensure_queue(player_index)
	local now = game.tick

	-- Destroy any existing emote render.
	if es.render_id then
		es.render_id.destroy()
		es.render_id = nil
	end

	-- Clear current emote queue.
	es.queue = {}

	pet_visuals.emote(player_index, entry, emote)
end

local function tick_emotes(player_index, entry)
	debug.trace("Processing pet emote for player: " .. player_index)
	local es = ensure_queue(player_index)

	local now = game.tick

	-- Check active is emote is finished.
	if es.active then
		if now >= es.ends_at_tick then
			es.active_emote = nil
			es.ends_at_tick = nil
		else
			return -- Emote active when emote active.
		end
	end

	-- Start the next queued emote if none active.
	local next_emote = es.queue[1]
	if next_emote then
		table.remove(es.queue, 1)

		-- TODO: Need these quoted variables passed.
		local render_id = pet_visuals.emote(player_index, entry, next_emote)
		es.render_id = render_id
		es.active_emote = next_emote
		es.ends_at_tick = now + (EMOTE_DURATION or 60)
	end
end

function pet_state.tick_pet_state(player_index, entry)
	local s = ensure_state(player_index)
	local now = game.tick
	local pet = entry.unit

	s.next_hunger_tick = s.next_hunger_tick or (now + HC.HUNGER_GAIN_INTERVAL)
	if now >= s.next_hunger_tick then

		-- Increment hunger.
		s.hunger = math.min(100, s.hunger + HC.HUNGER_INCREMENT)
		s.next_hunger_tick = now + HC.HUNGER_GAIN_INTERVAL -- Schedule next hunger increase.

		-- Update mood based on stats
		s.mood = pet_state.calculate_mood(player_index)
		debug.trace("Queuing next mood emote: " .. s.mood)
		pet_state.queue_emote(player_index, pet, s.mood)

		-- Add mood to emote queue.
		tick_emotes(player_index, entry)

	end
end

-- General mood functions.

local function pick_random_mood(player_index, mood_table)
	local n = #mood_table
	if n == 0 then
		return nil
	end

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
function pet_state.calculate_mood(player_index)
	local s = ensure_state(player_index)

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

	-- Extreme states.
	local mood_table = {}
	if s.hunger >= MC.STARVING then
		mood_table[#mood_table + 1] = "hungry"
	end
	if s.boredom >= MC.FRUSTRATED then
		mood_table[#mood_table + 1] = "angry"
	end
	if s.sadness >= MC.DEPRESSED then
		mood_table[#mood_table + 1] = "crying"
	end
	if s.loyalty >= MC.DEVOTED then
		mood_table[#mood_table + 1] = "love"
	end
	if next(mood_table) ~= nil then
		return pick_random_mood(player_index, mood_table)
	end

	-- Alarming states.
	if s.hunger >= MC.HUNGRY then
		mood_table[#mood_table + 1] = "hungry"
	end
	if s.boredom >= MC.APATHETIC then
		mood_table[#mood_table + 1] = "bored"
	end
	if s.sadness >= MC.SAD then
		mood_table[#mood_table + 1] = "hurt"
	end
	if s.loyalty >= MC.LOYAL then
		mood_table[#mood_table + 1] = "happy"
	end
	if next(mood_table) ~= nil then
		return pick_random_mood(player_index, mood_table)
	end

	-- Mild states.
	if s.hunger >= MC.CONTENT then
		mood_table[#mood_table + 1] = "happy"
	end
	if s.boredom >= MC.ALERT then
		mood_table[#mood_table + 1] = "investigate"
	end
	if s.sadness >= MC.HAPPY then
		mood_table[#mood_table + 1] = "very_happy"
	end
	if s.loyalty >= MC.FRIENDLY then
		mood_table[#mood_table + 1] = "love"
	end
	if next(mood_table) ~= nil then
		return pick_random_mood(player_index, mood_table)
	end

	-- Contented states.
	if s.hunger >= MC.FULL then
		mood_table[#mood_table + 1] = "happy"
	end
	if s.boredom >= MC.FOCUSED then
		mood_table[#mood_table + 1] = "investigate"
	end
	if s.sadness >= MC.OVERJOYED then
		mood_table[#mood_table + 1] = "ecstatic"
	end
	if s.loyalty >= MC.WARY then
		mood_table[#mood_table + 1] = "scared"
	end
	if next(mood_table) ~= nil then
		return pick_random_mood(player_index, mood_table)
	end

	return "confused"
end

function pet_state.set_mood(player_index, mood)
	local s = ensure_state(player_index)
	s.mood = tostring(mood or "neutral")
end

-- Hunger functions.
function pet_state.set_hunger(player_index, value)
	local s = ensure_state(player_index)
	s.hunger = math.max(0, math.min(100, value))
end

function pet_state.get_hunger(player_index)
	local s = ensure_state(player_index)
	return s.hunger
end

function pet_state.add_hunger(player_index, delta)
	local s = ensure_state(player_index)
	s.hunger = math.max(0, math.min(100, s.hunger + delta))
end

function pet_state.set_feeding_target(player_index, entity)
	local s = ensure_state(player_index)
	s.feeding_target = entity or nil
end

function pet_state.get_feeding_target(player_index)
	local s = ensure_state(player_index)
	return s.feeding_target
end

function pet_state.ate_food(player_index, entry, food_value)
	local emote = "love"
	local fv = food_value or FC.FOOD_DEFAULT_SATIATION_VALUE
	local s = ensure_state(player_index)
	local satiation_mood_modifier = math.floor((s.hunger ^ 1.2) * 0.05)

	s.hunger = math.max(0, math.min(100, s.hunger - fv))
	s.loyalty = math.min(100, s.loyalty + FC.FOOD_LOYALTY_MODIFIER + satiation_mood_modifier)
	s.sadness = math.max(0, s.sadness - FC.FOOD_SADNESS_MODIFIER - satiation_mood_modifier)
	s.boredom = math.max(0, s.boredom - FC.FOOD_BOREDOM_MODIFIER - satiation_mood_modifier)

	pet_state.force_emote(player_index, entry, emote)
end

-- Boredom functions.
function pet_state.set_boredom(player_index, value)
	local s = ensure_state(player_index)
	s.boredom = math.max(0, math.min(100, value))
end

function pet_state.get_boredom(player_index)
	local s = ensure_state(player_index)
	return s.boredom
end

function pet_state.add_boredom(player_index, delta)
	local s = ensure_state(player_index)
	s.boredom = math.max(0, math.min(100, s.boredom + delta))
end

-- Sadness functions.
function pet_state.set_sadness(player_index, value)
	local s = ensure_state(player_index)
	s.sadness = math.max(0, math.min(100, value))
end

function pet_state.get_sadness(player_index)
	local s = ensure_state(player_index)
	return s.sadness
end

function pet_state.add_sadness(player_index, delta)
	local s = ensure_state(player_index)
	s.sadness = math.max(0, math.min(100, s.sadness + delta))
end

-- Loyalty functions.
function pet_state.set_loyalty(player_index, value)
	local s = ensure_state(player_index)
	s.loyalty = math.max(0, math.min(100, value))
end

function pet_state.get_loyalty(player_index)
	local s = ensure_state(player_index)
	return s.loyalty
end

function pet_state.add_loyalty(player_index, delta)
	local s = ensure_state(player_index)
	s.loyalty = math.max(0, math.min(100, s.loyalty + delta))
end

-- Pause functions.
function pet_state.pause(player_index, ticks)
	if ticks < 60 then
		ticks = 60
	end
	local s = ensure_state(player_index)
	s.pause_end_tick = game.tick + ticks
end

function pet_state.is_paused(player_index)
	local s = ensure_state(player_index)
	return s.pause_end_tick and game.tick < s.pause_end_tick
end

-- Debugging functions.
function pet_state.debug_dump(player_index)
	local s = ensure_state(player_index)
	return string.format("\n\thunger=%d\n\tloyalty=%d\n\tsadness=%d\n\tboredom=%d", s.hunger, s.loyalty, s.sadness, s.boredom)
end

return pet_state
