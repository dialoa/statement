---Setup:create_aliases: create map of kind aliases
-- Populates self.aliases if the `aliases` options is set
function Setup:create_aliases()

	if not self.options.aliases then
		return
	end
	
	-- add_alias: function to add an alias to self.aliases
	-- 		ensure it's a string, use lowercase for case-insensitive matches
	local function add_alias(alias, kind_key)
		alias = stringify(alias):lower()
		-- warn if clash
		if self.aliases[alias] and self.aliases[alias] ~= kind_key then
			message('WARNING', 'Cannot use `'..alias..'` as an alias of `'..kind_key..'`'
													..', it is already an alias of `'..self.aliases[alias]..'`.')
		else
			self.aliases[alias] = kind_key
		end
	end


	for kind_key,kind in pairs(self.kinds) do
		-- user-defined aliases?
		if kind.aliases then
			for _,alias in ipairs(kind.aliases) do
				add_alias(alias,kind_key)
			end
		end
		-- use the kind's prefix as alias, if any
		if kind.prefix then
			add_alias(kind.prefix,kind_key) 
		end
		-- us the kind's label
		if kind.label then
			add_alias(kind.label,kind_key)
		end
	end


end
