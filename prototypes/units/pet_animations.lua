function make_sleep_animation_transparent()
	return {
		layers = {
			{
				filename = "__biter-pet__/graphics/small-biter-sleeping-transparent.png",
				width = 1,
				height = 1,
				frame_count = 1,
				direction_count = 1,
				scale = 1
			}
		}
	}
end

data:extend({
	{
		type = "animation",
		name = "sleeping-right-biter",
		filename = "__biter-pet__/graphics/small-biter-sleeping-right.png",
		width = 356,
		height = 348,
		scale = 0.5,
		frame_count = 3,
		line_length = 3,
		animation_speed = 0.1,
		frame_sequence = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,3,3,3,3,3,3,3,2}
	},
	{
		type = "animation",
		name = "sleeping-left-biter",
		filename = "__biter-pet__/graphics/small-biter-sleeping-left.png",
		width = 356,
		height = 348,
		scale = 0.5,
		frame_count = 3,
		line_length = 3,
		animation_speed = 0.1,
		frame_sequence = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,3,3,3,3,3,3,3,2}
	},
	{
		type = "animation",
		name = "sleeping-right-spitter",
		filename = "__biter-pet__/graphics/small-spitter-sleeping-right.png",
		width = 356,
		height = 348,
		scale = 0.5,
		frame_count = 3,
		line_length = 3,
		animation_speed = 0.1,
		frame_sequence = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,3,3,3,3,3,3,3,2}
	},
	{
		type = "animation",
		name = "sleeping-left-spitter",
		filename = "__biter-pet__/graphics/small-spitter-sleeping-left.png",
		width = 356,
		height = 348,
		scale = 0.5,
		frame_count = 3,
		line_length = 3,
		animation_speed = 0.1,
		frame_sequence = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,3,3,3,3,3,3,3,2}
	},
	{
		type = "animation",
		name = "show-affection",
		filename = "__biter-pet__/graphics/hand.png",
		width = 66,
		height = 64,
		scale = 0.5,
		frame_count = 6,
		line_length = 6,
		animation_speed = 0.4,
		frame_sequence = {1,1,2,2,3,3,4,4,5,5,6,6,5,4,3,2}
	}
})