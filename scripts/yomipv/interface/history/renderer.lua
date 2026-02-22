--[[ History Panel Renderer                                     ]]
--[[ Visual representation of history panel using OSD overlays. ]]

local StringOps = require("lib.string_ops")
local Monitor = require("capture.monitor")
local Display = require("lib.display")

local Renderer = {}

-- Clean and escape text for OSD display
local function escape_for_osd(str)
	if not str or str == "" then
		return ""
	end
	str = StringOps.trim(str)
	str = str:gsub("[\n\r]+", [[\N]]) -- Preserve OSD newlines
	str = StringOps.normalize_spacing(str)
	return str
end

-- Wrap text to maximum character length
local function wrap_text(text, max)
	if not text or text == "" then
		return ""
	end
	local lines = {}
	for line in text:gmatch("([^\n]+)") do
		local current = ""
		local current_len = 0
		-- Wrap by whitespace
		if line:find(" ") then
			for word in line:gmatch("%S+") do
				if current_len + #word + 1 > max then
					table.insert(lines, current)
					current = word
					current_len = #word
				else
					current = (current == "") and word or (current .. " " .. word)
					current_len = current_len + #word + (current == word and 0 or 1)
				end
			end
			table.insert(lines, current)
		else
			-- Wrap by character
			-- Double width for non-ASCII
			local i = 1
			while i <= #line do
				local c = string.byte(line, i)
				local next_i
				local char_weight = 1
				if c < 128 then
					next_i = i + 1
				elseif c >= 194 and c <= 223 then
					next_i = i + 2
					char_weight = 2
				elseif c >= 224 and c <= 239 then
					next_i = i + 3
					char_weight = 2
				elseif c >= 240 and c <= 244 then
					next_i = i + 4
					char_weight = 2
				else
					next_i = i + 1
				end

				local char = line:sub(i, next_i - 1)
				if current_len + char_weight > max then
					table.insert(lines, current)
					current = char
					current_len = char_weight
				else
					current = current .. char
					current_len = current_len + char_weight
				end
				i = next_i
			end
			if current ~= "" then
				table.insert(lines, current)
			end
		end
	end
	return table.concat(lines, "\n")
end

