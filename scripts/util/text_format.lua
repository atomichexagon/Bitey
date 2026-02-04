local FT = require("scripts.constants.text_format")

local text_format = {}

local function bold(text)
	return string.format("[font=%s]%s[/font]", FT.DEFAULT_FONT, text)
end

local function color(text, color_group)
	if not (color_group or color_group == "m") then
		return string.format("[color=%s]%s[/color]", FT.MESSAGE_COLOR, text)
	elseif color_group == "l" then
		return string.format("[color=%s]%s[/color]", FT.LABEL_COLOR, text)
	elseif color_group == "r" then
		return string.format("[color=%s]%s[/color]", FT.ERROR_COLOR, text)
	elseif color_group == "w" then
		return string.format("[color=%s]%s[/color]", FT.WARN_COLOR, text)
	elseif color_group == "i" then
		return string.format("[color=%s]%s[/color]", FT.INFO_COLOR, text)
	elseif color_group == "t" then
		return string.format("[color=%s]%s[/color]", FT.TRACE_COLOR, text)
	elseif color_group == "c" then
		return string.format("[color=%s]%s[/color]", FT.CLASS_COLOR, text)
	elseif color_group == "f" then
		return string.format("[color=%s]%s[/color]", FT.FUNCTION_COLOR, text)
	else
		return string.format("[color=%s]%s[/color]", FT.MESSAGE_COLOR, text)
	end
end

function text_format.format(text, color_group)
	return tostring(bold(color(text, color_group)))
end

return text_format
