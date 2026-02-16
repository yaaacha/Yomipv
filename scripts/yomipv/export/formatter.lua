--[[ Template formatter                             ]]
--[[ Variable substitution and template processing. ]]

local Formatter = {}

-- Create new formatter instance
function Formatter.new(config)
	local obj = {
		config = config,
	}
	setmetatable(obj, Formatter)
	Formatter.__index = Formatter
	return obj
end

-- Substitute variables in template string
function Formatter.substitute(_, template, variables)
	if not template or template == "" then
		return ""
	end

	local result = template

	if variables then
		for key, value in pairs(variables) do
			local pattern = "%%{" .. key .. "}"
			result = result:gsub(pattern, tostring(value))
		end
	end

	return result
end

return Formatter
