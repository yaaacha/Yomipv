--[[ Async job counter                                              ]]
--[[ Parallel async operation coordination and completion triggers. ]]

local Counter = {}

-- Creates new counter instance
function Counter.new(initial_count)
	local obj = {
		count = initial_count or 0,
		on_finish_callback = nil,
		finished = false,
	}
	setmetatable(obj, Counter)
	Counter.__index = Counter
	return obj
end

-- Set completion callback
function Counter:on_finish(callback)
	self.on_finish_callback = callback
	return self
end

-- Decrease counter and trigger callback if zero
function Counter:decrease()
	if self.finished then
		return
	end

	self.count = self.count - 1

	if self.count <= 0 and not self.finished then
		self.finished = true
		if self.on_finish_callback then
			self.on_finish_callback()
		end
	end
end

-- Increase counter
function Counter:increase()
	if self.finished then
		return
	end
	self.count = self.count + 1
end

-- Get current count value
function Counter:get_count()
	return self.count
end

-- Check if finished status
function Counter:is_finished()
	return self.finished
end

-- Reset counter to new value
function Counter:reset(new_count)
	self.count = new_count or 0
	self.finished = false
end

return Counter
