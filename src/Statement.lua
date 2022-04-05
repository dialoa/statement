-- # Statement class

--- Statement: class for statement objects.
-- @field kind string the statement's kind (key of the `kinds` table)
-- @field id string the statement's id
-- @field cust_label Inlines the statement custom's label, if any
-- @field info Inlines the statement's info
Statement = {
	kind = nil, -- string, key of `kinds`
	id = nil, -- string, Pandoc id
	cust_label = nil, -- Inlines, user-provided label
	info = nil, -- Inlines, user-provided info
	content = nil, -- Blocks, statement's content
}
--- create a statement object from a pandoc element.
-- @param elem pandoc Div or list item (= table list of 2 elements)
-- @param kind string (optional) statement's kind (key of `kinds`)
-- @return statement object or nil if elem isn't a statement
function Statement:new(elem)

	local kind = Statement:find_kind(elem)
	if kind then

		-- create an object of Statement class
		o = {}
		self.__index = self 
		setmetatable(o, self)

		-- populate the object
		-- kind
		o.kind = kind
		o.content = elem.content
		o:extract_info()

		-- return
		return o
	
	else
		return nil
	end

end
--- find_kind: find whether an element is a statement and of what kind
-- This function extracts custom label and info from self.content,
-- as these will be needed to determine the final kind.
-- @param elem pandoc Div or item in a pandoc DefinitionList
-- @return string or nil the key of `kinds` if found, nil otherwise
function Statement:find_kind(elem)

	if elem.t and elem.t == 'Div' then

		-- collect the element's classes that match a statement kind
		-- check aliases if `options.aliases` is true
		local matches = pandoc.List:new()
		for _,class in ipairs(elem.classes) do
			if kinds[class] and not matches:find(class) then
				matches:insert(class)
			elseif options.aliases
				and aliases[class] and not matches:find(aliases[class]) then
				matches:insert(aliases[class])
			end
		end

		-- return if no match
		if #matches == 0 then return nil end
		-- return if we only process 'statement' Divs and it isn't one
		if options.only_statement and not matches:find('statement') then
			return nil
		end

		-- if we have other matches that 'statement', remove the latter
		if #matches > 1 and matches:includes('statement') then
			local _, pos = matches:find('statement')
			matches:remove(pos)
		end

		-- warn if we still have more than one match
		if #matches > 1 then
			local str = ''
			for _,match in ipairs(matches) do
				str = str .. ' ' .. match
			end
			message('WARNING', 'A Div matches several statement kinds: '
				.. str .. '. Treated as kind '.. matches[1] ..'.')
		end

		-- extract custom label and info, if any



		-- kind must be modified if the statement has a custom label
		-- or has the 'unnumbered' class
		local new_kind

		-- return the first match, a key of `kinds`
		return matches[1]

	elseif type(elem) == 'table' then

		-- process DefinitionList items here
		-- they are table with two elements:
		-- [1] Inlines, the definiens
		-- [2] Blocks, the definiendum

	end

	return nil -- not a statement kind

end

