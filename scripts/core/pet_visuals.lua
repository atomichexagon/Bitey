local pet_visuals = {}

function pet_visuals.show_pet_reaction(pet, text, opts)
    if not (pet and pet.valid) then return end

    opts = opts or {}

    local color = opts.color or {r = 0.75, g = 0, b = 0, a = 1.0} -- default: pinkish heart color
    local scale = opts.scale or 1.0
    local drift = opts.drift or 0.02 -- Upward drift per tick.
    local fade = opts.fade or 0.02 -- Alpha fade per tick.

    -- Create the text slightly above the pet.
    local id = rendering.draw_text {
        text = text,
        surface = pet.surface,
        target = pet,
        color = color,
        scale = scale,
        alignment = "center",
        vertical_alignment = "bottom"
    }

    -- Optional upward drift animation.
    if drift ~= 0 then
        -- Store drift info so on_tick can animate it.
        storage.pet_reaction_drift = storage.pet_reaction_drift or {}
        table.insert(storage.pet_reaction_drift, {
            id = id,
            color = color,
            fade = fade,
            pet = pet,
            drift = drift,
            start_tick = game.tick
        })
    end
end

return pet_visuals

-- A - Home (house icon)
-- B - Attack (sword icon)
-- C - Stay (map pin icon)
-- D - Sleeping (hourglass icon)
-- E - Work (hammer icon)
-- F - Biter (bug icon)
-- G - Gift (gift icon)
-- H - Hungry (spoon-knife icon)
-- I - Fire (fire icon)
-- J - Defend (shield icon)
-- K - Patrol (flag icon)
-- K - Investigate (eye icon)
-- M - Love (heart icon)
-- N - Hurt (broken heart icon)
-- O - Very happy (smiley face icon)
-- P - Happy (smiley face icon)
-- Q - Sad (sad face icon)
-- R - Extremely happy (toothy grin icon)
-- S - Michievous (devil smiley face icon)
-- T - Scared (shocked face icon)
-- U - Confused (confused face icon)
-- V - Sick (sick face icon)
-- W - Bored (bored face icon)
-- X - Tired - (yawning face icon)
-- Y - Angry (angry face)
-- Z - Very sad (crying face icon)
-- 1 - Alert (warning)
-- 2 - Play (ball)

