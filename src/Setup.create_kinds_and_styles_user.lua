---Setup:create_kinds_and_styles_user: Create user-defined
-- kinds and styles. 
-- Styles may be based on other styles, so we need to 
-- proceed recursively without getting into endless loops.
-- Updates:
--		self.styles
--		self.kinds 
--@param meta pandoc Meta object, document's metadata
--@return nil 
function Setup:create_kinds_and_styles_user(meta)
	local options = self.options -- points to the options table
	local styles = self.styles -- points to the styles table
	local new_kinds, new_styles

	---dash_keys_to_underscore: replace dashes with underscores in a 
	--	map key's.
	--@param map table a map to be converted
	--@return
	local function dash_keys_to_underscore(map)
		new_map = {}
		for key,_ in pairs(map) do
			new_map[key:gsub('%-','_')] = map[key]
		end
		return new_map
	end

	-- insert_new_style: set a style in `new_styles`
	-- Insert a style in `new_styles`, erasing any previous value for it.
	-- If the definition isn't a map, assume an alias: 'style1: style2'
	--@param style string style key
	--@param definition definition map
	local function insert_new_style(style,definition)
		if type(definition) == 'table' then
			new_styles[style] = definition
		elseif definition then
			new_styles[style] = { based_on = stringify(definition) }
		end
	end

	--- insert_new_kind: function to insert a kind in `new_kinds`
	local function insert_new_kind(kind,definition)
		if type(definition) == 'table' then
			new_kinds[kind] = definition
		else
			message('ERROR', 'Could not understand the definition of'
												..'statement kind '..kind..'.'
												.." I've ignored it.")
		end
	end

	-- recursive function to define a style
	--@param style string the style name
	--@param definition map the style definition in user's metadata
	--@recursion trail pandoc List, list of styles defined in a recursion
	local function try_define_style(style, definition, recursion_trail)
		-- if already defined, we're good
		if definition.is_defined then return end
		-- replace dashes with underscores
		definition = dash_keys_to_underscore(definition)
		-- if `based_on` is set, possible cases:
		--		- basis not in defaults or new_styles: ignore
		--		- current style among those to be defined: circularity, ignore
		--		- bases is in new_styles and not defined: recursion step
		--		- basis is in new_styles but already defined: go ahead
		--		- basis is in styles and not in new_styles: go ahead
		if definition.based_on then
			local parent_style = stringify(definition.based_on)

			if not styles[parent_style] 
					and not new_styles[parent_style] then
				message('ERROR', 'Style `'..style..'` is supposed to be based'
													..' on style `'..parent_style..'`'
													..' but I cannot find the latter.'
													..' The `based-on` parameter will be ignored.')
				definition.based_on = nil

			elseif recursion_trail and recursion_trail:find(style) then
				local m_str = recursion_trail[1]
				for i = 2, #recursion_trail do
					m_str = m_str..' -> '..recursion_trail[i]
				end
				m_str = m_str..' -> '..style
				message('ERROR', 'Circularity in style definitions: '
													..m_str..'. The `based-on parameter'
													..' of style '..style..' is ignored.')
				definition.based_on = nil

			elseif new_styles[parent_style]
						and not new_styles[parent_style].is_defined then
				recursion_trail = recursion_trail or pandoc.List:new()
				recursion_trail:insert(style)
				try_define_style(parent_style, new_styles[parent_style], 
													recursion_trail)
				self:set_style(style, definition, new_styles)
				definition.is_defined = true
				recursion_trail:remove()
				return -- recursion complete, we exit

			end
		end
		-- any case other than the recursive one above,
		-- we're clear to define the style:
		self:set_style(style, definition, new_styles)
		definition.is_defined = true

	end

	--- parse_by_style: parse a list of kinds for a given style
	-- in the style of pandoc-amsthm kind definitions.
	-- remark: Case
	-- plain: [Theorem, Lemma, Corollary, Conjecture, Proposition]
	-- definition:
	-- - Definition
	-- remark-unnumbered: ...
	--@param style_key string key of the styles table
	--@param list List, string or Inlines, kinds
	local function parse_by_style(style_key, list, counter)
		if type(list) == 'string' or type(list) == 'Inlines' then
			list = pandoc.List:new( {list} )
		end
		if type(list) == 'List' then
			for _,item in ipairs(list) do
				-- each item is a kind's label, or a map (kind = list_subkinds)
				if type(item) == 'string' or type(item) == 'Inlines' then
					local kind = stringify(item):gsub('[^%w]','_')
					insert_new_kind(kind, {
							label = item,
							counter = counter, -- may be nil, set_kind takes care of it
							style = style_key,
					})
				end
			end
		end
	end
	--- parse_by_styles: parse a Meta map looking for 
	-- keys that correspond to a style, and parse each of these
	-- as a list of kinds.
	local function parse_by_styles(map)
		for style,list in pairs(styles) do
			if map[style] then 
				parse_by_style(style, map[style])
			end
			-- is there a <style>-unnumbered list to process as well?
			-- only process if it's not already a style
			if map[style..'-unnumbered'] 
					and not styles[style..'-unnumbered'] then 
				parse_by_style(style, map[style..'-unnumbered'], 'none')
			end
		end
	end

	-- MAIN FUNCTION BODY

	-- User-defined styles
	-- The ones in 'statement' prevail over those in 'statement-styles'
	-- @note using type(X) == 'table' to test both existence and type
	if type(meta['statement-styles']) == 'table' 
			or meta.statement and type(meta.statement.styles) == 'table' then

		-- gather the styles to be defined in a map
		-- the ones in 'statement' normally prevail over those in 'statement-styles'
		new_styles = {}

		if type(meta['statement-styles']) == 'table' then
			for style,definition in pairs(meta['statement-styles']) do
				insert_new_style(style, definition)
			end
		end
		if meta.statement and type(meta.statement.styles) == 'table' then
			for style,definition in pairs(meta.statement.styles) do
				insert_new_style(style, definition)
			end
		end

		-- main loop to define styles
		for style,definition in pairs(new_styles) do
			try_define_style(style, definition)
		end

	end -- end of user-defined styles

	-- User-defined kinds
	-- Can be found in four locations.
	--		(a) full definitions in 'statement:kinds:' and 'statement-kinds'
	--				(the former prevails)
	--		(b) by-style label only in 'statement' or 'pandoc-amsthm'				
	-- @note using type(X) == 'table' to test both existence and type
	if meta.statement
			or type(meta['statement-kinds']) == 'table' 
			or options.pandoc_amsthm and type(meta.amsthm) == 'table' then

		-- Gather kinds to be defined
		new_kinds = {} -- map

		-- Gather definitions from four locations
		-- latter ones erase former ones
		-- (1) pandoc-amsthm's `amsthm` field, kinds given by style
		if options.pandoc_amsthm and type(meta.amsthm) == 'table' then
			parse_by_styles(meta.amsthm)
		end
		-- (2) `statement` field, kinds given by style
		if meta.statement then 
			parse_by_styles(meta.statement)
		end
		-- (3) `statement-kinds` map of full definitions
		if type(meta['statement-kinds']) == 'table' then
			for kind,definition in pairs(meta['statement-kinds']) do
				insert_new_kind(kind,definition)
			end
		end
		-- (4) `statement:kinds` map of full definitions
		if meta.statement and type(meta.statement.kinds) == 'table' then
			for kind,definition in pairs(meta.statement.kinds) do
				insert_new_kind(kind,definition)
			end
		end

		-- main loop to define the kind definitions we've gathered
		for kind,definition in pairs(new_kinds) do
			self:set_kind(kind,definition,new_kinds)
		end

	end -- end of statement kinds

end
