---Statement.write_latex: write a statement in html
--@return Blocks
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
function Statement:write_html()
	local styles = self.setup.styles -- pointer to the styles table
	local style = self.setup.kinds[self.kind].style -- this statement's style
	local label_inlines, label_span, info_span 
	local heading_inlines, heading_span
	local attributes
	local blocks = pandoc.List:new()

	-- create label span; could be custom-label or kind label
	label_inlines = self:write_label() 
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
	attributes.classes:insert(style)
	if not self.is_numbered 
			and not attributes.classes:includes('unnumbered') then
		attributes.classes:insert('unnumbered')
	end

	-- create the statement Div and insert it
	blocks:insert(pandoc.Div(self.content, attributes))

	return blocks

end
