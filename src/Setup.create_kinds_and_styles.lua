---Setup:create_kinds_and_styles: Create kinds and styles
-- Populates Setup.kinds and Setup.styles with
-- default and user-defined kinds and styles.
-- Localizes the language and create aliases.
-- Updates:
--		self.styles
--		self.kinds 
--		self.aliases
--@param meta pandoc Meta object, document's metadata
--@return nil
function Setup:create_kinds_and_styles(meta)
	local language = self.options.language

	-- create default kinds and styles
	self:create_kinds_and_styles_defaults(meta)

	-- create user-defined kinds and styles
	self:create_kinds_and_styles_user(meta)

	-- @TODO read user-defined localizations?

	-- Check that shared counters are well defined
	-- A kind can only share a counter with a kind that doesn't
	for kind, definition in pairs(self.kinds) do
		if definition.counter and self.kinds[definition.counter]
			and self.kinds[definition.counter].counter
			and self.kinds[self.kinds[definition.counter].counter] then
				message('ERROR', 'Statement kind `'..kind..'` shares a counter'
												..' with a statement kind that also shares a'
												..' counter (`'..definition.counter..'`).'
												..' This is not allowed, things may break.')
		end
	end
	
	-- Finalize the kinds table
	-- ensure all labels are Inlines
	-- localize statement labels that aren't yet defined
	for kind_key, kind in pairs(self.kinds) do
		if kind.label then
			kind.label = pandoc.Inlines(kind.label)
		else
			kind.label = self.LOCALE[language]
									and self.LOCALE[language][kind_key]
									and pandoc.Inlines(self.LOCALE[language][kind_key])
									or nil
		end
	end

	-- populate the aliases map
	self:create_aliases()

end
