--- Statement:find_kind: find whether an element is a statement and of what kind
--@param elem pandoc Div or item in a pandoc DefinitionList
--@param setup Setup class object, filter setup
--@return string or nil the key of `kinds` if found, nil otherwise
function Statement:find_kind(elem, setup)
	local kinds = setup.kinds -- points to the kinds table
	local options = setup.options -- points to the options table
	local aliases = setup.aliases -- points to the aliases table

	if elem.t and elem.t == 'Div' then

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

		-- return if no match
		if #matches == 0 then return nil end
		-- return if we only process 'statement' Divs and it isn't one
		if options.only_statement and not matches:find('statement') then
			return nil
		end

		-- if we have other matches that 'statement', remove the latter
		if #matches > 1 and matches:includes('statement') then
			local _, pos = matches:find('statement')
			matches:remove(pos)
		end

		-- warn if we still have more than one match
		if #matches > 1 then
			local str = ''
			for _,match in ipairs(matches) do
				str = str .. ' ' .. match
			end
			message('WARNING', 'A Div matches several statement kinds: '
				.. str .. '. Treated as kind '.. matches[1] ..'.')
		end

		-- return the first match, a key of `kinds`
		return matches[1]

	elseif type(elem) == 'table' then

			message('WARNING', 'A non-Div element passed as potential statement. '
				.. 'Not supported yet. Element content: '..stringify(elem))

		-- process DefinitionList items here
		-- they are table with two elements:
		-- [1] Inlines, the definiens
		-- [2] Blocks, the definiendum

	else

		return nil -- not a statement kind

	end

end
