--- Create kinds and styles
-- Populates Setup.kinds and Setup.styles with
-- default and user-defined kinds and styles
--@param meta pandoc Meta object, document's metadata
--@return nil sets the Setup.kinds, Setup.styles, Setup.aliases tables
function Setup:create_kinds_and_styles(meta)
	local default_keys = pandoc.List:new() -- list of DEFAULTS.KINDS keys
	local chosen_defaults = 'basic' -- 'basic' unless user says otherwise
	local language = self.options.language

	-- make a list of defaults we have (overkill but future-proof)
	-- check that there's a DEFAULTS.STYLES key too
	default_keys = pandoc.List:new()
	for key,_ in pairs(self.DEFAULTS.KINDS) do
		if self.DEFAULTS.STYLES[key] then
			default_keys:insert(key)
		else
			message('WARNING', 'DEFAULTS file misconfigured: no `'
				..default_key..'` STYLES.')
		end
	end

	-- user-selected defaults?
	if not meta.statement and meta.statement.defaults
		and default_keys:find(stringify(meta.statement.defaults)) then
			chosen_defaults = stringify(meta.statement.defaults)
	end

	-- add the 'none' defaults no matter what
	for kind,definition in pairs(self.DEFAULTS.KINDS.none) do
		self.kinds[kind] = definition
	end
	for style,definition in pairs(self.DEFAULTS.STYLES.none) do
		self.styles[style] = definition
	end

	-- add the chosen defaults
	if chosen_defaults ~= 'none' then
		for kind,definition in pairs(self.DEFAULTS.KINDS[chosen_defaults]) do
			self.kinds[kind] = definition
		end
		for style,definition in pairs(self.DEFAULTS.STYLES[chosen_defaults]) do
			self.styles[style] = definition
		end
	end

	-- @TODO read kinds and styles definitions from `meta` here

	-- ensure all labels are Inlines
	-- localize statement labels that aren't yet defined
	for kind_key, kind in pairs(self.kinds) do
		if kind.label then
			kind.label = pandoc.Inlines(kind.label)
		elseif not kind.label and self.LOCALE[language][kind_key] then
			kind.label = pandoc.Inlines(self.LOCALE[language][kind_key])
		end
	end


	-- populate the aliases map (option 'aliases')
	if self.options.aliases then

		for kind_key,kind in pairs(self.kinds) do
			-- use the kind's prefix as alias, if any
			if kind.prefix then 
				self.aliases[kind.prefix] = kind_key
			end
			-- us the kind's label (converted to plain text), if any
			if kind.label then
				local alias = pandoc.write(pandoc.Pandoc({kind.label}), 'plain')
				alias = alias:gsub('\n','')
				self.aliases[alias] = kind_key
			end
		end

	end

end
