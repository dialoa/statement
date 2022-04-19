---Statement.write_latex: write a statement in Pandoc native
-- We wrap the statement in a Blockquote
--@return Blocks
function Statement:write_native()
	local styles = self.setup.styles -- pointer to the styles table
	local style = self.setup.kinds[self.kind].style -- this statement's style
	--@TODO implement font format functions
	local label_format = function(inlines) return inlines end
	local body_format = function(inlines) return inlines end
	local blocks = pandoc.List:new()


	-- if the element has an identifier, insert an empty identifier Span 
	if self.identifier then
		id_span = pandoc.Span({},pandoc.Attr(self.identifier))
		if self.content[1] and self.content[1] == 'Para' then
			self.content[1].content:insert(1, id_span)
		else
		self.content:insert(pandoc.Plain(id_span))
		end
	end

	-- create label span; could be custom-label or kind label
	label_inlines = self:write_label() 
	if #label_inlines > 0 then
		label_span = pandoc.Span(label_inlines, 
											{class = 'statement-label'})
	end

	-- prepare the statement heading
	local heading = pandoc.List:new()

	-- label?
	label_inlines = self:write_label() 
	if #label_inlines > 0 then
		if styles[style].punctuation then
			label_inlines:insert(pandoc.Str(
				styles[style].punctuation
				))
		label_inlines = label_format(label_inlines)
		end
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

	-- style body
	self.content = body_format(self.content)

	-- place all the content blocks in blockquote
	blocks:insert(pandoc.BlockQuote(self.content))

	return blocks

end
