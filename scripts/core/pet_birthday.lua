local debug = require("scripts.utilities.debug")
local notifications = require("scripts.utilities.notifications")
local pet_state = require("scripts.core.pet_state")

local BG = require("scripts.constants.gifts").BASE_GIFTS
local SG = require("scripts.constants.gifts").SPACE_AGE_GIFTS
local GQ = require("scripts.constants.gifts").GIFT_QUALITIES

local pet_birthday = {}

local function build_gift_table()
	local gifts = table.deepcopy(BG)

	if script.active_mods["space-age"] then for item, weight in pairs(SG) do gifts[item] = weight end end

	return gifts
end

local function weighted_random(table)
	local total = 0
	for _, weight in pairs(table) do total = total + weight end
	local random = math.random(total)
	for item, weight in pairs(table) do
		random = random - weight
		if random <= 0 then return item end
	end
end

local function random_quality()
	local total = 0
	for _, weight in pairs(GQ) do total = total + weight end

	local random = math.random(total)

	for quality, weight in pairs(GQ) do
		random = random - weight
		if random <= 0 then return quality end
	end
end

function pet_birthday.give_birthday_gift(player_index, player, entry)
	if not player then return end

	local gift_table = build_gift_table()
	local gift_name = weighted_random(gift_table)
	local birthday_gift = {
		name = gift_name,
		count = 1
	}

	if script.active_mods["quality"] then birthday_gift.quality = random_quality() end

	pet_state.set_behavior(player_index, "return_item")
	pet_state.set_returnable_item(player_index, birthday_gift)
	entry.birthday_tick = game.tick
end

return pet_birthday
