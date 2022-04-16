--- Setup:read_options: read user options into the Setup.options table
--@param meta pandoc Meta object, document's metadata
--@return nil sets the Setup.options table
function Setup:read_options(meta) 

	-- language. Set language if we have a self.LOCALE value for it
	if meta.lang then
		-- change the language only if we have a self.LOCALE value for it
		-- in the LOCALE table languages are encoded zh_CN rather than zh-CN
		-- try the first two letters too
		local lang_str = stringify(meta.lang):lower():gsub('-','_')
		if self.LOCALE[lang_str] then
			self.options.language = lang_str
		elseif self.LOCALE[lang_str:sub(1,2)] then
			self.options.language = lang_str:sub(1,2)
		end
	end

	-- pick the document fontsize, needed to convert some lengths
	if meta.fontsize then
		local fontstr = stringify(meta.fontsize)
		local size, unit = fontstr:match('(%d*.%d*)(.*)')
		if tonumber(size) then
			unit = unit:gsub("%s+", "")
			self.options.fontsize = {tonumber(size), unit}
		end
	end

	-- determine which level corresponds to LaTeX's 'section'
	self.LaTeX_section_level = self:set_LaTeX_section_level(meta)

	if meta.statement then

		-- read boolean options
		local boolean_options = {
			amsthm = 'amsthm',
			aliases = 'aliases',
			acronyms = 'acronyms',
			swap_numbers = 'swap-numbers',
			supply_header = 'supply-header',
			only_statement = 'only-statement',
			define_in_header = 'define-in-header',
			citations = 'citations',
		}
		for key,option in pairs(boolean_options) do
			if type(meta.statement[option]) == 'boolean' then
				self.options[key] = meta.statement[option]
			end
		end

		-- read count-within option, level or LaTeX level name
		if meta.statement['count-within'] then
			local count_within = stringify(meta.statement['count-within']):lower()
			if self:get_level_by_LaTeX_name(count_within) then
				self.options.count_within = count_within
			elseif self:get_level_by_LaTeX_name(count_within) then
				self.options.count_within = count_within
			end
		end

	end -- end of `meta.statement` processing


end