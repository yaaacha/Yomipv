--[[ Subtitle Filter                           ]]
--[[ JSRE-based subtitle display sanitization. ]]

local mp = require("mp")

local SubtitleFilter = {}

-- Apply JSRE sanitization filters
function SubtitleFilter.apply_filters()
	if not SubtitleFilter._config or not SubtitleFilter._config.subtitle_filter_enabled then
		mp.set_property("sub-filter-jsre", "")
		return
	end

	-- Force native renderer override to ensure filters apply
	mp.set_property("sub-ass-override", "force")

	-- Match signs, positioning tags, and drawing commands (p1-p9)
	local signs = [[.*\\(pos|move|p[0-9]|clip|an[0-9])\(.*]]

	-- Filter bracketed text, icons, arrows, and environmental noise
	local noise = [[^(\{.*\})?[(\[（【].*[)\]）】]\s*$]]
	local speaker = [[^(\{.*\})?🔊\s*$]]
	local arrows = [[^(\{.*\})?[➨➡➔➜➝➞]\s*$]]

	-- Update combined sub-filter-jsre property
	mp.set_property("sub-filter-jsre", table.concat({ signs, noise, speaker, arrows }, "|"))
end

-- Initialize subtitle filter module
function SubtitleFilter.init(config)
	SubtitleFilter._config = config

	mp.register_event("file-loaded", function()
		SubtitleFilter.apply_filters()
	end)

	-- Manual filter refresh binding
	mp.add_key_binding("b", "refresh_subs", function()
		SubtitleFilter.apply_filters()
		mp.osd_message("Native Filter Refreshed")
	end)

	SubtitleFilter.apply_filters()
end

return SubtitleFilter
