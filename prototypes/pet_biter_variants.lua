local function make_pet_variant(base, name, scale_factor)
    local pet = table.deepcopy(data.raw.unit[base])
    pet.name = name

    -- Helper to scale sprite properties.
    local function scale_layer(layer)
        layer.scale = (layer.scale or 1) * scale_factor

        if layer.shift then
            layer.shift = {
                layer.shift[1] * scale_factor, layer.shift[2] * scale_factor
            }
        end

        if layer.hr_version then scale_layer(layer.hr_version) end
    end

    -- Helper to traverse animation tables.
    local function process_animation(anim)
        if not anim then return end
        if anim.layers then
            for _, layer in pairs(anim.layers) do scale_layer(layer) end
        else
            scale_layer(anim)
        end
    end

    -- Apply visual scaling to all animation states.
    process_animation(pet.run_animation)
    process_animation(pet.attack_parameters.animation)
    process_animation(pet.dying_animation)
    process_animation(pet.water_reflection)

    if pet.drawing_box then
        pet.drawing_box = {
            {
                pet.drawing_box[1][1] * scale_factor,
                pet.drawing_box[1][2] * scale_factor
            },
            {
                pet.drawing_box[2][1] * scale_factor,
                pet.drawing_box[2][2] * scale_factor
            }
        }
    end

    pet.max_health = math.floor(15 * scale_factor)

    return pet
end

data:extend{
    make_pet_variant("small-biter", "pet-biter-baby", 0.65),
    make_pet_variant("small-biter", "pet-biter-small", 0.85),
    make_pet_variant("small-biter", "pet-biter-large", 1.0)
}
