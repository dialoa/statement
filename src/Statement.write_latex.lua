---Statement.write_latex: write a statement in LaTeX
-- \begin{kind}[info inlines] 
--		[Link(identifier)] content blocks
--	\end{kind}
--@return Blocks
function Statement:write_latex()
	local blocks = pandoc.List:new()
	local id_span -- a Span element to give the statement an identifier

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
	blocks:insert(pandoc.Plain(inlines))

	-- main content
	blocks:extend(self.content)

	-- close
	blocks:insert(pandoc.RawBlock('latex',
						'\\end{' .. self.kind .. '}'))

	return blocks

end

