local SCALING = require("__biter-pet__.shared.scaling")
local SCALE = SCALING.SIZE_SCALE
local SPEED = SCALING.SPEED_SCALE
local HEALTH = SCALING.HEALTH_SCALE

local BASES = {
	biter = "small-biter",
	mediumbiter = "medium-biter",
	bigbiter = "big-biter",
	behemothbiter = "behemoth-biter",

	spitter = "small-spitter",
	mediumspitter = "medium-spitter",
	bigspitter = "big-spitter",
	behemothspitter = "behemoth-spitter"
}

local TIERS = {
	baby = "baby",
	small = "small",
	large = "large"
}

local function make_pet_variant(base, name)
	local scale_factor = SCALE[name]
	local pet = table.deepcopy(data.raw.unit[base])
	pet.name = name
	pet.ai_settings = nil

	local function scale_layer(layer)
		layer.tint = {
			r = 0.8,
			g = 0.7,
			b = 0.8,
			a = 1
		}
		if layer.hr_version then layer.hr_version.tint = nil end
		layer.scale = (layer.scale or 1) * scale_factor

		if layer.shift then
			layer.shift = {
				layer.shift[1] * scale_factor,
				layer.shift[2] * scale_factor
			}
		end

		if layer.high_resolution_version then scale_layer(layer.high_resolution_version) end
	end

	local function process_animation(animation)
		if not animation then return end
		if animation.layers then
			for _, layer in pairs(animation.layers) do scale_layer(layer) end
		else
			scale_layer(animation)
		end
	end

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

	local base_health = pet.max_health or 1
	local health_scale = HEALTH[name] or 1
	pet.max_health = math.floor(base_health * health_scale)
	pet.map_color = {r = 0.3, g = 0.9, b = 0.3}
	return pet
end

local function make_sleeping_pet_variant(base, name)
	local function normalize_name(name)
		return name:gsub("-sleeping", "")
	end

	local base_name = normalize_name(name)
	local scale_factor = SCALE[base_name]

	local pet = table.deepcopy(data.raw.unit[base])
	pet.name = name

	pet.movement_speed = SPEED["sleeping"] or 0.01
	pet.attack_parameters.acquisition_fire_range = 0
	pet.attack_parameters.range = 0
	pet.attack_from_start_frame = false
	pet.vision_distance = 0
	pet.ai_settings = nil
	pet.distraction_cooldown = 0

	pet.run_animation = make_sleep_animation_transparent()
	pet.dying_animation = nil
	pet.water_reflection = nil

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

	local base_health = pet.max_health or 1
	local health_scale = HEALTH[name] or 1
	pet.max_health = math.floor(base_health * health_scale)
	pet.map_color = {r = 0.3, g = 0.9, b = 0.3}
	return pet
end

local function make_idle_variant(active_table, idle_name, speed_multiplier)
	local base = table.deepcopy(active_table)

	base.name = idle_name
	base.movement_speed = (base.movement_speed or 0.1) * speed_multiplier
	base.ai_settings = nil

	local function adjust_animation(anim)
		if not anim then return end
		if anim.layers then
			for _, layer in pairs(anim.layers) do layer.animation_speed = (layer.animation_speed or 1) * speed_multiplier end
		else
			anim.animation_speed = (anim.animation_speed or 1) * speed_multiplier
		end
	end

	adjust_animation(base.run_animation)
	adjust_animation(base.attack_parameters and base.attack_parameters.animation)

	return base
end

local active_variants = {}
local sleeping_variants = {}
local idle_variants = {}

for species, base in pairs(BASES) do
	for _, tiers in pairs(TIERS) do
		local name = "pet-" .. base .. "-" .. tiers

		local active_pet = make_pet_variant(base, name)
		table.insert(active_variants, active_pet)

		local sleeping_name = name .. "-sleeping"
		table.insert(sleeping_variants, make_sleeping_pet_variant(base, sleeping_name))

		local idle_name = name .. "-idle"
		table.insert(idle_variants, make_idle_variant(active_pet, idle_name, SPEED["idle"]))
	end
end

data:extend(active_variants)
data:extend(sleeping_variants)
data:extend(idle_variants)