-- Draw history/selection panel UI
function Renderer.draw(state, osd, scale, ow, oh)
	local entries
	local header_text

	if Monitor.is_appending() then
		header_text = "SELECTED"
		entries = Monitor.recorded_subs()
	else
		header_text = "HISTORY"
		entries = Monitor.get_history()
	end

	state.hit_boxes = {}
	if #entries == 0 then
		return
	end

	local width = (state.config.history_width or 160) * scale
	local max_height = (state.config.history_max_height or 400) * scale
	local x1 = ow - width - 20 * scale
	local y1 = 50 * scale
	local x2 = x1 + width

	local accent = Display.fix_color(state.config.history_accent_color or "3db54a", "3db54a")
	local bg = Display.fix_color(state.config.history_background_color or "111111", "111111")
	local radius = 8 * scale

	local header_h = 32 * scale
	local padding = 10 * scale

	local entries_to_draw = {}

	local CHARS_PER_LINE = 26
	local SEC_CHARS_PER_LINE = 36

	-- Measure entry heights
	local function measure_entry(entry)
		local h = 10 * scale
		local wrapped_pri = wrap_text(entry.primary_sid, CHARS_PER_LINE)
		for _ in wrapped_pri:gmatch("([^\n]+)") do
			h = h + 20 * scale
		end
		if state.config.history_show_secondary ~= false and entry.secondary_sid ~= "" then
			local wrapped_sec = wrap_text(entry.secondary_sid, SEC_CHARS_PER_LINE)
			local seen = {}
			for line in wrapped_sec:gmatch("([^\n]+)") do
				local cleaned = StringOps.trim(line) -- Deduplicate secondary lines
				if not seen[cleaned] then
					h = h + 16 * scale
					seen[cleaned] = true
				end
			end
		end
		return h
	end

	-- Cache heights
	for i = 1, #entries do
		entries[i].item_h = measure_entry(entries[i])
	end

	-- Calculate scroll bounds
	local h_limit = math.floor(max_height - header_h - padding)
	state.max_scroll_top_index = 1
	state.scroll_bottom_offset = 0

	local total_h = 0
	for i = 1, #entries do
		total_h = total_h + entries[i].item_h
	end

	if total_h > h_limit then
		local current_total_h = 0
		for i = #entries, 1, -1 do
			local next_h = current_total_h + entries[i].item_h
			if next_h <= h_limit then
				current_total_h = next_h
				state.max_scroll_top_index = i
			else
				-- Push up if item exceeds limit
				state.max_scroll_top_index = i
				state.scroll_bottom_offset = h_limit - next_h
				break
			end
		end
	end

	-- Update auto-scroll
	if state.auto_scroll then
		state.scroll_top_index = state.max_scroll_top_index
		state.scroll_fine_offset = state.scroll_bottom_offset
	else
		state.scroll_top_index = math.max(1, math.min(state.max_scroll_top_index, state.scroll_top_index or 1))
		state.scroll_fine_offset = (state.scroll_top_index == state.max_scroll_top_index) and state.scroll_bottom_offset
			or 0
	end

	-- Layout content
	local current_y = y1 + header_h + padding + (state.scroll_fine_offset or 0)
	for i = state.scroll_top_index, #entries do
		local entry = entries[i]
		entry.wrapped_pri = wrap_text(entry.primary_sid, CHARS_PER_LINE)
		entry.wrapped_sec = wrap_text(entry.secondary_sid, SEC_CHARS_PER_LINE)
		entry.index = i

		table.insert(entries_to_draw, entry)
		-- Stop when content exceeds boundary
		if current_y + entry.item_h > y1 + max_height + entry.item_h then
			break
		end
		current_y = current_y + entry.item_h
	end

	-- Clamp box height
	local total_h_val = 0
	for i = 1, #entries do
		total_h_val = total_h_val + entries[i].item_h
	end
	local box_h = math.min(max_height, total_h_val + header_h + padding)
	if state.scroll_top_index > 1 or total_h_val > h_limit then
		box_h = max_height
	end
	local y2 = y1 + box_h

	-- Convert opacity to hex
	local opacity = state.config.history_background_opacity or "22"
	if type(opacity) == "string" and opacity:match("%%$") then
		local num = tonumber(opacity:sub(1, -2))
		if num then
			opacity = string.format("%02X", math.floor(num * 255 / 100))
		end
	end

	-- Background Box
	osd:rect(x1, y1, x2, y2, bg, opacity, radius)

	-- Draw content area
	local draw_y = y1 + header_h + padding + (state.scroll_fine_offset or 0)
	local content_x = math.floor(x1 + 10 * scale)
	local clip_y1 = math.floor(y1 + header_h)
	local clip_y2 = math.floor(y2)
	local clip_x1 = math.floor(x1)
	local clip_x2 = math.floor(x2)

	-- Clip to content region
	osd:new_event():clip(clip_x1, clip_y1, clip_x2, clip_y2)

	for _, entry in ipairs(entries_to_draw) do
		local entry_top = draw_y
		local entry_bottom = entry_top + entry.item_h - 10 * scale

		if entry_bottom > y1 + header_h and entry_top < y2 then
			if state.hovered_id == entry.index then
				-- Adjust padding for scrollbar
				local has_scrollbar = #entries > #entries_to_draw
					or (state.scroll_fine_offset and state.scroll_fine_offset < 0)
				local h_x2 = x2 - (has_scrollbar and 10 * scale or 4 * scale)
				-- Draw hover highlight
				osd:rect(
					math.floor(x1 + 4 * scale),
					math.floor(entry_top - 4 * scale),
					math.floor(h_x2),
					math.floor(entry_bottom + 4 * scale),
					accent,
					"66",
					4 * scale
				):clip(clip_x1, clip_y1, clip_x2, clip_y2)
			end

			local text_y = draw_y
			for line in entry.wrapped_pri:gmatch("([^\n]+)") do
				osd:new_event()
					:clip(clip_x1, clip_y1, clip_x2, clip_y2)
					:pos(content_x, math.floor(text_y))
					:size((state.config.history_font_size or 15) * scale)
					:color("ffffff")
					:text(escape_for_osd(line))
				text_y = text_y + ((state.config.history_font_size or 15) + 5) * scale
			end

			if state.config.history_show_secondary ~= false and entry.wrapped_sec ~= "" then
				local seen = {}
				for line in entry.wrapped_sec:gmatch("([^\n]+)") do
					if not seen[line] then
						osd:new_event()
							:clip(clip_x1, clip_y1, clip_x2, clip_y2)
							:pos(content_x, math.floor(text_y))
							:size((state.config.history_secondary_font_size or 12) * scale)
							:color(state.hovered_id == entry.index and "ffffff" or "AAAAAA")
							:text(escape_for_osd(line))
						text_y = text_y + ((state.config.history_secondary_font_size or 12) + 4) * scale
						seen[line] = true
					end
				end
			end

			table.insert(state.hit_boxes, {
				id = entry.index,
				x1 = x1,
				y1 = math.max(y1 + header_h, entry_top),
				x2 = x2 - 10 * scale,
				y2 = math.min(y2, entry_bottom),
				entry = entry,
			})
		end
		draw_y = draw_y + entry.item_h
	end

	-- Render fade mask
	-- Avoid artifacts with non-overlapping steps
	local fade_h_px = math.floor(48 * scale)
	local fade_steps = math.min(fade_h_px, 64)

	if state.scroll_top_index > 1 then
		for i = 0, fade_steps - 1 do
			local s_y1 = math.floor(y1 + header_h + (i * fade_h_px / fade_steps))
			local s_y2 = math.floor(y1 + header_h + ((i + 1) * fade_h_px / fade_steps))
			if s_y1 < s_y2 then
				local alpha = string.format("%02X", math.floor(34 + (255 - 34) * (i / (fade_steps - 1))))
				osd:new_event():clip(clip_x1, clip_y1, clip_x2, clip_y2):rect(x1, s_y1, x2, s_y2, bg, alpha, 0)
			end
		end
	end

	if entries_to_draw[#entries_to_draw] and entries_to_draw[#entries_to_draw].index < #entries then
		for i = 0, fade_steps - 1 do
			local s_y1 = math.floor((y2 - fade_h_px) + (i * fade_h_px / fade_steps))
			local s_y2 = math.floor((y2 - fade_h_px) + ((i + 1) * fade_h_px / fade_steps))
			if s_y1 < s_y2 then
				local alpha = string.format("%02X", math.floor(255 - (255 - 34) * (i / (fade_steps - 1))))
				osd:new_event():clip(clip_x1, clip_y1, clip_x2, clip_y2):rect(x1, s_y1, x2, s_y2, bg, alpha, 0)
			end
		end
	end

	-- Draw header
	osd:new_event():rect(x1, y1, x2, y1 + header_h, accent, "00", radius, { tl = true, tr = true })
	osd:new_event()
		:pos(x1 + 10 * scale, y1 + 16 * scale, true, 4)
		:size((state.config.history_font_size or 15) + 3 * scale)
		:color("ffffff")
		:bold(header_text)

	-- Draw GIF toggle button
	local is_animated = state.config.picture_animated
	local anim_text = is_animated and "GIF: ON" or "GIF: OFF"
	local anim_color = state.hovered_id == "toggle_anim" and "ffffff" or (is_animated and "ffffff" or "CCCCCC")

	osd
		:new_event()
		:pos(x1 + (width / 2), y1 + 16 * scale, true, 5) -- 5 is top-center alignment
		:size((state.config.history_font_size or 15) + 3 * scale)
		:color(anim_color)
		:bold(anim_text)

	table.insert(state.hit_boxes, {
		id = "toggle_anim",
		x1 = x1 + (width / 2) - 40 * scale,
		y1 = y1,
		x2 = x1 + (width / 2) + 40 * scale,
		y2 = y1 + header_h,
	})

	-- Draw Clear button
	osd:new_event()
		:pos(x2 - 10 * scale, y1 + 16 * scale, true, 6)
		:size((state.config.history_font_size or 15) + 3 * scale)
		:color(state.hovered_id == "clear" and "ffffff" or "CCCCCC")
		:bold("CLEAR")

	table.insert(state.hit_boxes, {
		id = "clear",
		x1 = x2 - 60 * scale,
		y1 = y1,
		x2 = x2,
		y2 = y1 + header_h,
	})

	-- Scrollbar
	if #entries > #entries_to_draw or state.scroll_top_index > 1 then
		local sb_w = 4 * scale
		local sb_x = x2 - sb_w - 2 * scale
		local track_top = y1 + header_h + padding
		local track_bottom = y2 - padding
		local c_h = track_bottom - track_top

		local thumb_h = math.max(20 * scale, c_h * (#entries_to_draw / #entries))
		local progress = 0
		if state.max_scroll_top_index and state.max_scroll_top_index > 1 then
			progress = (state.scroll_top_index - 1) / (state.max_scroll_top_index - 1)
		end
		local thumb_top = track_top + (c_h - thumb_h) * progress

		-- Draw scrollbar
		osd:new_event():rect(sb_x, track_top, sb_x + sb_w, track_bottom, "ffffff", "BB", 2)
		osd:new_event():rect(sb_x, thumb_top, sb_x + sb_w, thumb_top + thumb_h, accent, "00", 2)
	end

	osd:new_event():clip(0, 0, ow, oh)
end

return Renderer
