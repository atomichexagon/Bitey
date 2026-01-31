local debug = require("scripts.util.debug")

local VC = require("scripts.constants.visuals") -- Visuals constants.

pet_visuals = {}

-- Convert RGB values to normalized RGBA.
local function rgb(r, g, b, a)
	-- Only exists because I can't find a VS Code color preview extension for normalized RGBA values in Lua.
    return {r = r / 255, g = g / 255, b = b / 255, a = a or 1}
end

-- TODO: Add queuing system so emotes do not visually overlap.
local EMOTE_MAP = {
    -- General emotes.
    home = {char = "A", color = rgb(50, 0, 50)},
    sleeping = {char = "D", color = rgb(0, 0, 50)},
    work = {char = "E", color = rgb(0, 50, 0)},
    investigate = {char = "L", color = rgb(50, 0, 50)},
    tired = {char = "X", color = rgb(0, 50, 0)},
    alert = {char = "1", color = rgb(50, 50, 0)},

    -- Combat emotes.
    attack = {char = "B", color = rgb(50, 0, 0)},
    stay = {char = "C", color = rgb(0, 50, 0)},
    biter = {char = "F", color = rgb(50, 50, 0)},
    fire = {char = "I", color = rgb(50, 0, 0)},
    defend = {char = "J", color = rgb(0, 50, 50)},
    patrol = {char = "K", color = rgb(0, 50, 50)},
    scared = {char = "T", color = rgb(50, 50, 0)},

    -- Feeding emotes.
    hungry = {char = "H", color = rgb(50, 50, 0)},
    sick = {char = "V", color = rgb(0, 50, 0)},

    -- Boredom emotes.
    bored = {char = "W", color = rgb(0, 0, 50)},
    play = {char = "2", color = rgb(0, 50, 0)},
    mischievous = {char = "S", color = rgb(50, 0, 0)},
    confused = {char = "U", color = rgb(0, 0, 50)},

    -- Sadness emotes.
    ecstatic = {char = "R", color = rgb(0, 50, 0)},
    very_happy = {char = "O", color = rgb(0, 50, 0)},
    happy = {char = "P", color = rgb(0, 50, 50)},
    sad = {char = "Q", color = rgb(50, 0, 0)},
    crying = {char = "Z", color = rgb(255, 255, 255)},

    -- Loyalty emotes.
    love = {char = "M", color = rgb(200, 0, 0)},
    gift = {char = "G", color = rgb(0, 50, 0)},
    hurt = {char = "N", color = rgb(200, 0, 0)},
    angry = {char = "Y", color = rgb(50, 0, 0)}
}

function pet_visuals.emote(pet, key)
    local data = EMOTE_MAP[key]
    local text = (data and data.char) or key
    local color = (data and data.color) or rgb(0, 0, 0)
    local render_id = pet_visuals.show_pet_reaction(pet, text, color)
	return render_id
end

function pet_visuals.show_pet_reaction(pet, text, color)
    if not (pet and pet.valid) then return end
	local color = color or rgb(0, 0, 0)
    local render_id = rendering.draw_text {
        text = text,
        surface = pet.surface,
        target = pet,
        scale = VC.EMOTE_SCALE,
        font = "biter-pet-emotes",
        alignment = "center",
        vertical_alignment = "bottom",
        use_rich_text = true,
        color = color
    }

    if drift ~= 0 then
        -- Store drift info so on_tick can animate it.
        storage.pet_reaction_drift = storage.pet_reaction_drift or {}
        table.insert(storage.pet_reaction_drift, {
            id = render_id,
            color = color,
            fade = VC.EMOTE_FADE_RATE,
            pet = pet,
            drift = VC.EMOTE_DRIFT_RATE,
            start_tick = game.tick
        })
    end
	return render_id
end

return pet_visuals
