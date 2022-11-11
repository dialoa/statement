--- Statement:write_kind: write the statement's kind definition as output string.
-- If the statement's kind is not yet defined, create blocks to define it
-- in the desired output format. These blocks are added to
-- `self.setup.includes.header` or returned to be added locally, 
-- depending on the `setup.options.define_in_header` setting.
-- @param kind string (optional) kind to be formatted, if not kind
-- @param format string (optional) format desired if other than FORMAT
-- @return blocks or {}, blocks to be added locally if any
function Statement:write_kind(kind, format)
	local format = format or FORMAT
	local kind = kind or self.kind
	local counter = self.setup.kinds[kind].counter or 'none'
	local shared_counter, counter_within
	local blocks = pandoc.List:new() -- blocks to be written

	-- check if the kind is already written
	if self.setup.kinds[kind].is_written then
		return {}
	else
		self.setup.kinds[kind].is_written = true
	end

	-- identify counter_within and shared_counter
	if counter ~= 'none' and counter ~= 'self' then
		if self.setup.kinds[counter] then
			shared_counter = counter
		elseif self.setup:get_level_by_LaTeX_name(counter) then
			counter_within = counter
		elseif self.setup:get_LaTeX_name_by_level(counter) then
			counter_within = self.setup:get_LaTeX_name_by_level(counter)
		else -- unintelligible, default to 'self'
			message('WARNING', 'unintelligible counter for kind'
				..kind.. '. Defaulting to `self`.')
			counter = 'self'
		end
	end
	-- if shared counter, ensure its kind is defined before
	if shared_counter then
		blocks:extend(self:write_kind(shared_counter))
	end

	-- write the style definition if needed
	blocks:extend(self:write_style(self.setup.kinds[kind].style))

	-- format
	if format:match('latex') then
	
		local label = self.setup.kinds[kind].label 
						or pandoc.Inlines(pandoc.Str(''))

		-- in LaTeX we need to add the acronym in the label's definition
		if self.acronym then

			local acro_inlines = pandoc.List:new()
			acro_inlines:insert(pandoc.Str('('))
			acro_inlines:extend(self.acronym)
			acro_inlines:insert(pandoc.Str(')'))
			acro_inlines:insert(1, pandoc.Space())
			label = label:__concat(acro_inlines)

		end

		-- 'proof' statements are not defined
		if kind == 'proof' then
			-- nothing to be done

		else

			-- amsthm provides `newtheorem*` for unnumbered kinds
			local latex_cmd = self.setup.options.amsthm and counter == 'none' 
				and '\\newtheorem*' or '\\newtheorem'

			-- LaTeX command:
			-- \theoremstyle{style} (amsthm only)
			-- \newtheorem{kind}{label}
			-- \newtheorem{kind}[shared_counter]{label}
			-- \newtheorem{kind}{label}[counter_within]

			local inlines = pandoc.List:new()
			if self.setup.options.amsthm then
				inlines:insert(
					pandoc.RawInline('latex','\\theoremstyle{'
							.. self.setup.kinds[kind].style .. '}\n')
					)
			end
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

		end

	elseif format:match('html') then

	else -- any other format, no way to define statement kinds

	end

	-- place the blocks in header_includes or return them
	if self.setup.options.define_in_header then
		if not self.setup.includes.header then
			self.setup.includes.header = pandoc.List:new()
		end
		self.setup.includes.header:extend(blocks)
		return {}
	else
		return blocks
	end

end
