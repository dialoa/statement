--- extract_label: extract label and acronym from a statement Div.
-- A label is a Strong element at the beginning of the Div, ending or 
-- followed by a dot. An acronym is between brackets, within the label
-- at the end of the label. If the label only contains an acronym,
-- it is used as label, brackets preserved.
-- if `acronym_mode` is set to false we do not search for acronyms.
-- label (Inlines) placed in self.label
-- acronym (Inlines) placed in self.acronym
-- remainder of the content (Blocks) placed in self.content
--@return nil 
function Statement:extract_label()
	local delimiters = {'(',')'} -- acronym delimiters
	local first_block, lab, acro = nil, nil, nil
	local has_label = false

	-- first block must be a Para that starts with a Strong element
	if self.content[1] and self.content[1].t == 'Para'
			and self.content[1].content and self.content[1].content[1]
			and self.content[1].content[1].t == 'Strong' then
		first_block = self.content[1]:clone() -- Para element
		lab = first_block.content[1].content -- content of the Strong element
		first_block.content:remove(1) -- take the Strong elem out
	else
		return
	end

	-- the label must end by or be followed by a dot
	-- if a dot is found, take it out.
	-- ends by a dot?
	if lab[#lab] 
		and lab[#lab].t == 'Str'
		and lab[#lab].text:match('%.$') then
			-- remove the dot
			if lab[#lab].text:len() > 1 then
				lab[#lab].text =
					lab[#lab].text:sub(1,-2)
				has_label = true
			else -- special case: Str was just a dot
				lab:remove(#lab)
				-- remove trailing Space if needed
				if lab[#lab]
					and lab[#lab].t == 'Space' then
						lab:remove(#lab)
				end
				-- do not validate if empty
				if #lab > 0 then
					has_label = true
				end
			end
	end
	-- followed by a dot?
	if first_block.content[1]
		and first_block.content[1].t == 'Str'
		and first_block.content[1].text:match('^%.') then
			-- remove the dot
			if first_block.content[1].text:len() > 1 then
				first_block.content[1].text =
					first_block.content[1].text:sub(2,-1)
					has_label = true
			else -- special case: Str was just a dot
				first_block.content:remove(1)
				-- validate even if empty
				has_label = true
			end
	end

	-- search for an acronym within the label
	-- we only store it if removing it leaves some label
	if self.setup.options.acronym then
		local saved_content = lab:clone()
		acro, lab = self:extract_fbb(lab, 'reverse')
		if acro and #lab == 0 then
			acro, lab = nil, saved_content
		end
	end

	-- remove trailing Space on the label if needed
	if #lab > 0 and lab[#lab].t == 'Space' then
		lab:remove(#lab)
	end

	-- remove leading Space on the first block if needed
	if first_block.content[1] 
		and first_block.content[1].t == 'Space' then
			first_block.content:remove(1)
	end

	-- store label, acronym modified content if label found
	if has_label then
		self.content[1] = first_block
		self.acronym = acro
		self.label = lab
	end

end
