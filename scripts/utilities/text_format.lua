local TF = require("scripts.constants.text_format")

local text_format = {}

local function bold(text, format)

	if format == "default" then
		return string.format("[font=%s]%s[/font]", TF.DEFAULT_FONT, text)
	elseif format == "mono" then
		return string.format("[font=%s]%s[/font]", TF.DEFAULT_MONO_FONT, text)
	elseif format == "header" then
		return string.format("[font=%s]%s[/font]", TF.DEFAULT_HEADER_FONT, text)
	end
end

local function color(text, color_group)
	if color_group == "c" then
		return string.format("[color=%s]%s[/color]", TF.CLASS_COLOR, text)
	elseif color_group == "f" then
		return string.format("[color=%s]%s[/color]", TF.FUNCTION_COLOR, text)
	elseif color_group == "a" then
		return string.format("[color=%s]%s[/color]", TF.ALWAYS_COLOR, text)
	elseif color_group == "n" then
		return string.format("[color=%s]%s[/color]", TF.NONE_COLOR, text)
	elseif color_group == "e" then
		return string.format("[color=%s]%s[/color]", TF.ERROR_COLOR, text)
	elseif color_group == "w" then
		return string.format("[color=%s]%s[/color]", TF.WARN_COLOR, text)
	elseif color_group == "i" then
		return string.format("[color=%s]%s[/color]", TF.INFO_COLOR, text)
	elseif color_group == "t" then
		return string.format("[color=%s]%s[/color]", TF.TRACE_COLOR, text)
	elseif color_group == "l" then
		return string.format("[color=%s]%s[/color]", TF.LABEL_COLOR, text)
	else
		return string.format("[color=%s]%s[/color]", TF.MESSAGE_COLOR, text)
	end
end

function text_format.f(text, color_group)
	return tostring(bold(color(text, color_group), "default"))
end

function text_format.fh(text, color_group)
	return tostring(bold(color(text, color_group), "header"))
end

function text_format.fm(text, color_group, pad_length)
	local pad_length = pad_length or 15
	if pad_length then
		return tostring(bold(text_format.pad(color(text, color_group), pad_length), "mono"))
	else
		return tostring(bold(color(text, color_group), "mono"))
	end
end

local function visible_len(text)
	-- Remove any rich text tags that are present in the string.
	text = text:gsub("%b[]", "")
	return #text
end

function text_format.pad(text, pad_length)
	local visible_length = visible_len(text)
	local pad_length = math.max(0, pad_length - visible_length)
	return string.rep(" ", pad_length) .. text
end

return text_format
