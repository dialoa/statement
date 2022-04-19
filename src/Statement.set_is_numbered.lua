--- Statement:set_is_numbered: determine whether a statement is numbered
-- Checks if the element has a 'unnumbered' attribute or 'none' counter.
-- Updates:
--	self.is_numbered Bool whether the statement is numbered
--@param elem the statement element Div or item in Definition list
--@return nil
function Statement:set_is_numbered(elem)
	kinds = self.setup.kinds -- pointer to the kinds table
	elem = elem or self.element

	-- is_counter: whether a counter is a level, LaTeX level or 'self'
	local function is_counter(counter) 
		return counter == 'self'
					or (type(counter) == 'number' and counter >= 1 and counter <= 6)
					or self.setup:get_level_by_LaTeX_name(counter)
		end

	-- custom label theorems aren't numbered
	if self.custom_label then

			self.is_numbered = false

	elseif elem.t == 'Div' and elem.classes:includes('unnumbered') then

			self.is_numbered = false

	elseif kinds[self.kind] and kinds[self.kind].counter then
		-- check if this is a counting counter
		local counter = kinds[self.kind].counter
		-- if shared counter, switch to that counter
		if kinds[counter] then
			counter = kinds[counter].counter
		end
		-- check this is a counting counter
		if is_counter(counter) then
			self.is_numbered = true
		else
			self.is_numbered = false
		end

	else -- 'none' or something unintelligible

		self.is_numbered = false
		
	end
end

