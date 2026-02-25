local FETCH_FLAVOR_TEXT = {
	"Who's a good boy?!",
	"You're a smart one.",
	"You sure like fetching sticks.",
	"You're not so bad.",
	"What a playful creature.",
	"Clever girl...",
	"Good hustle.",
	"You did it!",
	"Very nice.",
	"Again?",
	"You're a natural.",
	"You're going to need a bigger stick.",
	"I was looking for that.",
	"I can do this all day.",
	"Stop trying to make fetch happen."
}

local INVESTIGATION_FLAVOR_TEXT_GENERAL = {
	"Find something interesting?",
	"It's a curious thing...",
	"Did you notice something?",
	"Admiring my work?"
}

local INVESTIGATION_FLAVOR_TEXT_SPECIFIC = {
	"Interested in the %s?",
	"Looks like the %s caught his attention...",
	"The %s must seem strange to him...",
	"The %s seems to bother him...",
	"That's just a %s little buddy..."
}

local RENAME_FLAVOR_TEXT = {
	"%s is a good name...",
	"You look like a %s...",
	"I knight thee... %s.",
	"I dub thee... %s.",
	"Alright, %s it is.",
	"I shall call you... %s.",
	"Hope you like the name %s...",
	"Let's go with %s.",
	"You seem like a %s to me.",
	"I guess I'll call you %s...",
	"It's either %s or McBugface..."
}

local FOLLOW_ME_FLAVOR_TEXT = {
	"Here boy!",
	"Tch tch...",
	"Let's boogie...",
	"Pss pss pss...",
	"Time to go...",
	"Wanna go for a walk?",
	"Nap time's over.",
	"Follow me...",
	"Let's move..."
}

local GUARD_FLAVOR_TEXT_SPECIFIC = {
	"Why don't you watch this %s for a bit.",
	"Protect this %s at all costs.",
	"Keep an eye on this %s while I'm busy.",
	"Try not to bite the %s while I'm gone...",
	"Stand guard by the %s, okay?",
	"Make sure nothing happens to this %s.",
	"Hold down the fort here by the %s.",
	"Watch over this %s for me.",
	"Stay sharp. This %s is important.",
	"Guard this %s like your life depends on it.",
	"Defend the %s at all costs!"
}

local GUARD_FLAVOR_TEXT_GENERAL = {
	"Sit tight and keep watch.",
	"Hold this position.",
	"Stand guard for a bit.",
	"Keep watch for a bit.",
	"Stay frosty...",
	"Keep an eye out.",
	"Guard the factory.",
	"Stay alert while I'm gone."
}

local LAZY_GUARD_FLAVOR_TEXT = {
	"I said guard, not nap...",
	"I give you one job...",
	"Do I have to do everyting around here?",
	"Unbelievable...",
	"Truly the pinnacle of vigilance...",
	"I see you've worked security before...",
	"Incredible discipline...",
	"How did your species ever survive?",
	"I haven't even left yet...",
	"No more fish for you...",
	"Shameful..."
}

local PETTING_FLAVOR_TEXT = {
	"Who's a good boy?",
	"Easy, little buddy.",
	"That'll do, pig.",
	"You're not so bad...",
	"Who's my favorite little... thing?",
	"I wonder if I could automate petting...",
	"Don't get used to it...",
	"Don't pretend like you don't enjoy it...",
	"You want scritches?",
	"Who wants belly rubs!",
	"If only the other fauna were as friendly...",
	"Must calculate exact petting ratios...",
	"Does petting even work on an exoskeleton?"
}

local PETTING_MODIFIERS_AND_SETTINGS = {
	PETTING_FLAVOR_TEXT_COOLDOWN = 60 * 5,
	PETTING_REWARD_COOLDOWN = 60 * 60 * 5,
	HAPPINESS_BONUS = 1,
	FRIENDSHIP_BONUS = 1,
	BOREDOM_BONUS = -1
}

local NOTIFICATION_SETTINGS = {
	PLAYER_NOTIFICATION_OFFSET = {
		0.75,
		-1.5
	},
	MECH_NOTIFICATION_OFFSET = {
		1,
		-2
	}
}

return {
	NOTIFICATION_SETTINGS = NOTIFICATION_SETTINGS,
	FETCH_FLAVOR_TEXT = FETCH_FLAVOR_TEXT,
	INVESTIGATION_FLAVOR_TEXT_GENERAL = INVESTIGATION_FLAVOR_TEXT_GENERAL,
	INVESTIGATION_FLAVOR_TEXT_SPECIFIC = INVESTIGATION_FLAVOR_TEXT_SPECIFIC,
	RENAME_FLAVOR_TEXT = RENAME_FLAVOR_TEXT,
	FOLLOW_ME_FLAVOR_TEXT = FOLLOW_ME_FLAVOR_TEXT,
	GUARD_FLAVOR_TEXT_GENERAL = GUARD_FLAVOR_TEXT_GENERAL,
	GUARD_FLAVOR_TEXT_SPECIFIC = GUARD_FLAVOR_TEXT_SPECIFIC,
	LAZY_GUARD_FLAVOR_TEXT = LAZY_GUARD_FLAVOR_TEXT,
	PETTING_MODIFIERS_AND_SETTINGS = PETTING_MODIFIERS_AND_SETTINGS,
	PETTING_FLAVOR_TEXT = PETTING_FLAVOR_TEXT
}
