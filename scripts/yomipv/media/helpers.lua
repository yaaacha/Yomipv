--[[ Media processing and binary resolution utilities ]]

local mp = require("mp")
local utils = require("mp.utils")

local msg = require("mp.msg")
local StringOps = require("lib.string_ops")

local Platform = require("lib.platform")

local MediaUtils = {}

local binary_cache = {}

-- Resolve executable path from local script directory or system path
function MediaUtils.resolve_binary(binary_name)
	if binary_cache[binary_name] then
		return binary_cache[binary_name]
	end

	local script_dir = mp.get_script_directory()
	local ext = Platform.get_binary_extension()
	local sep = Platform.get_path_separator()

	msg.info("Resolving binary '" .. binary_name .. "' from script dir: " .. tostring(script_dir))

	if script_dir then
		local search_paths = {
			utils.join_path(script_dir, ".." .. sep .. ".." .. sep .. binary_name .. ext),
			utils.join_path(script_dir, ".." .. sep .. binary_name .. ext),
			utils.join_path(script_dir, ".." .. sep .. ".." .. sep .. "bin" .. sep .. binary_name .. ext),
		}

		for _, portable_path in ipairs(search_paths) do
			msg.info("Checking portable path: " .. portable_path)
			local file = io.open(portable_path, "r")
			if file then
				file:close()
				msg.info("Found portable binary: " .. portable_path)
				binary_cache[binary_name] = portable_path
				return portable_path
			end
		end
	end

	msg.info("Falling back to system binary: " .. binary_name)
	binary_cache[binary_name] = binary_name
	return binary_name
end

function MediaUtils.to_timestamp_str(seconds)
	return StringOps.to_timestamp(seconds)
end

-- Map 0-100 quality to 0-63 CRF value
function MediaUtils.map_avif_crf(quality)
	if not quality or quality < 0 then
		return 32
	end
	if quality > 100 then
		quality = 100
	end

	return math.floor(63 - (quality / 100) * 63)
end

-- Map 0-100 quality to 2-31 qscale value
function MediaUtils.map_jpeg_qscale(quality)
	if not quality or quality < 0 then
		return 15
	end
	if quality > 100 then
		quality = 100
	end

	return math.floor(31 - (quality / 100) * 29)
end

-- Timestamp-based unique filename generation
function MediaUtils.generate_filename(prefix, extension, show_ms)
	local timestamp = os.time()
	local ms = show_ms and string.format("_%03d", math.floor((os.clock() % 1) * 1000)) or ""

	return string.format("%s_%d%s.%s", prefix, timestamp, ms, extension)
end

function MediaUtils.sanitize_path(component)
	return StringOps.sanitize_filename(component)
end

function MediaUtils.is_remote_path(path)
	if not path or path == "" then
		return false
	end
	-- Match common protocols: http, https, ytdl, edl, etc.
	return path:find("^%w+://") ~= nil
end

return MediaUtils