--- extract_label: extract label and acronym from a statement Div.
--@TODO adapt to the class, use self.content
-- A label is a Strong element at the beginning of the Div, ending or 
-- followed by a dot. An acronym is between brackets, within the label
-- at the end of the label. If the label only contains an acronym,
-- it is used as label, brackets preserved.
-- if `acronym_mode` is set to false we do not search for acronyms. 
-- @param div a pandoc Div element (of class `statement`)
-- @param acronym_mode bool whether to search for an acronym
-- @param delimiters table acronym delimiters; default {'(',')'}
-- @return lab, acro, div, where`label` and `acronym` are Inlines or 
-- or nil, and `div` the pandoc Div element with label removed. 
function Statement:extract_label(div, acronym_mode, delimiters)

	if acronym_mode == false then else acronym_mode = true end
	if not delimiters or type(delimiters) ~= 'table' 
		or #delimiters ~= 2 then
			delimiters = {'(',')'}
	end

	local first_block, lab, acro = nil, nil, nil
	local has_label = false

	-- first block must be a Para that starts with a Strong element
	if not div.content[1] or div.content[1].t ~= 'Para' 
		or not div.content[1].content
		or div.content[1].content[1].t ~= 'Strong' then
			return nil, nil, div
	else
		first_block = div.content[1]:clone() -- Para element
		lab = first_block.content[1] -- Strong element
		first_block.content:remove(1) -- take the Strong elem out
	end

	-- the label must end by or be followed by a dot
	-- if a dot is found, take it out.
	-- ends by a dot?
	if lab.content[#lab.content] 
		and lab.content[#lab.content].t == 'Str'
		and lab.content[#lab.content].text:match('%.$') then
			-- remove the dot
			if lab.content[#lab.content].text:len() > 1 then
				lab.content[#lab.content].text =
					lab.content[#lab.content].text:sub(1,-2)
				has_label = true
			else -- special case: Str was just a dot
				lab.content:remove(#lab.content)
				-- remove trailing Space if needed
				if lab.content[#lab.content]
					and lab.content[#lab.content].t == 'Space' then
						lab.content:remove(#lab.content)
				end
				-- do not validate if empty
				if #lab.content > 0 then
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
	local saved_content = lab.content:clone()
	acro, lab.content = extract_first_bal_brackets(lab.content, 'reverse')
	if acro and #lab.content == 0 then
		acro, lab.content = nil, saved_content
	end

	-- remove trailing Space on the label if needed
	if #lab.content > 0 and lab.content[#lab.content].t == 'Space' then
		lab.content:remove(#lab.content)
	end

	-- remove leading Space on the first block if needed
	if first_block.content[1] 
		and first_block.content[1].t == 'Space' then
			first_block.content:remove(1)
	end

	-- return label, modified div if label found, original div otherwise
	if has_label then
		div.content[1] = first_block
		return lab, acro, div
	else
		return nil, nil, div
	end
end

--- extract_info: extra specified info from the statement's content.
-- Scans the content's first block for an info specification (Cite
-- or text within delimiters). If found, remove and place in the
-- statement's `info` field.
-- This should be run after extracting any custom label. 
function Statement:extract_info()

	-- first block must be Para or Plain
	if self.content and 
	  (self.content[1].t=='Para' or self.content[1].t=='Plain') then

	  	local first_block = self.content[1]:clone()
	  	local inf

		-- remove one leading space if any
		if first_block.content[1].t == 'Space' then
			first_block:remove(1)
		end

		-- info must be a Cite element, or bracketed content - not both
		if first_block.content[1].t == 'Cite' then
			inf = pandoc.Inlines(first_block.content[1])
			first_block.content:remove(1)
		else
			-- bracketed content?
			inf, first_block.content = 
				extract_first_bal_brackets(first_block.content)
		end

		-- if info found, save it and save the modified block
		if inf then
			self.info = inf
			self.content[1] = first_block
		end

	end

end

--- format_kind: format the statement's kind.
-- If the statement's kind is not yet define, create blocks to define
-- it in the desired output format. These blocks are added to
-- `header_includes` or returned to be added locally, depending
-- on the `options.define_in_header` setting.
-- @param kind string (optional) kind to be formatted, if not self.kind
-- @param format string (optional) format desired if other than FORMAT
-- @return blocks or nil, blocks to be added locally if any
function Statement:format_kind(kind, format)
	local blocks = pandoc.List:new()
	local format = format or FORMAT
	local kind = kind or self.kind

	-- check if the kind is already defined
	if kinds[kind].is_defined then
		return
	else
		kinds[kind].is_defined = true
	end

	-- do we have before_definitions_includes to include before any
	-- definition? if yes include it here and wipe it out
	if before_definitions_includes then
		blocks:extend(before_definitions_includes)
		before_definitions_includes = nil
	end

	-- format
	if format:match('latex') then
	
		local label = kinds[kind].label 
						or pandoc.Inlines(pandoc.Str(''))
		local counter = kinds[kind].counter or 'none'
		local shared_counter, counter_within

		-- identify counter_within and shared_counter
		if counter ~= 'none' and counter ~= 'self' then
			if type(counter)=='number' and LaTeX_levels[counter] then
				counter_within = LaTeX_levels[counter]
			elseif kinds[counter] then
				shared_counter = counter
			else -- unintelligible, default to 'self'
				message('WARNING', 'unintelligible counter for kind'
					.. kind '. Defaulting to `self`.')
				counter = 'self'
			end
		end
		-- if shared counter, its kind must be defined before
		if shared_counter then
			local extra_blocks = self:format_kind(shared_counter)
			if extra_blocks then
				blocks:extend(extra_blocks)
			end
		end

		-- amsthm provides `newtheorem*` for unnumbered kinds
		local latex_cmd = options.amsthm and counter == 'none' 
			and '\\newtheorem*' or '\\newtheorem'

		-- \newtheorem{kind}{label}
		-- \newtheorem{kind}[shared_counter]{label}
		-- \newtheorem{kind}{label}[counter_within]

		local inlines = pandoc.List:new()
		inlines:insert(
			pandoc.RawInline('latex', latex_cmd .. '{'
				.. kind ..'}')
		)
		if shared_counter then
			inlines:insert(
			  pandoc.RawInline('latex', '['..shared_counter..']')
			)
		end
		inlines:insert(pandoc.RawInline('latex','{'))
		inlines:extend(label)
		inlines:insert(pandoc.RawInline('latex','}'))
		if counter_within then
			inlines:insert(
			  pandoc.RawInline('latex', '['..counter_within..']')
			)
		end
		blocks:insert(pandoc.Plain(inlines))

	elseif format:match('html') then

	else -- any other format, no way to define statement kinds

	end

	-- place the blocks in header_includes or return them
	if options.define_in_header then
		header_includes:extend(blocks)
		return {}
	else
		return blocks
	end

end

--- format: format the statement.
-- @param format string (optional) format desired if other than FORMAT
-- @return Blocks blocks to be inserted. 
function Statement:format(format)
	local blocks = pandoc.List:new()
	local format = format or FORMAT

	-- format the kind if needed
	-- if local blocks are returned, insert them
	local format_kind_local_blocks = self:format_kind()
	if format_kind_local_blocks then
		blocks:extend(format_kind_local_blocks)
	end

	-- format the statement
	if format:match('latex') then

		-- \begin{kind}[info inlines] content blocks \end{kind}
		local inlines = pandoc.List:new()
		inlines:insert(pandoc.RawInline('latex', 
							'\\begin{' .. self.kind .. '}'))
		if self.info then
			inlines:insert(pandoc.RawInline('latex', '['))
			inlines:extend(self.info)
			inlines:insert(pandoc.RawInline('latex', ']'))
		end
		blocks:insert(pandoc.Plain(inlines))
		blocks:extend(self.content)
		blocks:insert(pandoc.RawBlock('latex',
							'\\end{' .. self.kind .. '}'))

	elseif format:match('html') then

	else -- other formats, use blockquote

		-- prepare the statement heading
		local heading = pandoc.List:new()
		if kinds[self.kind].label then
			local inlines = pandoc.List:new()
			inlines:extend(kinds[self.kind].label)
			inlines:insert(pandoc.Space())
			inlines:insert(pandoc.Str('1.1')) -- placeholder for the counter
			inlines:insert(pandoc.Str('.')) -- delimiter
			heading:insert(pandoc.Strong(inlines))
		end

		-- info?
		if self.info then 
			heading:insert(pandoc.Space())
			heading:insert(pandoc.Str('('))
			heading:extend(self.info)
			heading:insert(pandoc.Str(')'))
		end

		-- combine statement heading with the first paragraph if any
		if self.content[1] and self.content[1].t == 'Para' then
			heading:insert(pandoc.Space())
			heading:extend(self.content[1].content)
		end

		-- insert the heading as first paragraph of content
		if #heading > 0 then
			self.content:insert(1, pandoc.Para(heading))
		end

		-- place all the content blocks in blockquote
		blocks:insert(pandoc.BlockQuote(self.content))

	end

	return blocks

end
