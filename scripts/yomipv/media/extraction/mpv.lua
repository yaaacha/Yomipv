--[[ Media encoding engine (MPV)                                 ]]
--[[ Generates command-line arguments for MPV encoding pipeline. ]]

local mp = require("mp")
local msg = require("mp.msg")
local Collections = require("lib.collections")
local MediaUtils = require("media.helpers")

local MpvEncoder = {}
MpvEncoder.exec = MediaUtils.resolve_binary("mpv")

local function build_base_command(source, ...)
	local args = {
		MpvEncoder.exec,
		"--no-config",
		"--loop-file=no",
		"--keep-open=no",
		"--no-ocopy-metadata",
		"--hr-seek=yes",
	}

	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		if arg ~= nil then
			table.insert(args, arg)
		end
	end

	table.insert(args, source)
	return args
end

-- Picture Extraction
function MpvEncoder.generate_picture_args(config, source, output, time, duration)
	local codec_flags
	local timeline_flags = {
		"--start=" .. MediaUtils.to_timestamp_str(time),
	}

	local format, quality, width, fps
	if config.picture_animated then
		format = config.animation_format or "webp"
		quality = config.animation_quality or 50
		width = config.animation_width or 1080
		fps = config.animation_fps or 8
		table.insert(timeline_flags, "--length=" .. tostring(duration or 2.0))
	else
		format = config.picture_static_format or "jpg"
		quality = config.picture_static_quality or 85
		width = config.picture_static_width or 0
		table.insert(timeline_flags, "--frames=1")
	end

	if format == "avif" then
		codec_flags = {
			"--ovc=libaom-av1",
			"--ovcopts-add=cpu-used=" .. (config.picture_avif_cpu_used or 4),
			string.format("--ovcopts-add=crf=%d", MediaUtils.map_avif_crf(quality)),
		}
		if config.picture_animated then
			table.insert(codec_flags, "--ofopts-add=loop=0")
		else
			table.insert(codec_flags, "--ovcopts-add=still-picture=1")
		end
	elseif format == "webp" then
		codec_flags = {
			"--ovc=libwebp",
			"--ovcopts-add=compression_level=" .. (config.picture_webp_compression or 6),
			"--ovcopts-add=sharp_yuv=1",
			string.format("--ovcopts-add=quality=%d", quality),
		}
		if config.picture_animated then
			table.insert(codec_flags, "--ovcopts-add=loop=0")
			table.insert(codec_flags, "--ofopts-add=loop=0")
			table.insert(codec_flags, "--ovcopts-add=lossless=" .. (config.picture_webp_lossless and 1 or 0))
		else
			table.insert(codec_flags, "--ovcopts-add=lossless=" .. (config.picture_webp_lossless and 1 or 0))
		end
	else
		-- Default to MJPEG
		codec_flags = {
			"--ovc=mjpeg",
			string.format("--ovcopts=global_quality=%d*QP2LAMBDA", MediaUtils.map_jpeg_qscale(quality)),
			"--ovcopts-add=flags=+qscale",
			"--ovcopts-add=strict=unofficial",
			"--ovcopts-add=update=1",
		}
	end

	-- Hardware-accelerated scaling
	local filters = {}
	if width > 0 then
		table.insert(filters, string.format("scale=%d:-1", width))
	end
	if config.picture_animated and fps and fps > 0 then
		table.insert(filters, string.format("fps=%d", fps))
	end

	local vf_flag = #filters > 0 and "--vf-add=" .. table.concat(filters, ",") or nil

	local extra_flags = Collections.concat({ "--audio=no", "--no-sub", vf_flag }, timeline_flags, codec_flags)
	local final_args = build_base_command(source, Collections.unpack(extra_flags))

	table.insert(final_args, "-o")
	table.insert(final_args, output)

	msg.info(
		"Generated picture args (formatted: "
			.. MediaUtils.to_timestamp_str(time)
			.. "): "
			.. require("mp.utils").to_string(final_args)
	)
	return final_args
end

-- Audio Extraction
function MpvEncoder.generate_audio_args(config, source, output, start_time, end_time, volume)
	local audio_flags
	if config.audio_format == "opus" then
		audio_flags = {
			"--oac=libopus",
			"--oacopts-add=b=" .. (config.audio_bitrate or "64k"),
			"--oacopts-add=application=voip",
		}
	else
		audio_flags = {
			"--oac=libmp3lame",
			"--oacopts-add=b=" .. (config.audio_bitrate or "128k"),
			"--oacopts-add=compression_level=0",
		}
	end

	local aid = mp.get_property("aid", "auto")

	local filter_flags = {}
	if volume and volume ~= 100 then
		table.insert(filter_flags, "--af-add=volume=volume=" .. tostring(volume / 100.0))
	end

	local combined_flags = Collections.concat({
		"--video=no",
		"--aid=" .. aid,
		"--audio-channels=mono",
		"--start=" .. MediaUtils.to_timestamp_str(start_time),
		"--end=" .. MediaUtils.to_timestamp_str(end_time),
	}, audio_flags, filter_flags)

	local base_args = build_base_command(source, Collections.unpack(combined_flags))

	table.insert(base_args, "-o")
	table.insert(base_args, output)

	return base_args
end

return MpvEncoder
