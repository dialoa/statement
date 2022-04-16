---Setup:create_kinds_and_styles: Create kinds and styles
-- Populates Setup.kinds and Setup.styles with
-- default and user-defined kinds and styles
--@param meta pandoc Meta object, document's metadata
--@return nil sets the Setup.kinds, Setup.styles, Setup.aliases tables
function Setup:create_kinds_and_styles(meta)
	local language = self.options.language

	-- create default kinds and styles
	self:create_kinds_and_styles_defaults(meta)

	-- parse user-defined kinds and styles

	-- dash_keys_to_underscore: replace dashes with underscores in a 
	--	map key's
	function dash_keys_to_underscore(map) 
		new_map = {}
		for key,value in pairs(map) do
			new_map[key:gsub('%-','_')] = map[key]
		end
		return new_map
	end

	-- read kinds and styles definitions from `meta` here
	if meta['statement-styles'] and type(meta['statement-styles']) == 'table' then
		for style,definition in pairs(meta['statement-styles']) do
			self:set_style(style,dash_keys_to_underscore(definition))
		end
	end
	if meta.statement and meta.statement.styles 
		and type(meta.statement.styles) == 'table' then
		for style,definition in pairs(meta.statement.styles) do
			self:set_style(style,dash_keys_to_underscore(definition))
		end
	end
	if meta['statement-kinds'] and type(meta['statement-kinds']) == 'table' then
		for kind,definition in pairs(meta['statement-kinds']) do
			self:set_kind(kind,dash_keys_to_underscore(definition))
		end
	end
	if meta.statement and meta.statement.kinds 
		and type(meta.statement.kinds) == 'table' then
		for kind,definition in pairs(meta.statement.kinds) do
			self:set_kind(kind,dash_keys_to_underscore(definition))
		end
	end

	-- Finalize the kinds table
	-- ensure all labels are Inlines
	-- localize statement labels that aren't yet defined
	for kind_key, kind in pairs(self.kinds) do
		if kind.label then
			kind.label = pandoc.Inlines(kind.label)
		elseif not kind.label and self.LOCALE[language][kind_key] then
			kind.label = pandoc.Inlines(self.LOCALE[language][kind_key])
		end
	end

	-- populate the aliases map
	self:create_aliases()

end
