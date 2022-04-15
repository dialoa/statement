---Statement:kinds_matched Determines whether an element is a
-- statement and return the kinds it matches. 
--@param elem (optional) pandoc element, should be Div or DefinitionList
--							default to self.element
--@param setup (optional) a Setup class object, to be used when
--			the function is called from the setup object
--@return list, a pandoc List of matched kinds or nil
function Statement:kinds_matched(elem,setup)
	setup = setup or self.setup
	elem = elem or self.element
	local options = setup.options -- pointer to the options table
	local kinds = setup.kinds -- pointer to the kinds table
	local aliases = setup.aliases -- pointed to the aliases table

	if elem.t then
		if elem.t == 'Div' then
			-- collect the element's classes that match a statement kind
			-- check aliases if `options.aliases` is true
			local matches = pandoc.List:new()
			for _,class in ipairs(elem.classes) do
				if kinds[class] and not matches:find(class) then
					matches:insert(class)
				elseif options.aliases
					and aliases[class] and not matches:find(aliases[class]) then
					matches:insert(aliases[class])
				end
			end

			-- return nil if no match, or if options requires a statement
			-- class and we don't have it
			if #matches == 0 
				or options.only_statement and not matches:find('statement') then
					return nil
			else
					return matches
			end

		--@TODO process DefinitionList
		elseif elem.t == 'DefinitionList' then

			--@TODO

		end

	end

end
	