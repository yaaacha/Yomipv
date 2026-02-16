--[[ Media processing helpers                                      ]]
--[[ Binary resolution, timestamp conversion, and quality mapping. ]]

local mp = require("mp")
local utils = require("mp.utils")

local msg = require("mp.msg")
local StringOps = require("lib.string_ops")

local MediaUtils = {}

-- Resolve path to binary executable (local or system)
function MediaUtils.resolve_binary(binary_name)
	local script_dir = mp.get_script_directory()
	msg.info("Resolving binary '" .. binary_name .. "' from script dir: " .. tostring(script_dir))

	if script_dir then
		-- Check sibling directory (e.g. mpv/scripts/yomipv -> mpv/mpv.exe)
		local portable_path = utils.join_path(script_dir, "..\\..\\" .. binary_name .. ".exe")
		msg.info("Checking portable path: " .. portable_path)
		local file = io.open(portable_path, "r")
		if file then
			file:close()
			msg.info("Found portable binary: " .. portable_path)
			return portable_path
		end

		-- Check same directory (e.g. mpv/mpv.exe)
		local portable_path_2 = utils.join_path(script_dir, "..\\" .. binary_name .. ".exe")
		msg.info("Checking portable path 2: " .. portable_path_2)
		local file_2 = io.open(portable_path_2, "r")
		if file_2 then
			file_2:close()
			msg.info("Found portable binary 2: " .. portable_path_2)
			return portable_path_2
		end
	end

	msg.info("Falling back to system binary: " .. binary_name)
	return binary_name
end

-- Convert seconds to timestamp string (HH:MM:SS.mmm)
function MediaUtils.to_timestamp_str(seconds)
	return StringOps.to_timestamp(seconds)
end

-- Map quality (0-100) to AVIF CRF (0-63)
function MediaUtils.map_avif_crf(quality)
	if not quality or quality < 0 then
		return 32
	end
	if quality > 100 then
		quality = 100
	end

	return math.floor(63 - (quality / 100) * 63)
end

-- Map quality (0-100) to JPEG qscale (2-31)
function MediaUtils.map_jpeg_qscale(quality)
	if not quality or quality < 0 then
		return 15
	end
	if quality > 100 then
		quality = 100
	end

	return math.floor(31 - (quality / 100) * 29)
end

-- Generate unique filename with timestamp
function MediaUtils.generate_filename(prefix, extension, show_ms)
	local timestamp = os.time()
	local ms = show_ms and string.format("_%03d", math.floor((os.clock() % 1) * 1000)) or ""

	return string.format("%s_%d%s.%s", prefix, timestamp, ms, extension)
end

-- Sanitize path component for filesystem safety
function MediaUtils.sanitize_path(component)
	return StringOps.sanitize_filename(component)
end

-- Detect if path is a remote URL
function MediaUtils.is_remote_path(path)
	if not path or path == "" then
		return false
	end
	-- Match common protocols: http, https, ytdl, edl, etc.
	return path:find("^%w+://") ~= nil
end

return MediaUtils
