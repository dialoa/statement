--- Statement:set_labels: Set a statement's label and 
-- crossref label. The label is used in the statement
-- heading, the crossref label in references. 
-- Ex: label "Theorem 1.1", crossref_label "1.1"
-- Updates:
--		self.label
--		self.crossref_label
-- Crossref label priority:
--		- use self.crossref_label, if user set
-- 		- use self.acronym, otherwise
--		- use self.label (custom label), otherwise
--		- use formatted statement count
--		- '??'
--@return nil
function Statement:set_labels()
	local kinds = self.setup.kinds -- pointer to the kinds table
	local kind = self.kind -- the statement's kind
	local delimiter = self.setup.options.counter_delimiter
										or '.' -- separates section counter and statement counter
	local counters = self.setup.counters -- pointer to the counters table
	local number -- string formatted number, if numbered statement

	-- If numbered, create the `number` string
	if self.is_numbered then
		-- counter; if shared, use the source's counter
		local counter = kinds[kind].counter
		local kind_to_count = kind
		if kinds[counter] then
			kind_to_count = counter
			counter = kinds[counter].counter
		end
		-- format depending on counter == `self`, <level> or 'none'/unintelligible
		local level = self.setup:get_level_by_LaTeX_name(counter)
		local count = kinds[kind_to_count].count or 0
		if level then
			number = self.setup:write_counter(level)..delimiter..count
		elseif counter == 'self' then
			number = tostring(count)
		else
			number = '??'
		end
	end

	-- Label
	if self.custom_label then
		self.label = self.custom_label
	elseif kinds[kind].label then
		self.label = kinds[kind].label:clone()
		if number then
			self.label:extend({pandoc.Space(), pandoc.Str(number)})
		end
	end

	-- Crossref Label
	-- (future use) use self.crossref_label if set (open this to Div attributes?)
	if self.crossref_label then
	-- or use acronym
	elseif self.acronym then
		self.crossref_label = self.acronym
	-- or custom label
	elseif self.custom_label then
		self.crossref_label = self.custom_label
	-- or formatted statement count
	elseif number then
		self.crossref_label = pandoc.Inlines(pandoc.Str(number))
	-- or set it to '??'
	else
		self.crossref_label = pandoc.Inlines(pandoc.Str('??'))
	end

end
