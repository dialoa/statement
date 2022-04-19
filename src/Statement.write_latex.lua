---Statement.write_latex: write a statement in LaTeX
-- \begin{kind}[info inlines] 
--		[Link(identifier)] content blocks
--	\end{kind}
--@return Blocks
function Statement:write_latex()
	local blocks = pandoc.List:new()
	local id_span -- a Span element to give the statement an identifier

	-- if the element has an identifier, insert an empty identifier Span 
	if self.identifier then
		id_span = pandoc.Span({},pandoc.Attr(self.identifier))
		if self.content[1] and self.content[1] == 'Para' then
			self.content[1].content:insert(1, id_span)
		else
		self.content:insert(pandoc.Plain(id_span))
		end
	end

	-- \begin{kind}[info inlines] content blocks \end{kind}
	local inlines = pandoc.List:new()
	inlines:insert(pandoc.RawInline('latex', 
						'\\begin{' .. self.kind .. '}'))
	if self.info then
		inlines:insert(pandoc.RawInline('latex', '['))
		inlines:extend(self.info)
		inlines:insert(pandoc.RawInline('latex', ']'))
	end
	-- insert a span as link target if the statement has an identifier
	if self.identifier then
		inlines:insert(1, pandoc.Span({},pandoc.Attr(self.identifier)))
	end
	blocks:insert(pandoc.Plain(inlines))
	blocks:extend(self.content)
	blocks:insert(pandoc.RawBlock('latex',
						'\\end{' .. self.kind .. '}'))

	return blocks

end

