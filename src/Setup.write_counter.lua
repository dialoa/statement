--- Setup:write_counter: format a counter as string
--@param level number, counter level
--@return string formatted counter
function Setup:write_counter(level)

	-- counter_format: function to be used in recursion
	-- The recursion list tracks the levels encountered in recursion
	-- to ensure the function doesn't get into an infinite loop.
	local function counter_format(lvl, recursion)
		local recursion = recursion or pandoc.List:new()
		local result = ''

		if not self.counters[lvl] then
			message('WARNING', 'No counter for lvl '..tostring(lvl)..'.')
			result = '??'
		else
			result = self.counters[lvl].format or '%s'
			-- remember that we're currently processing this lvl
			recursion:insert(lvl)
			-- replace %s by the value of this counter
			local self_count = self.counters[lvl].count or 0
			result = result:gsub('%%s', tostring(self_count))
			-- replace %p by the formatted previous lvl counter
			-- unless we're already processing that lvl in recursion
			if lvl > 1 and not recursion:find(lvl-1) then
				result = result:gsub('%%p',counter_format(lvl-1, recursion))
			end
			-- replace %1, %2, ... by the value of the corresponding counter
			-- unless we're already processing them in recursion
			for i = 1, 6 do
				if result:match('%%'..tostring(i)) and not recursion:find(i) then
					result = result:gsub('%%'..tostring(i), 
																counter_format(i, recursion))
				end
			end
		end

		return result

	end

	return counter_format(level)

end