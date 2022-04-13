--- Statement:find_kind: find whether an element is a statement and of what kind
--@param elem pandoc Div or item in a pandoc DefinitionList
--@return string or nil the key of `kinds` if found, nil otherwise
function Statement:find_kind(elem)
	local setup = self.setup -- points to the setup table
	local options = setup.options -- points to the options table
	local kinds = setup.kinds -- points to the kinds table
	local aliases = setup.aliases -- points to the aliases table

	if elem.t and elem.t == 'Div' then

		local kinds_matched = self:kinds_matched(elem)

		-- if kinds matched, find king
		if kinds_matched then

			-- remove 'statement' if it's redundant
			if #kinds_matched > 1 and kinds_matched:includes('statement') then
				local _, pos = kinds_matched:find('statement')
				kinds_matched:remove(pos)
			end
			-- warn if there's still more than one kind
			if #kinds_matched > 1 then
				local str = ''
				for _,match in ipairs(kinds_matched) do
					str = str .. ' ' .. match
				end
				message('WARNING', 'A Div kinds_matched several statement kinds: '
					.. str .. '. Treated as kind '.. kinds_matched[1] ..'.')
			end
			-- return the first match, a key of `kinds`
			return kinds_matched[1]

		else -- no match

			return nil

		end

	-- @TOOO process DefinitionList

		-- process DefinitionLists
		-- list of items
		-- each item is a table with two elements:
		-- [1] Inlines, the definiens
		-- [2] the definienda, a list of definitions
		--			where each definition is Blocks

	-- other element types passed, warn
	else

		local type_str = elem.t and 'Element type: '..elem.t..'.' or ''

			message('WARNING', 'A wrong element passed as potential statement. '
				.. type.str .. 'Element content: '..stringify(elem) )

	end

end
