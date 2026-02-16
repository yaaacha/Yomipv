--[[ Platform Detection and Cross-Platform Utilities           ]]
--[[ Provides OS detection and platform-specific command paths ]]

local mp = require("mp")
local msg = require("mp.msg")

local Platform = {}

-- Detect operating system
local function detect_os()
	local os_name = mp.get_property("platform")

	if os_name then
		if os_name:find("windows") or os_name:find("win32") then
			return "windows"
		elseif os_name:find("darwin") then
			return "macos"
		else
			return "linux"
		end
	end

	-- Fallback detection via path separator
	local path_sep = package.config:sub(1, 1)
	if path_sep == "\\" then
		return "windows"
	else
		return "linux"
	end
end

Platform.OS = detect_os()
Platform.IS_WINDOWS = Platform.OS == "windows"
Platform.IS_LINUX = Platform.OS == "linux"
Platform.IS_MACOS = Platform.OS == "macos"

msg.info("Platform detected: " .. Platform.OS)

-- Get platform-specific curl command
function Platform.get_curl_cmd()
	if Platform.IS_WINDOWS then
		return "C:\\Windows\\System32\\curl.exe"
	else
		return "curl"
	end
end

-- Get platform-specific path separator
function Platform.get_path_separator()
	if Platform.IS_WINDOWS then
		return "\\"
	else
		return "/"
	end
end

-- Convert path to platform-specific format
function Platform.normalize_path(path)
	if not path then
		return nil
	end

	if Platform.IS_WINDOWS then
		-- Convert forward slashes to backslashes
		local normalized = path:gsub("/", "\\")
		-- Handle drive letter format
		normalized = normalized:gsub("^\\?([%a]:)", "%1")
		-- Remove trailing separator
		normalized = normalized:gsub("\\$", "")
		return normalized
	else
		-- Convert backslashes to forward slashes
		local normalized = path:gsub("\\", "/")
		-- Remove trailing separator
		normalized = normalized:gsub("/$", "")
		return normalized
	end
end

-- Launch Electron app with platform-specific launcher
function Platform.launch_electron_app(app_path, mpv_pid, callback)
	local normalized_path = Platform.normalize_path(app_path)

	if Platform.IS_WINDOWS then
		-- Use PowerShell launcher
		local start_ps1 = normalized_path .. "\\start_lookup.ps1"

		local cmd_args = {
			"powershell.exe",
			"-NoProfile",
			"-ExecutionPolicy",
			"Bypass",
			"-File",
			start_ps1,
			"-mpvPid",
			tostring(mpv_pid),
		}

		msg.info("Starting lookup app via PowerShell for PID: " .. tostring(mpv_pid))

		mp.command_native_async({
			name = "subprocess",
			playback_only = false,
			detach = true,
			args = cmd_args,
		}, callback)
	else
		-- Use bash launcher
		local start_sh = normalized_path .. "/start_lookup.sh"

		-- Make script executable first (best effort)
		mp.command_native_async({
			name = "subprocess",
			playback_only = false,
			args = { "chmod", "+x", start_sh },
		}, function()
			-- Launch the script
			local cmd_args = {
				"/bin/bash",
				start_sh,
				tostring(mpv_pid),
			}

			msg.info("Starting lookup app via bash for PID: " .. tostring(mpv_pid))

			mp.command_native_async({
				name = "subprocess",
				playback_only = false,
				detach = true,
				args = cmd_args,
			}, callback)
		end)
	end
end

-- Get null device path for output redirection
function Platform.get_null_device()
	if Platform.IS_WINDOWS then
		return "nul"
	else
		return "/dev/null"
	end
end

return Platform
