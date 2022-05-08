--- Statement:write_label write the statement's full label
-- If numbered, use the kind label and statement numbering.
-- If custom label and acronym, use them. Otherwise no label.
-- Uses
--	self.is_numbered to tell whether the statement is numbered
--	self.setup.options.swap_numbers to swap numbers
-- 	self.custom_label, if any
-- 	self.crossref_label if numbered, this contains the numbering
-- 	self.setup.kinds[self.kind].label the kind's label, if any
--@return inlines statement label inlines
function Statement:write_label()
	kinds = self.setup.kinds -- pointer to the kinds table
	bb, eb = '(', ')' 
	inlines = pandoc.List:new()
	
	if self.custom_label then

		inlines:extend(self.custom_label)
		if self.acronym then
			inlines:insert(pandoc.Space())
			inlines:insert(pandoc.Str(bb))
			inlines:extend(self.acronym)			
			inlines:insert(pandoc.Str(eb))
		end

	else

		-- add kind label
		if kinds[self.kind] and kinds[self.kind].label then
			inlines:extend(kinds[self.kind].label)
		end

		-- if numbered, add number from self.crossref_label
		-- before or after depending on `swamp_numbers`
		if self.is_numbered and self.crossref_label then

			if self.setup.options.swap_numbers then
				if #inlines > 0 then
					inlines:insert(1, pandoc.Space())
				end
				inlines = self.crossref_label:__concat(inlines) 
			else
				if #inlines > 0 then
					inlines:insert(pandoc.Space())
				end
				inlines:extend(self.crossref_label)
			end

		end

	end

	return inlines

end