data:extend({
	{
		type = "technology",
		name = "pet-spitter-grief-processing",
		icon = "__biter-pet__/graphics/spitter-memorial.png",
		icon_size = 440,
		hidden = true,
		enabled = false,
		effects = {
			{
				type = "unlock-recipe",
				recipe = "pet-spitter-memorial"
			}
		},
		unit = {
			count = 1,
			ingredients = {
				{
					"automation-science-pack",
					1
				}
			},
			time = 1
		}
	},
	{
		type = "simple-entity-with-owner",
		name = "pet-spitter-remains-placeholder",
		icon = "__biter-pet__/graphics/pet-spitter-remains.png",
		icon_size = 256,
		flags = {
			"not-blueprintable",
			"not-deconstructable",
			"not-on-map",
			"not-repairable",
			"not-upgradable",
			"placeable-neutral",
			"player-creation"
		},
		allow_copy_paste = false,
		hidden_in_factoriopedia = true,
		max_health = 500,
		destructible = false,
		is_military_target = false,
		minable = {
			mining_time = 2,
			result = "pet-spitter-remains"
		},
		animations = {
			filename = "__core__/graphics/empty.png",
			width = 1,
			height = 1,
			frame_count = 1
		},
		collision_mask = {
			layers = {}
		},
		selection_box = {
			{
				-0.8,
				-0.8
			},
			{
				0.8,
				0.8
			}
		},
		selection_priority = 60
	},
	{
		type = "item",
		name = "pet-spitter-remains",
		icon = "__biter-pet__/graphics/pet-spitter-remains.png",
		auto_recycle = false,
		icon_size = 256,
		mipmap_count = 4,
		stack_size = 1,
		subgroup = "intermediate-product",
		order = "z[pet-spitter-remains]"
	},
	{
		type = "item",
		name = "pet-spitter-memorial",
		icon = "__biter-pet__/graphics/spitter-memorial-icon.png",
		icon_size = 64,
		mipmap_count = 4,
		subgroup = "defensive-structure",
		order = "z[pet-spitter-memorial]",
		place_result = "pet-spitter-memorial",
		stack_size = 1,
		recycle = false
	},
	{
		type = "recipe",
		name = "pet-spitter-memorial",
		category = "crafting-with-fluid",
		energy_required = 600,
		enabled = false,
		ingredients = {
			{
				type = "item",
				name = "refined-concrete",
				amount = 1000
			},
			{
				type = "item",
				name = "stone-brick",
				amount = 500
			},
			{
				type = "item",
				name = "wood",
				amount = 100
				
			},
			{
				type = "fluid",
				name = "sulfuric-acid",
				amount = 250
			}
		},
		results = {
			{
				type = "item",
				name = "pet-biter-memorial",
				amount = 1
			}
		}
	},
	{
		type = "recipe-category",
		name = "pet-memorial-category"
	},
	{
		type = "recipe",
		name = "pet-spitter-memorial-recipe",
		category = "pet-memorial-category",
		icon = "__biter-pet__/graphics/spitter-memorial-icon.png",
		energy_required = 1200,
		icon_size = 64,
		mipmap_count = 4,
		hidden = true,
		ingredients = {
			{
				type = "item",
				name = "pet-spitter-remains",
				amount = 1
			}
		},
		results = {}
	},
	{
		type = "assembling-machine",
		name = "pet-spitter-memorial",
		icon = "__biter-pet__/graphics/spitter-memorial-icon.png",
		icon_size = 64,
		mipmap_count = 4,
		flags = {
			"placeable-neutral",
			"player-creation",
			"not-blueprintable",
			"not-upgradable",
			"not-flammable",
			"no-automated-item-removal",
			"hide-alt-info"
		},
		working_sound = {
			sound = {
				filename = "__biter-pet__/sounds/memorial.ogg",
				volume = 0.1,
				fade_in_ticks = 300,
				fade_out_ticks = 300,
				audible_distance_modifier = 20
			}
		},
		minable = {
			mining_time = 0.5,
			result = "pet-spitter-memorial",
			mining_particle = nil
		},
		max_health = 1000,
		corpse = "small-remnants",
		collision_box = {
			{
				-3.5,
				0
			},
			{
				3.5,
				6
			}
		},
		selection_box = {
			{
				-3.5,
				0
			},
			{
				3.5,
				6
			}
		},
		crafting_categories = {
			"pet-memorial-category"
		},
		fixed_recipe = "pet-spitter-memorial-recipe",
		crafting_speed = 1,
		ingredient_count = 1,
		allowed_effects = {},
		energy_source = {
			type = "void"
		},
		energy_usage = "1W",
		graphics_set = {
			animation = {
				filename = "__biter-pet__/graphics/spitter-memorial.png",
				width = 440,
				height = 440
			}
		}
	}
})
