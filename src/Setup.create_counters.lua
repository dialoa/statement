--- Setup:create_counters create level counters based on statement kinds
-- Creates
--	self.counters
--@param format (optional) desired format if other than FORMAT
--@return nil, creates the self.counters table
function Setup:create_counters(format)
	local format = format or FORMAT
	local deepest_level = 0 -- deepest level needed
	local reset_with_level = {} -- map kind = level

	-- make the reset_with_level map
	-- and determine the deepest level needed
	for kind_key,definition in pairs(self.kinds) do
		local level = tonumber(definition.counter) or 
									self:get_level_by_LaTeX_name(definition.counter)
		if level then
			if level >=1 and level <= 6 then
				reset_with_level[kind_key] = level
				if level > deepest_level then
					deepest_level = level
				end
			else
				message('WARNING','Kind '..kind_key..' was assigned level '..tostring(level)
													..', which is outside the range 1-6 of Pandoc levels.'
													..' Counters for these statement may not work as desired.')
			end
		end
	end

	-- create levels up to the level needed
	-- use Pandoc's number_offset if html output
	-- default format: '%s' for level 1, '%p.%s' for others
	for i=1, deepest_level do -- will not do anything if `deepest_level` is 0
		self.counters[i] = {
				count = FORMAT:match('html') and PANDOC_WRITER_OPTIONS.number_offset[i]
								or 0,
				reset = pandoc.List:new(),
				format = i == 1 and '%s'
											or '%p.%s',
		}
		for kind,level in pairs(reset_with_level) do
			if level == i then
				self.counters[i].reset:insert(kind)
			end
		end
	end

	-- insert each kind in the reset list of its counter


end
