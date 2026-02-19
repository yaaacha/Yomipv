--[[ Audio extraction job creator                      ]]
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

	local filename =
		MediaUtils.generate_filename("yomipv_audio", Audio.config.audio_format or "mp3", Audio.config.filename_show_ms)

	local target_file = utils.join_path(Audio.output_dir, filename)

	local job = {
		result_file = filename,
		full_path = target_file,
		on_finish_callback = nil,
	}

	function job:on_finish(callback)
		self.on_finish_callback = callback
		return self
	end

	function job:run()
		msg.info("Starting audio extraction: " .. target_file)

		local args
		-- Use FFmpeg for local files if configured; fallback to MPV encoder for remotes
		if Audio.config.audio_use_ffmpeg and not MediaUtils.is_remote_path(source) then
			args = FFmpegEncoder.generate_audio_args(Audio.config, source, target_file, start_time, end_time)
		else
			args = MpvEncoder.generate_audio_args(Audio.config, source, target_file, start_time, end_time)
		end

		mp.command_native_async({
			name = "subprocess",
			playback_only = false,
			args = args,
		}, function(success, result, error)
			if success and result.status == 0 then
				msg.info("Audio extracted: " .. filename)
				if self.on_finish_callback then
					self.on_finish_callback(true)
				end
			else
				msg.error("Audio extraction failed: " .. tostring(error or result.status))
				if self.on_finish_callback then
					self.on_finish_callback(false)
				end
			end
		end)
	end

	return job
end

return Audio
