---Setup.create_kinds_and_styles_defaults: create the default
-- kinds and styles.
--@param meta pandoc Meta object, document's metadata
--@return nil sets the Setup.kinds, Setup.styles, Setup.aliases tables
function Setup:create_kinds_and_styles_defaults(meta)
	local chosen_defaults = 'basic' -- 'basic' unless user says otherwise

	-- add_default_set: adds a given set of defaults to kinds and styles
	local function add_default_set(set_key)
		for kind,definition in pairs(self.DEFAULTS.KINDS[set_key]) do
			self.kinds[kind] = definition
		end
		for style,definition in pairs(self.DEFAULTS.STYLES[set_key]) do
			self.styles[style] = definition
		end
	end

	-- does the user want to check the filter's DEFAULTS files?
	if meta.statement and meta.statement['validate-defaults'] then
		self:validate_defaults()
	end

	-- user-selected defaults?
	if meta.statement and meta.statement.defaults then
		local new_defaults = stringify(meta.statement.defaults)
		if self.DEFAULTS.KINDS[new_defaults] then
			chosen_defaults = new_defaults
		end
	end

	-- add the 'none' defaults no matter what, then the chosen ones
	add_default_set('none')
	if chosen_defaults ~= 'none' then
		add_default_set(chosen_defaults)
	end

	-- if count_within, change defaults with 'self' counter 
	-- to 'count_within' counter
	if self.options.count_within then
		for kind,definition in pairs(self.kinds) do
			if definition.counter == 'self' then 
				self.kinds[kind].counter = self.options.count_within
			end
		end
	end
	
end