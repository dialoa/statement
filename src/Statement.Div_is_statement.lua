---Statement:Div_is_statement Whether an Div element is a statement.
-- If yes, returns a list of kinds the element matches.
--@param elem (optional) pandoc Div element, defaults to self.element
--@param setup (optional) a Setup class object, to be used when
--			the function is called from the setup object
--@return List or nil, pandoc List of kinds the element matches
function Statement:Div_is_statement(elem,setup)
	setup = setup or self.setup
	elem = elem or self.element
	local options = setup.options -- pointer to the options table
	local kinds = setup.kinds -- pointer to the kinds table

	-- safety check
	if not elem.t or elem.t ~= 'Div' then
		message('ERROR', 	'Non-Div element passed to the Div_is_statement function,'
											..' this should not have happened.')
		return
	end

	-- collect the element's classes that match a statement kind
	-- check aliases if `options.aliases` is true
	local matches = pandoc.List:new()
	for _,class in ipairs(elem.classes) do
		-- nb, needs to pass the setup to is_kind_key 
		-- in case the statement isn't created yet
		local kind_key = self:is_kind_key(class, setup)
		-- if found, add provided it's not a duplicate
		if kind_key and not matches:find(kind_key) then
			matches:insert(kind_key)
		end
	end

	-- fail if no match, or if the options require every statement to
	-- have the `statement` kind and we don't have it. 
	-- if success, remove the statement kind if we have another kind as well.
	if #matches == 0 
		or (options.only_statement and not matches:find('statement')) then
			return nil
	else
		if #matches > 1 and matches:includes('statement') then
			local _, pos = matches:find('statement')
			matches:remove(pos)
		end
		return matches
	end

end