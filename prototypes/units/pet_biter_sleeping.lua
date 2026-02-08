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
		name = "pet-sleeping-animation",
		filename = "__biter-pet__/graphics/small-biter-sleeping.png",
		width = 356,
		height = 348,
		scale = 0.5,
		frame_count = 3,
		line_length = 3,
		animation_speed = 0.1,
		frame_sequence = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,3,3,3,3,3,3,3,2}
	}
})
