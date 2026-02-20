--[[ Collection utilities and table operations                ]]
--[[ Table manipulation, unpacking, and validation utilities. ]]

local Collections = {}

-- Unpacks array into individual return values
function Collections.unpack(arr)
	if not arr then
		return
	end
	return unpack(arr)
end

-- Creates deep copy of table
function Collections.duplicate(original)
	if type(original) ~= "table" then
		return original
	end

	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = Collections.duplicate(value)
		else
			copy[key] = value
		end
	end

	return copy
end

-- Checks if value is void (nil, empty string, or empty table)
function Collections.is_void(value)
	if value == nil then
		return true
	end

	if type(value) == "string" and value == "" then
		return true
	end

	if type(value) == "table" then
		return next(value) == nil
	end

	return false
end

-- Concatenates multiple arrays into a single array
function Collections.concat(...)
	local result = {}
	for _, arr in ipairs({ ... }) do
		if arr then
			for _, value in ipairs(arr) do
				table.insert(result, value)
			end
		end
	end
	return result
end

return Collections
