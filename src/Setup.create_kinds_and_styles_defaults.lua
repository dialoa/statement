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

	-- based_on_styles: builds styles based on other styles
	local function based_on_styles()

		for style,definition in pairs(self.styles) do

			if definition.based_on and self.styles[definition.based_on] then
				source_style = self.styles[definition.based_on]
				if source_style.based_on then
					message('ERROR', 'Defaults misconfigured: style `'..style..'` '
											..' is based on a style (`'..definition.based_on..'`)'
											..' that is itself based on another style.'
											..' this is not allowed.')
				else

					for key,value in pairs(source_style) do
						if not definition[key] then
							definition[key] = source_style[key]
						end
					end

					-- '' keys in derived styles are used to erase fields
					for key,value in pairs(definition) do
						if value == '' then
							definition[key] = nil
						end
					end

					-- once defined, not based on anymore
					-- (Ensures that if user redefines the basis style, it doesn't
					--	affect new styles based on this derived style)
					definition.based_on = nil

					-- No need for this in Lua as tables are passed by references
					-- but putting it there as a reminder of what happens
					-- self.styles[style] = definition

				end
			end

		end

	end

	-- MAIN FUNCTION BODY

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

	-- fill in styles based on other styles
	based_on_styles()

	-- styles: convert newlines in 'space_after_head' 
	-- to linebreak_after_head = true
	for style,definition in pairs(self.styles) do
		if definition.space_after_head and
			(definition.space_after_head == '\n'
				or definition.space_after_head == '\\n'
				or definition.space_after_head == '\\newline'
				) then
			self.styles[style].linebreak_after_head = true
			self.styles[style].space_after_head = nil
		end
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