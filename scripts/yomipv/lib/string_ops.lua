--[[ String operations and text utilities                 ]]
--[[ Text cleaning, subtitle sanitization, and formatting ]]

local StringOps = {}

-- Pattern for matching control characters and formatting codes
local CONTROL_CHARS_PATTERN = "[\1-\31\127]"
local WHITESPACE_PATTERN = "[ \t\n\r]+"
local SUBTITLE_TAGS_PATTERN = "{[^}]-}"
local SUBTITLE_SYMBOLS = { "🔊", "➨", "➡", "➔", "➜", "➝", "➞" }
local BRACKET_PATTERNS = {
	"（[^）]-）", -- Full-width
	"%([^%)]-%)", -- ASCII
	"%[[^%]]-%]", -- Square brackets
	"【[^】]-】", -- Lenticular brackets
}
local TITLE_CLEAN_PATTERNS = {
	"[%.%s_]+[Ss]%d+[Ee]%d+", -- S01E01
	"[%.%s_]+[Ee]%d+", -- E01
	"[%.%d]+$", -- Trailing numbers/dots
	"%.%w+$", -- Extensions
}

-- Normalizes whitespace and optionally preserves newlines
function StringOps.clean_text(text, preserve_newlines)
	if not text or text == "" then
		return ""
	end

	local cleaned = text

	if preserve_newlines then
		cleaned = cleaned:gsub("\r\n", "\n")
		cleaned = cleaned:gsub("\r", "\n")
		cleaned = cleaned:gsub("[\1-\8\11-\12\14-\31]", "")
	else
		cleaned = cleaned:gsub(CONTROL_CHARS_PATTERN, "")
		cleaned = cleaned:gsub(WHITESPACE_PATTERN, " ")
	end

	cleaned = cleaned:gsub("^%s+", "")
	cleaned = cleaned:gsub("%s+$", "")

	return cleaned
end

-- Strips ASS tags and symbols from subtitle text
function StringOps.clean_subtitle(text, preserve_newlines)
	if not text or text == "" then
		return ""
	end

	local cleaned = text:gsub(SUBTITLE_TAGS_PATTERN, "")

	-- Strip symbols individually to avoid UTF-8 bracketed set issues
	for _, symbol in ipairs(SUBTITLE_SYMBOLS) do
		cleaned = cleaned:gsub(symbol, "")
	end

	-- Strip brackets individually
	for _, pattern in ipairs(BRACKET_PATTERNS) do
		cleaned = cleaned:gsub(pattern, "")
	end

	cleaned = StringOps.clean_text(cleaned, preserve_newlines)

	return cleaned
end

-- Formats duration to HH:MM:SS[:MS]
function StringOps.format_duration(seconds, show_ms)
	if not seconds or seconds < 0 then
		return "00:00:00"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	local ms = math.floor((seconds % 1) * 1000)

	if show_ms then
		return string.format("%02d:%02d:%02d:%03d", hours, minutes, secs, ms)
	else
		return string.format("%02d:%02d:%02d", hours, minutes, secs)
	end
end

-- Convert seconds to MPV-compatible timestamp (HH:MM:SS.mmm)
function StringOps.to_timestamp(seconds)
	if not seconds or seconds < 0 then
		return "00:00:00.000"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	local ms = math.floor((seconds % 1) * 1000)

	return string.format("%02d:%02d:%02d.%03d", hours, minutes, secs, ms)
end

-- Remove invalid filesystem characters from name
function StringOps.sanitize_filename(filename)
	if not filename or filename == "" then
		return "untitled"
	end

	local sanitized = filename:gsub('[<>:"/\\|?*]', "_")
	return StringOps.trim(sanitized)
end

-- Extract and clean media title from metadata or path
function StringOps.clean_title(title, path)
	local s = title
	if not s or s == "" then
		s = path or "Unknown"
	end

	-- Strip path and only keep filename
	s = s:gsub("^.*[/\\]", "")

	-- Replace underscores with spaces
	s = s:gsub("_", " ")

	-- Strip extension if it looks like a filename
	if s:match("%.%w+$") then
		s = s:gsub("%.%w+$", "")
	end

	-- Strip brackets
	for _, pattern in ipairs(BRACKET_PATTERNS) do
		s = s:gsub(pattern, "")
	end

	-- Strip season/episode tags
	for _, pattern in ipairs(TITLE_CLEAN_PATTERNS) do
		s = s:gsub(pattern, "")
	end

	return StringOps.trim(StringOps.normalize_spacing(s))
end

-- Trim leading and trailing whitespace
function StringOps.trim(text)
	if not text then
		return ""
	end
	return text:gsub("^[ \t\n\r]+", ""):gsub("[ \t\n\r]+$", "")
end

-- Collapse multiple spaces into single space
function StringOps.normalize_spacing(text)
	if not text then
		return ""
	end
	return text:gsub("[ \t\n\r]+", " ")
end

-- Detect Japanese/CJK characters (Hiragana, Katakana, Kanji)
function StringOps.has_japanese(text)
	if not text or text == "" then
		return false
	end

	-- UTF-8 ranges for Japanese/CJK
	-- Hiragana: [0x3040, 0x309F]
	-- Katakana: [0x30A0, 0x30FF]
	-- Kanji (CJK Unified Ideographs): [0x4E00, 0x9FAF]
	-- Half-width Katakana: [0xFF66, 0xFF9F]

	-- Check for common Japanese UTF-8 byte sequences
	-- E3 81-83: Hiragana/Katakana
	-- E4-E9: Kanji
	local found = text:find("[\227][\128-\131]") or text:find("[\228-\233]") or text:find("[\239][\189-\190]")

	return found ~= nil
end

return StringOps
