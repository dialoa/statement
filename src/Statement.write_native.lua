---Statement.write_latex: write a statement in Pandoc native
-- We wrap the statement in a Div
--@return Blocks
function Statement:write_native()
	local font_format_native = Helpers.font_format_native
	-- pick the style definition for punctuation, linebreak after head...
	local style_def = self.setup.styles[self.setup.kinds[self.kind].style]
	-- convert font definitions into formatting functions
	local label_format = font_format_native(style_def.head_font)
	local body_format = font_format_native(style_def.body_font)
	local label_inlines, heading_inlines

	-- local debug_inlines = label_format(pandoc.Para(pandoc.Str('test'))) 
	-- local debug_blocks = pandoc.Blocks(debug_inlines)

	-- print(pandoc.write(pandoc.Pandoc(debug_blocks), 'html'))

	-- create label span; could be custom-label or kind label
	label_inlines = self:write_label() 
	if #label_inlines > 0 then
		label_span = pandoc.Span(label_inlines, 
											{class = 'statement-label'})
	end

	-- prepare the statement heading inlines
	local heading = pandoc.List:new()
	-- label?
	label_inlines = self:write_label()
	if #label_inlines > 0 then
		if style_def.punctuation then
			label_inlines:insert(pandoc.Str(style_def.punctuation))
		end
--		print(pandoc.write(pandoc.Pandoc(pandoc.Plain(label_inlines))))
		label_inlines = label_format(label_inlines)
--		print(pandoc.write(pandoc.Pandoc(pandoc.Plain(label_inlines))))
		label_inlines = pandoc.Span(label_inlines, {class = 'statement-label'})
		heading:insert(label_inlines)
	end

	-- info?
	if self.info then
		if #heading > 0 then
			heading:insert(pandoc.Space())
		end
		heading:insert(pandoc.Str('('))
		heading:extend(self.info)
		heading:insert(pandoc.Str(')'))
	end

	-- style body
	-- must be done before we insert the heading to ensure
	-- that body_format isn't applied to the heading.
--	print(pandoc.write(pandoc.Pandoc(self.content)))
	self.content = body_format(self.content)
--	print(pandoc.write(pandoc.Pandoc(self.content)))

	-- insert heading
	-- combine statement heading with the first paragraph if any
	-- take care of linebreak after head
	if #heading > 0 then
		if self.content[1] and self.content[1].t == 'Para' then
			if style_def.linebreak_after_head then
				heading:insert(pandoc.LineBreak())
			else
				heading:insert(pandoc.Space())
			end
			heading:extend(self.content[1].content)
			self.content[1] = pandoc.Para(heading)
		else
			self.content:insert(1, pandoc.Para(heading))
		end
	end

	-- if the element has an identifier, insert an empty identifier Span 
	if self.identifier then
		id_span = pandoc.Span({},pandoc.Attr(self.identifier))
		if self.content[1] 
				and (self.content[1].t == 'Para' 
						or self.content[1].t == 'Plain') then
			self.content[1].content:insert(1, id_span)
		else
			self.content:insert(pandoc.Plain(id_span))
		end
	end

	-- place all the content blocks in Div
	return pandoc.Blocks(pandoc.Div(self.content))

end