local events = require("scripts.core.events")
local debug = require("scripts.util.debug")
local pet_lifecycle = require("scripts.core.pet_lifecycle")
local pet_state = require("scripts.core.pet_state")

-- Console commands.
commands.add_command("petstatus", "Show pet status for the calling player.",
                     function(cmd)
    local player = game.get_player(cmd.player_index)
    if not player then
        game.print("[BP] /petstatus must be run by a player.")
        return
    end
    local state = pet_state.get(player.index)
    game.print("[BP] Pet state: " .. pet_state.debug_dump(player.index))

    pet_lifecycle.print_status_for_players(player)
end)

commands.add_command("petdebuglevel", "Set debug level.", function(cmd)
    local lvl = tonumber(cmd.parameter)
    if lvl then
        debug.set_level(lvl)
    else
        game.print("Usage: /petdebuglevel <0-4>")
    end
end)

script.on_init(function() events.on_init() end)
script.on_load(function() events.on_load() end)
script.on_configuration_changed(function(cfg)
    events.on_configuration_changed(cfg)
end)

-- Event wiring
script.on_event(defines.events.on_player_created, events.on_player_created)
script.on_event(defines.events.on_entity_died, events.on_entity_died)

script.on_event(defines.events.on_tick, function(event)
    -- Main mod tick.
    events.on_tick(event)

    -- Pet reaction animation.
    if not storage.pet_reaction_drift then return end
    local drift_queue = storage.pet_reaction_drift
    if not drift_queue or #drift_queue == 0 then return end

    for i = #drift_queue, 1, -1 do
        local r = drift_queue[i]

        if not (r.id and r.id.valid) then
            table.remove(drift_queue, i)
        else
            local age = game.tick - r.start_tick

            -- Drift and scale.
            local offset = {0, -0.5 - (age * r.drift)}
            r.id.target = {entity = r.pet, offset = offset}
            r.id.scale = r.id.scale + 0.01

            -- Fade out text.
            local new_alpha = math.max(0, r.color.a - age * r.fade)
            r.id.color = {
                r = r.color.r,
                g = r.color.g,
                b = r.color.b,
                a = new_alpha
            }
            -- Remove text if it's already invisible.
            if new_alpha <= 0 then
                r.id.destroy()
                table.remove(drift_queue, i)
            end
        end
    end
end)
