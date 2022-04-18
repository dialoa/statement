---Setup:set_kind: create or set a kind based on an options map
-- Creates a new style or modify an existing one, based on options.
--@param kind string kind key
--@param map table, kind definition from user metadata
--@param new_kinds table (optional), new kinds to be defined
function Setup:set_kind(kind,map,new_kinds)
	local styles = self.styles -- points to the styles map
	local kinds = self.kinds -- points to the kinds map
	local map = map or {}
	local new_kind = {}

	-- if kind already defined, get original fields
	if kinds[kind] then
		new_kind = kinds[kind]
	end

	-- Ensure kind has a valid counter
	-- if shared counter, check that it exists or is about to be defined
	if map.counter then
		local counter = stringify(map.counter)
		if counter == 'self' or counter == 'none' then
			new_kind.counter = counter
		elseif counter == kind then -- using own name as counter
			new_kind.counter = 'self'
		elseif self:get_level_by_LaTeX_name(counter) then -- latex counter
			new_kind.counter = counter
		elseif self:get_LaTeX_name_by_level(counter) then -- level counter
			new_kind.counter = counter
		elseif kinds[counter] or new_kinds and new_kinds[counter] then
			new_kind.counter = counter
		else
			message('ERROR', 'Cannot understand counter setting `'..counter
											..'` to define statement kind '..kind..'.')
		end
	end
	-- if no counter, use the pre-existing counter if there's one
	-- otherwise use the first primary counter found in `kinds`
	-- or `options.count_within` or `self`	
	if not map.counter then
		if not new_kind.counter then
			for kind,definition in pairs(kinds) do
				if definition.counter == 'self'
					or self:get_level_by_LaTeX_name(definition.counter) 
					or self:get_LaTeX_name_by_level(definition.counter) then
						new_kind.counter = kind
						break
				end
			end
		end
		if not new_kind.counter then
			new_kind.counter = self.options.count_within or 'self'
		end
	end

	-- validate the kind's style
	-- if none (or bad) provided, use 'plain' or 'empty'
	if map.style then
		map.style = stringify(map.style)
	 	if styles[map.style] then
			new_kind.style = map.style
		else
			message('ERROR', 'Style `'.. map.style 
											..'` for statement kind `'..kind
											..'` is not defined.')
		end
	end
	if not map.style then 
		if styles['plain'] then
			new_kind.style = 'plain'
		elseif styles['empty'] then
			new_kind.style = 'empty'
		else -- use any style you can find!
			for style_key,_ in pairs(styles) do
				new_kind.style = style_key
				break
			end
		end
		if new_kind.style then
			message('INFO', 'Statement kind `'..kind..'`'
											..' has not been given a style.'
											..' Using `'..new_kind.style..'`.')
		else
			message('ERROR','Defaults misconfigured:'
													..'no `empty` style provided.')
			new_kind.style = 'empty' -- may still work e.g. in HTML
		end
	end

	-- validate and insert options
	local string_fields = { 
		'prefix', 
	}
	local inlines_fields = {
		'label'
	}
	local strings_list_fields = {
		'aliases',
	}
	local map_fields = {
		'custom_label_style'
	}
	for _,string_field in ipairs(string_fields) do
		if map[string_field] then
			new_kind[string_field] = stringify(map[string_field])
		end
	end
	for _,inlines_field in ipairs(inlines_fields) do
		if map[inlines_field] then
			if type(map[inlines_field]) == 'Inlines' then
				new_kind[inlines_field] = map[inlines_field]
			else
				new_kind[inlines_field] = pandoc.Inlines(pandoc.Str(
																		stringify(map[inlines_field])
																	))
			end
		end
	end
	for _,strings_list_field in ipairs(strings_list_fields) do
		if map[strings_list_field] then
			if type(map[strings_list_field]) == 'List' then
				new_kind[strings_list_field] = map[strings_list_field]
			elseif type(map[strings_list_field]) == 'string' 
					or type(map[strings_list_field]) == 'Inlines' then
				new_kind[strings_list_field] = pandoc.List:new(
																		{stringify(map[strings_list_field])}
																	)
			end
		end
	end
	for _,map_field in ipairs(map_fields) do
		if map[map_field] then
			new_kind[map_field] = map[map_field]
		end
	end

	-- store in kinds table
	kinds[kind] = new_kind

end