--[[ HTTP client using curl subprocess         ]]
--[[ Base functionality for API POST requests. ]]

local mp = require("mp")
local msg = require("mp.msg")

local Curl = {}

-- Execute POST request (compatibility alias)
function Curl.post(url, json_body, callback)
	return Curl.request(url, json_body, function(_, output, _)
		callback(output)
	end)
end

-- Execute request with detailed callback
function Curl.request(url, json_body, callback)
	-- Write to temp file to avoid Windows pipe CP1252 corruption
	local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "."
	local temp_file = string.format("%s\\yomipv_req_%d_%d.json", temp_dir, os.time(), math.random(10000, 99999))

	local f = io.open(temp_file, "wb")
	if not f then
		msg.error("Failed to write to temp file: " .. temp_file)
		return callback(false, { status = -1 }, "IO Error")
	end
	f:write(json_body)
	f:close()

	local args = {
		"curl",
		"-s",
		"-X",
		"POST",
		"-H",
		"Content-Type: application/json",
		"--data-binary",
		"@" .. temp_file,
		url,
	}

	msg.info("Executing curl request to: " .. url)

	mp.command_native_async({
		name = "subprocess",
		playback_only = false,
		capture_stdout = true,
		capture_stderr = true,
		args = args,
	}, function(success, result, error)
		-- Clean up temp file
		os.remove(temp_file)

		msg.info(
			string.format(
				"Curl finished: success=%s, status=%s, stdout_len=%d, stderr_len=%d",
				tostring(success),
				tostring(result and result.status),
				(result and result.stdout or ""):len(),
				(result and result.stderr or ""):len()
			)
		)

		if result and result.stdout and result.stdout ~= "" then
			msg.info("Curl stdout preview: " .. result.stdout:sub(1, 100))
		end

		local output = {
			status = result and result.status or -1,
			stdout = result and result.stdout or "",
			stderr = result and result.stderr or error or "",
		}

		local is_success = success and output.status == 0
		callback(is_success, output, output.stderr)
	end)
end

return Curl
