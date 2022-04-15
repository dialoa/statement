---Setup:set_kind: create or set a kind based on an options map
-- Creates a new style or modify an existing one, based on options.
--@param name string style key
--@param map map of options
function Setup:set_kind(kind,map)
	local styles = self.styles -- points to the styles map
	local kinds = self.kinds -- points to the kinds map
--	local user_kinds = self.user_kinds -- user kinds (for shared counter checks)
--	local user_styles = self.user_kinds -- user kinds (for shared counter checks)
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
		elseif self:get_level_by_LaTeX_name(counter) then
			new_kind.counter = counter
		elseif self:get_level_by_LaTeX_name(counter) then
			new_kind.counter = counter
		elseif kinds[counter] then
			new_kind.counter = counter
		-- elseif shared counter with a kind to be defined! USER_DEFINED(...)
		else
			message('ERROR', 'Cannot understand counter setting `'..counter
											..'` to define statement kind '..kind..'.')
		end
	end
	-- if no counter, use the first primary counter found in `kinds`
	-- or `options.count_within` or `self`	
	if not map.counter then
		for kind,definition in ipairs(kinds) do
			if definition.counter == 'self'
				or self:get_level_by_LaTeX_name(counter) 
				or self:get_level_by_LaTeX_name(counter) then
					new_kind.counter = definition.counter
					break
			end
		end
		if not map.counter then
			new_kind.counter = self.options.count_within or 'self'
		end
	end

	-- validate style
	-- if none (or bad) provided, use 'plain' or 'empty'
	if map.style then
	 	if styles[stringify(map.style)] then
			new_kind.style = stringify(map.style)
		else
			message('ERROR', 'Style `'..stringify(map.style)
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
																		stringify(map[strings_list_field])
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