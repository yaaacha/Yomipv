--[[ Audio extraction job creator ]]
--[[ Async jobs for extracting audio clips from video. ]]

local mp = require("mp")
local msg = require("mp.msg")
local utils = require("mp.utils")
local MpvEncoder = require("media.extraction.mpv")
local FFmpegEncoder = require("media.extraction.ffmpeg")
local MediaUtils = require("media.helpers")

local Audio = {
	output_dir = nil,
	config = nil,
}

function Audio.set_output_dir(dir)
	Audio.output_dir = dir
end

function Audio.init(config)
	Audio.config = config
end

function Audio.create_job(subtitle)
	if not Audio.config or not Audio.output_dir then
		msg.error("Audio module not initialized")
		return nil
	end

	local start_time = subtitle.start or 0
	local end_time = subtitle["end"] or 0

	local source = mp.get_property("path", "")
	if not source or source == "" then
		msg.error("No media file loaded")
		return nil
	end
	
	-- Ambil metadata
	local anime_title = mp.get_property("media-title") or "Unknown Anime"
	local ep_num = mp.get_property("episode") or mp.get_property_number("playlist-pos-1") or "N/A"
	local ep_title = mp.get_property("title") or ""
	local timestamp = MediaUtils.to_timestamp_str(mp.get_property_number("time-pos") or 0)

	local filename = MediaUtils.generate_filename(
		"yomipv_audio", 
		Audio.config.audio_format or "mp3", 
		Audio.config.filename_show_ms
	)
	local target_file = utils.join_path(Audio.output_dir, filename)
	
	-- Rakit string MiscInfo
	local misc_info = string.format("%s | Ep: %s | %s [%s]", anime_title, ep_num, ep_title, timestamp)

	local job = {
		result_file = filename,
		full_path = target_file,
		misc_info = misc_info, 
		on_finish_callback = nil,
	}

	function job:on_finish(callback)
		self.on_finish_callback = callback
		return self
	end

	function job:run()
		msg.info("Starting audio extraction: " .. target_file)

		local volume = 100
		if Audio.config.audio_match_volume then
			volume = mp.get_property_native("volume") or 100
		end

		local args
		if Audio.config.audio_use_ffmpeg then
			msg.info("Using FFmpeg as per config")
			args = FFmpegEncoder.generate_audio_args(Audio.config, source, target_file, start_time, end_time, volume)
		else
			msg.info("Using MPV as per config")
			args = MpvEncoder.generate_audio_args(Audio.config, source, target_file, start_time, end_time, volume)
		end

		mp.command_native_async({
			name = "subprocess",
			playback_only = false,
			capture_stdout = true,
			args = args,
		}, function(success, result, error)
			if success and result.status == 0 then
				msg.info("Audio extracted successfully: " .. filename)
				if self.on_finish_callback then self.on_finish_callback(true) end
			else
				msg.error("Audio extraction failed. Status: " .. tostring(result and result.status))
				if self.on_finish_callback then self.on_finish_callback(false) end
			end
		end)
	end

	return job
end

return Audio