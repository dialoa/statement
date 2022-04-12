--- Setup:create_counters create level counters based on statement kinds
--@return nil, modifies the self.counters table
--@TODO html output, read Pandoc's number-offset option
function Setup:create_counters()
	-- default counter output: %s for counter value, 
	-- %p for its parent's formatted output
	local default_format = function (level)
		return level == 1 and '%s' or '%p.%s'
	end

	-- only create counters from 1 to level required by some kind
	for kind_key,definition in pairs(self.kinds) do
		local level = tonumber(definition.counter) or 
									self:get_level_by_LaTeX_name(definition.counter)
		if level then
			if level >= 1 and level <= 6 then

				-- create counters up to level if needed
				for i = 1, level do
					if not self.counters[i] then
							self.counters[i] = {
																		count = 0,
																		reset = pandoc.List:new(),
																		format = default_format(i),
																	}
					end
				end
				self.counters[level].reset:insert(kind_key)

			else

				message('WARNING','Kind '..kind_key..' was assigned level '..tostring(level)
													..', which is outside the range 1-6 of Pandoc levels.'
													..' Counters for these statement will probably not work as desired.')

			end

		end

	end

end
