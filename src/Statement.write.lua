--- Statement:write: format the statement as an output string.
-- @param format string (optional) format desired if other than FORMAT
-- @return Blocks blocks to be inserted. 
function Statement:write(format)
	local format = format or FORMAT
	local kinds = self.setup.kinds -- pointer to the kinds table
	local styles = self.setup.styles -- pointer to the styles table
	local style = kinds[self.kind].style -- this statement's style
	local label_inlines -- statement's label
	local label_delimiter = '.'
	local blocks = pandoc.List:new()

	-- do we have before_first includes to include before any
	-- definition? if yes include them here and wipe it out
	if self.setup.includes.before_first then
		blocks:extend(self.setup.includes.before_first)
		self.setup.includes.before_first = nil
	end

	-- do we need to write the kind definition first?
	-- if local blocks are returned, insert them
	local write_kind_local_blocks = self:write_kind()
	if write_kind_local_blocks then
		blocks:extend(write_kind_local_blocks)
	end

	-- prepare the label inlines
	-- This is actually only needed for non-latex formats, since
	-- in LaTeX the label is part of the kind definition
	if not format:match('latex') then
		label_inlines = self:write_label() or pandoc.List:new()
	end

	-- format the statement

	-- LaTeX formatting
	if format:match('latex') then

		-- insert a span in content as link target if the statement has an identifier
		if self.identifier then
			self.content[1].content:insert(1, pandoc.Span({},pandoc.Attr(self.identifier)))
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

	-- HTML formatting
	-- we create a Div
	--	<div class='statement <kind> <style>'>
	-- 	<p class='statement-first-paragraph'>
	--		<span class='statement-head'>
	--			<span class='statement-label'> label inlines </span>
	--		  <span class='statement-info'>( info inlines )</span>
	--			<span class='statement-spah'> </span>
	--		first paragraph content, if any
	--	</p>
	--  content blocks
	-- </div>
	elseif format:match('html') then

		local label_span, info_span 
		local heading_inlines, heading_span
		local attributes

		-- create label span; could be custom-label or kind label
		if #label_inlines > 0 then
			label_span = pandoc.Span(label_inlines, 
												{class = 'statement-label'})
		end
		-- create info span
		if self.info then 
			self.info:insert(1, pandoc.Str('('))
			self.info:insert(pandoc.Str(')'))
			info_span = pandoc.Span(self.info, 
											{class = 'statement-info'})
		end
		-- put heading together
		if label_span or info_span then
			heading_inlines = pandoc.List:new()
			if label_span then
				heading_inlines:insert(label_span)
			end
			if label_span and info_span then
				heading_inlines:insert(pandoc.Space())
			end
			if info_span then
				heading_inlines:insert(info_span)
			end
			-- insert punctuation defined in style
			if styles[style].punctuation then
				heading_inlines:insert(pandoc.Str(
					styles[style].punctuation
					))
			end
			heading_span = pandoc.Span(heading_inlines,
										{class = 'statement-heading'})
		end

		-- if heading, insert it in the first paragraph if any
		-- otherwise make it its own paragraph
		if heading_span then
			if self.content[1] and self.content[1].t 
					and self.content[1].t == 'Para' then
				self.content[1].content:insert(1, heading_span)
				-- add space after heading
				self.content[1].content:insert(2, pandoc.Span(
											{pandoc.Space()}, {class='statement-spah'}
					))
			else
				self.content:insert(1, pandoc.Para({heading_span}))
			end
		end

		-- prepare Div attributes
		-- keep the original element's attributes if any
		attributes = self.element.attr or pandoc.Attr()
		if self.identifier then
				attributes.identifier = self.identifier
		end
		-- add the `statement`, kind, style and unnumbered classes
		-- same name for kind and style shouldn't be a problem
		attributes.classes:insert('statement')
		attributes.classes:insert(self.kind)
		attributes.classes:insert(kinds[self.kind].style)
		if not self.is_numbered 
				and not attributes.classes:includes('unnumbered') then
			attributes.classes:insert('unnumbered')
		end

		-- create the statement Div and insert it
		blocks:insert(pandoc.Div(self.content, attributes))

	-- JATS formatting
	-- Pandoc's JATS writer turns Plain blocks in to <p>...</p>
	-- for this reason we must write <label> and <title> inlines
	-- to text before we insert them.
	elseif format:match('jats') then

		--write_to_jats: use pandoc to convert inlines to jats output
		--@BUG this needs the document meta, otherwise biblio not found 
		function write_to_jats(inlines)
			local result, doc
			local options = pandoc.WriterOptions({
					cite_method = PANDOC_WRITER_OPTIONS.cite_method
			})
			doc = pandoc.Pandoc(pandoc.Plain(inlines))
			result = pandoc.write(doc, 'jats', options)
			return result:match('^<p>(.*)</p>$') or result or ''

		end

		blocks:insert(pandoc.RawBlock('jats', '<statement>'))

		if #label_inlines > 0 then
			local label_str = '<label>'..write_to_jats(label_inlines) 
												..'</label>'
			blocks:insert(pandoc.RawBlock('jats',label_str))
		end

		if self.info then
			local info_str = 	'<title>'..write_to_jats(self.info)
												..'</title>'
			blocks:insert(pandoc.RawBlock('jats',info_str))
		end

		blocks:extend(self.content)

		blocks:insert(pandoc.RawBlock('jats', '</statement>'))

	else -- other formats, use blockquote

		-- insert a span in content as link target if the statement has an identifier
		if self.identifier then
			self.content[1].content:insert(1, pandoc.Span({},pandoc.Attr(self.identifier)))
		end

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