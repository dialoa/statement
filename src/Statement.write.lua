--- Statement:write: format the statement as an output string.
-- @param format string (optional) format desired if other than FORMAT
-- @return Blocks blocks to be inserted. 
function Statement:write(format)
	local blocks = pandoc.List:new()
	local format = format or FORMAT
	local kinds = self.setup.kinds -- pointer to the kinds table
	local label_inlines -- statement's label
	local label_delimiter = '.'

	-- do we have before_first includes to include before any
	-- definition? if yes include them here and wipe it out
	if self.setup.includes.before_first then
		blocks:extend(self.setup.includes.before_first)
		self.setup.includes.before_first = nil
	end

	-- write the kind definition if needed
	-- if local blocks are returned, insert them
	local write_kind_local_blocks = self:write_kind()
	if write_kind_local_blocks then
		blocks:extend(write_kind_local_blocks)
	end

	-- prepare the label inlines (only needed for non-LaTeX formats)
	label_inlines = self:write_label() or pandoc.List:new()
	-- insert a span in content as link target if the statement has an identifier
	if self.identifier then
		self.content[1].content:insert(1, pandoc.Span({},pandoc.Attr(self.identifier)))
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

	--elseif format:match('html') then

	else -- other formats, use blockquote

		-- prepare the statement heading
		local heading = pandoc.List:new()
		-- label?
		if #label_inlines > 0 then
			label_inlines:insert(pandoc.Str(label_delimiter))
			-- @TODO format according to statement kind
			heading:insert(pandoc.Strong(label_inlines))
		end

		-- info?
		if self.info then 
			heading:insert(pandoc.Space())
			heading:insert(pandoc.Str('('))
			heading:extend(self.info)
			heading:insert(pandoc.Str(')'))
		end

		-- insert heading
		-- combine statement heading with the first paragraph if any
		if #heading > 0 then
			if self.content[1] and self.content[1].t == 'Para' then
				heading:insert(pandoc.Space())
				heading:extend(self.content[1].content)
				self.content[1] = pandoc.Para(heading)
			else
				self.content:insert(1, pandoc.Para(heading))
			end
		end

		-- place all the content blocks in blockquote
		blocks:insert(pandoc.BlockQuote(self.content))

	end

	return blocks

end