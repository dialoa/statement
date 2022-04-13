--- Statement:set_crossref_label
-- Set a statement's crossref label, i.e. the text that will be
-- used in crossreferences to the statement.
-- priority:
--		- use self.crossref_label, if user set
-- 		- use self.acronym, otherwise
--		- use self.label (custom label), otherwise
--		- use formatted statement count
--		- '??'
--@return nil sets self.crossref_label, pandoc Inlines
function Statement:set_crossref_label()
	local delimiter = '.' -- separates section counter and statement counter
	local kinds = self.setup.kinds -- pointer to the kinds table
	local counters = self.setup.counters -- pointer to the counters table

	-- use self.crossref_label if set
	if self.crossref_label then
	-- or use acronym
	elseif self.acronym then
		self.crossref_label = self.acronym
	-- or custom label
	elseif self.custom_label then
		self.crossref_label = self.custom_label
	-- or formatted statement count
	elseif self.is_numbered then
		-- if shared counter, switch kind to the shared counter's kind
		local kind = self.kind
		local counter = kinds[self.kind].counter
		if kinds[counter] then
			kind = counter
			counter = kinds[counter].counter
		end
		-- format result depending of 'self', <level> or 'none'/unintelligible
		if counter =='self' then
			local count = kinds[kind].count or 0
			self.crossref_label = pandoc.Inlines(pandoc.Str(tostring(count)))
		elseif type(counter) == 'number' 
			or self.setup:get_level_by_LaTeX_name(counter) then
			if type(counter) ~= 'number' then
				counter = self.setup:get_level_by_LaTeX_name(counter)
			end
			local count = kinds[kind].count or 0
			local prefix = self.setup:write_counter(counter)
			local str = prefix..delimiter..tostring(count)
			self.crossref_label = pandoc.Inlines(pandoc.Str(str))
		else
			self.crossref_label = pandoc.Inlines(pandoc.Str('??'))
		end
	-- or set it to '??'
	else
		self.crossref_label = pandoc.Inlines(pandoc.Str('??'))
	end

end
