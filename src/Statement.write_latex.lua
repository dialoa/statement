---Statement.write_latex: write a statement in LaTeX
-- \begin{kind}[info inlines] 
--		[Link(identifier)] content blocks
--	\end{kind}
--@return Blocks
function Statement:write_latex()
	local blocks = pandoc.List:new()
	local id_span -- a Span element to give the statement an identifier
	local style_def = self.setup.styles[self.setup.kinds[self.kind].style]

	-- we start with Plain block `\begin{...}[info]\hypertarget'
	local inlines = pandoc.List:new()
	inlines:insert(pandoc.RawInline('latex', 
						'\\begin{' .. self.kind .. '}'))
	-- if info, insert in brackets
	if self.info then
		inlines:insert(pandoc.RawInline('latex', '['))
		inlines:extend(self.info)
		inlines:insert(pandoc.RawInline('latex', ']'))
	end
	-- if the element has an identifier, insert an empty identifier Span 
	if self.identifier then
		inlines:insert(pandoc.Span({},pandoc.Attr(self.identifier)))
	end
	-- if the blocks start with a list and has a label, 
	-- amsthm needs to be told to start a newline
	-- if the style has a linebreak already, needs a negative baselineskip too
	if self.content[1] and self.content[1].t
		  and (self.label or self.custom_label)
			and (self.content[1].t == 'BulletList' or self.content[1].t == 'OrderedList'
				or self.content[1].t == 'DefinitionList') then
		inlines:insert(pandoc.RawInline('latex', '\\leavevmode'))
		if style_def.linebreak_after_head then
			inlines:insert(pandoc.RawInline('latex', '\\vspace{-\\baselineskip}'))
		end
	end
	-- insert \begin{...}[...] etc. as Plain block
	blocks:insert(pandoc.Plain(inlines))

	-- main content
	blocks:extend(self.content)

	-- close
	blocks:insert(pandoc.RawBlock('latex',
						'\\end{' .. self.kind .. '}'))

	return blocks

end

