-- scripts/core/pet_state.lua
-- Persistent state for each player's pet (hunger, loyalty, mood, etc.)
local debug = require("scripts.util.debug")

local pet_state = {}
local HUNGER_GAIN_ITERVAL = 1800 -- 30 seconds

local function ensure_state(player_index)
    storage.pet_state = storage.pet_state or {}
    storage.pet_state[player_index] = storage.pet_state[player_index] or {
        hunger = 100, -- 0 = Full, 100 = Starving.
        loyalty = 50, -- 0 = Wild, 100 = Devoted.
        mood = "neutral", -- Purely cosmetic for now.
        xp = 0, -- Purely cosmetic for now.
        level = 1, -- Purely cosmetic for now.

        feeding_target = nil
    }
    return storage.pet_state[player_index]
end

function pet_state.get(player_index) return ensure_state(player_index) end

function pet_state.set_state(player_index, new_state)
    local s = ensure_state(player_index)
    s.state = new_state
end

function pet_state.get_state(player_index)
    local s = ensure_state(player_index)
    return s.state or "idle"
end

function pet_state.tick_hunger(player_index)
    local s = ensure_state(player_index)
    local now = game.tick

    s.next_hunger_tick = s.next_hunger_tick or (now + HUNGER_GAIN_ITERVAL)

    if now >= s.next_hunger_tick then
        s.hunger = math.min(100, s.hunger + 1)
        s.next_hunger_tick = now + HUNGER_GAIN_ITERVAL -- Schedule next hunger increase.
    end
end

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

function pet_state.set_loyalty(player_index, value)
    local s = ensure_state(player_index)
    s.loyalty = math.max(0, math.min(100, value))
end

function pet_state.add_loyalty(player_index, delta)
    local s = ensure_state(player_index)
    s.loyalty = math.max(0, math.min(100, s.loyalty + delta))
end

function pet_state.set_mood(player_index, mood)
    local s = ensure_state(player_index)
    s.mood = tostring(mood or "neutral")
end

function pet_state.add_xp(player_index, amount)
    local s = ensure_state(player_index)
    s.xp = s.xp + (amount or 0)
end

function pet_state.set_feeding_target(player_index, entity)
    local s = ensure_state(player_index)
    s.feeding_target = entity or nil
end

function pet_state.get_feeding_target(player_index)
    local s = ensure_state(player_index)
    return s.feeding_target
end

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
    return string.format(
               "\n\thunger=%d\n\tloyalty=%d\n\tmood=%s\n\txp=%d\n\tlevel=%d",
               s.hunger, s.loyalty, s.mood, s.xp, s.level)
end

return pet_state
