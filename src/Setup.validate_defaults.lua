---Setup:validate_defaults: check that the filter's DEFAULTS are
-- well configured. Prints an error if not.
function Setup:validate_defaults()
	local default_keys = pandoc.List:new() -- list of DEFAULTS.KINDS keys
	local valid = true

	-- check that we have 'none' defaults and that they provide 'statement'
	if not self.DEFAULTS.KINDS.none then
		message('ERROR', 'DEFAULTS file misconfigured: `none` defaults set missing in KINDS.')
		valid = false
	elseif not self.DEFAULTS.KINDS.none.statement then
		message('ERROR', 'DEFAULTS file misconfigured: `none` defaults lack the `statement` kind.')
		valid = false
	elseif not self.DEFAULTS.KINDS.none.statement.style then
		message('ERROR', 'DEFAULTS file misconfigured: `none.statement` has no style setting.')
		valid = false
	elseif not self.DEFAULTS.STYLES.none 
					or not self.DEFAULTS.STYLES.none[self.DEFAULTS.KINDS.none.statement.style] then
		message('ERROR', 'DEFAULTS file misconfigured: the none.statement style, '
										..self.DEFAULTS.KINDS.none.statement.style
										..' should be present in the STYLES.none table.')
		valid = false
	end
	if not self.DEFAULTS.STYLES.none then
		message('ERROR', 'DEFAULTS file misconfigured: `none` defaults set missing in STYLES.')
		valid = false
	end

	-- check that each default set has both kinds and styles
	for set,_ in pairs(self.DEFAULTS.KINDS) do
		if not self.DEFAULTS.STYLES[set] then
			message('ERROR', 'DEFAULTS file misconfigured: no `'
				..set..'` defaults in the STYLES table.')
			valid = false
		end
	end

	-- check that each kind has a counter and an existing style
	for set,_ in pairs(self.DEFAULTS.KINDS) do
		for kind,definition in pairs(self.DEFAULTS.KINDS[set]) do
			if not definition.counter then 
				message('ERROR', 'DEFAULTS file misconfigured: kind `'..kind..'`'
												..' in default set `'..set..'` has no counter.')
				valid = false
			end
			if not definition.style then 
				message('ERROR', 'DEFAULTS file misconfigured: kind `'..kind..'`'
												..' in default set `'..set..'` has no style.')
				valid = false
			end
			if not self.DEFAULTS.STYLES[set][definition.style] then 
				message('ERROR', 'DEFAULTS file misconfigured: style `'..definition.style..'`'
												..' needed by kind `'..kind..'` is missing in STYLES.'..set..'.')
				valid = false
			end
			if self.options and self.options.language
				and not self.LOCALE[self.options.language][kind] then
					message('WARNING', 'LOCALE file, entry `'..self.options.language..'`'
								.."doesn't provide a label for the kind `"..kind..'`'
								..' in defaults set `'..set..'`.')
				valid = false
			end
		end
	end

	if valid then
		message('INFO', 'Defaults files checked, all is in order.')
	end

end