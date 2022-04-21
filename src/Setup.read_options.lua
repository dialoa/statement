--- Setup:read_options: read user options into the Setup.options table
--@param meta pandoc Meta object, document's metadata
--@return nil sets the Setup.options table
function Setup:read_options(meta) 

	-- user-defined localisations.
	-- Ready any user-provided translation map in 'stateemnt-locale' or 'locale'
	if meta['statement-locale'] or meta.locale then

		local function set_locale(lang,map)
			if type(map) ~= 'table' then 
				return
			end
			local lang_str = stringify(lang):lower():gsub('-','_')
			if not self.LOCALE[lang_str] then 
				self.LOCALE[lang_str] = {}
			end
			for key,translation in pairs(map) do
				if type(translation) == 'string' 
						or type(translation) == 'Inlines' then
					self.LOCALE[lang_str][key] = translation
				end
			end
		end

		if meta.locale and type(meta.locale) == 'table' then
			for lang,map in pairs(meta.locale) do
				set_locale(lang,map)
			end
		end
		if meta['statement-locale'] 
				and type(meta['statement-locale']) == 'table' then
			for lang,map in pairs(meta['statement-locale']) do
				set_locale(lang,map)
			end
		end

	end

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
		elseif self.LOCALE['en'] then
			self.options.language = 'en'
		else
			for lang_key,_ in pairs(self.LOCALE) do
				self.options.language = lang_key
				break
			end
			if lang_key then 
				message('ERROR', 'No translations for language '..lang_str..'.'
												 ..' English not available either.'
												 .." I've randomly picked `"..self.options.language..'`'
												 ..'instead.')
			else
				message('ERROR', 'Translation table LOCALE is empty, the filter will crash.')
			end
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
			pandoc_amsthm = 'pandoc-amsthm',
		}
		for key,option in pairs(boolean_options) do
			if type(meta.statement[option]) == 'boolean' then
				self.options[key] = meta.statement[option]
			end
		end

		-- read count-within option, level or LaTeX level name
		-- two locations:
		-- (1) pandoc-amsthm style options, in amsthm: counter_depth (number)
		-- (2) statement:count-within
		-- The latter prevails.
		if self.options.pandoc_amsthm and meta.amsthm 
				and meta.amsthm.counter_depth then
			local count_within = tonumber(stringify(meta.amsthm.counter_depth))
			if self:get_LaTeX_name_by_level(count_within) then
				self.options.count_within = count_within
			end
		end
		if meta.statement['count-within'] then
			local count_within = stringify(meta.statement['count-within']):lower()
			if self:get_level_by_LaTeX_name(count_within) then
				self.options.count_within = count_within
			elseif self:get_LaTeX_name_by_level(count_within) then
				self.options.count_within = count_within
			end
		end

	end -- end of `meta.statement` processing


end