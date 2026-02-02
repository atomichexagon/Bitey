local pet_ai = {}

-- Internal Logic: Should the pet do something idle?
local function handle_idle_behavior(pet, state)
    if state.boredom > 75 then
        -- Find a nearby tree to "investigate" (chew)
        local tree = pet.surface.find_entities_filtered{
            position = pet.position,
            radius = 10,
            type = "tree",
            limit = 1
        }[1]
        
        if tree then
            return {
                type = defines.command.attack,
                target = tree,
                distraction = defines.distraction.none
            }
        end
    end
    -- Follow player if nothing else to do
    return {
        type = defines.command.go_to_location,
        destination_entity = game.players[pet.player_index].character,
        radius = 5,
        distraction = defines.distraction.by_enemy
    }
end

function pet_ai.update(pet, state)
    if not pet.valid then return end
    
    -- 1. Check for urgent overrides (Combat, Scared, etc.)
    -- 2. Check for "Jobs" (Eating, Fetching)
    -- 3. Fallback to Idle behaviors
    local command = handle_idle_behavior(pet, state)
    
    pet.set_command(command)
end

return pet_ai