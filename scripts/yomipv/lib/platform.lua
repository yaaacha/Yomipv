--[[ Platform detection and cross-platform command paths ]]

local mp = require("mp")
local msg = require("mp.msg")

local Platform = {}

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

function Platform.get_curl_cmd()
	return "curl"
end

function Platform.get_temp_dir()
	if Platform.IS_WINDOWS then
		return os.getenv("TEMP") or os.getenv("TMP") or "C:\\Windows\\Temp"
	else
		return os.getenv("TMPDIR") or "/tmp"
	end
end

function Platform.get_path_separator()
	if Platform.IS_WINDOWS then
		return "\\"
	elseif Platform.IS_MACOS or Platform.IS_LINUX then
		return "/"
	end
	return "/"
end

function Platform.normalize_path(path)
	if not path then
		return nil
	end

	if Platform.IS_WINDOWS then
		local normalized = path:gsub("/", "\\")
		normalized = normalized:gsub("^\\?([%a]:)", "%1")
		normalized = normalized:gsub("\\$", "")
		return normalized
	elseif Platform.IS_MACOS or Platform.IS_LINUX then
		local normalized = path:gsub("\\", "/")
		normalized = normalized:gsub("/$", "")
		return normalized
	end

	return path
end

-- Launcher implementation for Electron frontend
function Platform.launch_electron_app(app_path, mpv_pid, ipc_pipe, callback)
	local normalized_path = Platform.normalize_path(app_path)

	if Platform.IS_WINDOWS then
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
			"-ipcPipe",
			ipc_pipe or "",
		}

		msg.info("Starting lookup app via PowerShell for PID: " .. tostring(mpv_pid))

		mp.command_native_async({
			name = "subprocess",
			playback_only = false,
			detach = true,
			args = cmd_args,
		}, callback)
	else
		local start_sh = normalized_path .. "/start_lookup.sh"

		-- Make script executable first
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
				ipc_pipe or "",
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

function Platform.get_null_device()
	if Platform.IS_WINDOWS then
		return "nul"
	elseif Platform.IS_MACOS or Platform.IS_LINUX then
		return "/dev/null"
	end
	return "/dev/null"
end

function Platform.get_binary_extension()
	if Platform.IS_WINDOWS then
		return ".exe"
	else
		return ""
	end
end

return Platform
