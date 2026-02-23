local mp = require("mp")
local MediaUtils = require("media.helpers")

local FFmpegEncoder = {}
FFmpegEncoder.exec = MediaUtils.resolve_binary("ffmpeg")

local function get_input_args(source, start_time)
    local args = {}
    table.insert(args, "-headers")
    table.insert(args, "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36\r\nReferer: https://hianime.to/\r\n")
    table.insert(args, "-ss")
    table.insert(args, MediaUtils.to_timestamp_str(start_time or 0))
    table.insert(args, "-i")
    table.insert(args, source)
    
    return args
end

function FFmpegEncoder.generate_picture_args(config, source, output, time, duration)
    local args = { FFmpegEncoder.exec, "-hide_banner", "-loglevel", "error", "-y" }
    
    local input_args = get_input_args(source, time)
    for _, v in ipairs(input_args) do table.insert(args, v) end

    local format, quality, width, fps
    if config.picture_animated then
        format = config.animation_format or "webp"
        quality = config.animation_quality or 50
        width = config.animation_width or 720
        fps = config.animation_fps or 8
        table.insert(args, "-t")
        table.insert(args, tostring(duration or 2.0))
    else
        format = config.picture_static_format or "jpg"
        quality = config.picture_static_quality or 85
        width = config.picture_static_width or 0
        table.insert(args, "-frames:v")
        table.insert(args, "1")
    end

    -- Filter logic
    local filters = {}
    if width > 0 then table.insert(filters, string.format("scale=%d:-1", width)) end
    if config.picture_animated and fps and fps > 0 then table.insert(filters, string.format("fps=%d", fps)) end
    if #filters > 0 then
        table.insert(args, "-vf")
        table.insert(args, table.concat(filters, ","))
    end

    -- Encoder settings
    if format == "avif" then
        table.insert(args, "-c:v")
        table.insert(args, "libaom-av1")
        table.insert(args, "-crf")
        table.insert(args, tostring(MediaUtils.map_avif_crf(quality)))
    elseif format == "webp" then
        table.insert(args, "-c:v")
        table.insert(args, "libwebp")
        table.insert(args, "-quality")
        table.insert(args, tostring(quality))
    else
        table.insert(args, "-c:v")
        table.insert(args, "mjpeg")
        table.insert(args, "-q:v")
        table.insert(args, tostring(math.floor(31 - (quality / 100) * 30 + 1)))
    end

    table.insert(args, "-an")
    table.insert(args, output)
    return args
end

function FFmpegEncoder.generate_audio_args(config, source, output, start_time, end_time, volume)
    local args = { FFmpegEncoder.exec, "-hide_banner", "-loglevel", "error", "-y" }

    local input_args = get_input_args(source, start_time)
    for _, v in ipairs(input_args) do table.insert(args, v) end

    if end_time and start_time then
        table.insert(args, "-t")
        table.insert(args, tostring(end_time - start_time))
    end

    local track_list = mp.get_property_native("track-list")
    local selected_track_index = 0
    local audio_counter = 0
    if track_list then
        for _, track in ipairs(track_list) do
            if track.type == "audio" then
                if track.selected then selected_track_index = audio_counter break end
                audio_counter = audio_counter + 1
            end
        end
    end

    table.insert(args, "-map")
    table.insert(args, "0:a:" .. tostring(selected_track_index))

    if volume and volume ~= 100 then
        table.insert(args, "-af")
        table.insert(args, string.format("volume=%.4f", volume / 100.0))
    end

    -- MP3/Opus settings
    if config.audio_format == "opus" then
        table.insert(args, "-c:a")
        table.insert(args, "libopus")
        table.insert(args, "-b:a")
        table.insert(args, config.audio_bitrate or "64k")
    else
        table.insert(args, "-c:a")
        table.insert(args, "libmp3lame")
        table.insert(args, "-b:a")
        table.insert(args, config.audio_bitrate or "128k")
    end

    table.insert(args, "-ac")
    table.insert(args, "1")
    table.insert(args, "-vn")
    table.insert(args, output)

    return args
end

return FFmpegEncoder