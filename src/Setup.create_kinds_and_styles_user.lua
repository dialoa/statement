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
	local new_kinds, new_styles

	---dash_keys_to_underscore: replace dashes with underscores in a 
	--	map key's.
	--@param map table a map to be converted
	--@return
	local function dash_keys_to_underscore(map)
		new_map = {}
		for key,value in pairs(map) do
			new_map[key:gsub('%-','_')] = map[key]
		end
		return new_map
	end

	-- User-defined styles
	-- The ones in 'statement' prevail over those in 'statement-styles'
	-- @note using type(X) == 'table' to test both existence and type
	if type(meta['statement-styles']) == 'table' 
			or meta.statement and type(meta.statement.styles) == 'table' then

		-- gather the styles to be defined in a map
		-- the ones in 'statement' normally prevail over those in 'statement-styles'
		new_styles = {}

		-- insert_new_style: set a style in new_styles
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

		-- recursive function to define a style
		--@param style string the style name
		--@param definition map the style definition in user's metadata
		--@recursion trail pandoc List, list of styles defined in a recursion
		local function try_define_style(style, definition, recursion_trail)
			-- if already defined, we're good
			if definition.is_defined then return end
			-- if `based_on` is set, possible cases:
			--		- basis not in defaults or new_styles: ignore
			--		- current style among those to be defined: circularity, ignore
			--		- bases is in new_styles and not defined: recursion step
			--		- basis is in new_styles but already defined: go ahead
			--		- basis is in styles and not in new_styles: go ahead
			if definition.based_on then
				local parent_style = stringify(definition.based_on)

				if not self.styles[parent_style] 
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
					return

				end -- any other case than recursion, go ahead
			end
			-- if still not defined, not based on another style
			-- or based_on was ignored
			self:set_style(style, definition, new_styles)
			definition.is_defined = true

		end

		-- main loop to define styles
		for style,definition in pairs(new_styles) do
			try_define_style(style, definition)
		end

	end -- end of user-defined styles

	-- User-defined kinds
	-- The ones in 'statement' prevail over those in 'statement-kinds'
	-- @note using type(X) == 'table' to test both existence and type
	if type(meta['statement-kinds']) == 'table' 
			or meta.statement and type(meta.statement.kinds) == 'table' then

		-- gather the kinds to be defined
		new_kinds = {}
		--- insert_new_kind: function to insert a kind `in new_kinds`
		local function insert_new_kind(kind,definition)
			if type(definition) == 'table' then
				new_kinds[kind] = definition
			else
				message('ERROR', 'Could not understand the definition of'
													..'statement kind '..kind..'.'
													.." I've ignored it.")
			end
		end
		-- gather the kinds to be defined
		if type(meta['statement-kinds']) == 'table' then
			for kind,definition in pairs(meta['statement-kinds']) do
				insert_new_kind(kind,definition)
			end
		end
		if meta.statement and type(meta.statement.kinds) == 'table' then
			for kind,definition in pairs(meta.statement.kinds) do
				insert_new_kind(kind,definition)
			end
		end

		-- main loop to define kinds
		for kind,definition in pairs(new_kinds) do
			self:set_kind(kind,definition,new_kinds)
		end

	end -- end of user-defined kinds

end
