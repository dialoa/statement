--- Statement:write_kind: write the statement's style definition as output string.
-- If the statement's style is not yet defined, create blocks to define it
-- in the desired output format. These blocks are added to
-- `self.setup.includes.before_first` or returned to be added locally, 
-- depending on the `setup.options.define_in_header` setting.
-- @param kind string (optional) kind to be formatted, if not self.kind
-- @param format string (optional) format desired if other than FORMAT
-- @return blocks or {}, blocks to be added locally if any
function Statement:write_style(style, format)
	local format = format or FORMAT
	local length_format = Helpers.length_format
	local font_format = Helpers.font_format
	local styles = self.setup.styles -- points to the styles table
	local style = style or self.setup.kinds[self.kind].style
	local blocks = pandoc.List:new() -- blocks to be written

	-- check if the style is already written or not to be defined
	if styles[style].is_written 
			or styles[style]['do_not_define_in_'..format] then
		return {}
	else
		styles[style].is_written = true
	end

	-- format
	if format:match('latex') then

		-- special case: proof environement
		-- with amsthm this is already defined, we only set \proofname
		-- without we must provide the environement and \proofname
		if style == 'proof' then
			local LaTeX_command = ''
			if not self.setup.options.amsthm then
				 LaTeX_command = LaTeX_command ..
[[\makeatletter
\ifx\proof\undefined
\newenvironment{proof}[1][\protect\proofname]{\par
	\normalfont\topsep6\p@\@plus6\p@\relax
	\trivlist
	\itemindent\parindent
	\item[\hskip\labelsep\itshape #1.]\ignorespaces
}{%
	\endtrivlist\@endpefalse
}
\fi
\makeatother
]]
			end
			if self.setup.LOCALE[self.setup.options.language]['proof'] then
				LaTeX_command = LaTeX_command 
							.. '\\providecommand{\\proofname}{'
							.. self.setup.LOCALE[self.setup.options.language]['proof']
							.. '}'
			else
				LaTeX_command = LaTeX_command 
							.. '\\providecommand{\\proofname}{Proof}'
			end
			blocks:insert(pandoc.RawBlock('latex', LaTeX_command))

		-- \\theoremstyle requires amsthm
		-- normal style, use \\theoremstyle if amsthm
		elseif self.setup.options.amsthm then

			-- LaTeX command
			-- \\\newtheoremstyle{stylename}
			-- 		{length} space above
			-- 		{length} space below
			-- 		{command} body font
			-- 		{length} indent amount
			-- 		{command} theorem head font
			--		{string} punctuation after theorem head
			--		{length} space after theorem head
			--		{pattern} theorem heading pattern
			local style_def = styles[style]
			local space_above = length_format(style_def.margin_top) or '0pt'
			local space_below = length_format(style_def.margin_bottom) or '0pt'
			local margin_right = length_format(style_def.margin_right)
			local margin_left = length_format(style_def.margin_left)
			local body_font = font_format(style_def.body_font) or ''
			if margin_right then
				body_font = '\\addtolength{\\rightskip}{'..style_def.margin_left..'}'
										..body_font
			end
			if margin_left then
				body_font = '\\addtolength{\\leftskip}{'..style_def.margin_left..'}'
										..body_font
			end
			local indent = length_format(style_def.indent) or ''
			local head_font = font_format(style_def.head_font) or ''
			local punctuation = style_def.punctuation or ''
			-- NB, space_after_head can't be '' or LaTeX crashes. use ' ' or '0pt'
			local space_after_head = style_def.linebreak_after_head and '\\newline'
															or length_format(style_def.space_after_head) 
															or ' '
			local heading_pattern = style_def.heading_pattern or ''
			local LaTeX_command = '\\newtheoremstyle{'..style..'}'
										..'{'..space_above..'}'
										..'{'..space_below..'}'
										..'{'..body_font..'}'
										..'{'..indent..'}'
										..'{'..head_font..'}'
										..'{'..punctuation..'}'
										..'{'..space_after_head..'}'
										..'{'..heading_pattern..'}\n'
			blocks:insert(pandoc.RawBlock('latex',LaTeX_command))

		end
	
	elseif format:match('html') then

		-- CSS specification 
		-- @TODO: handle linebreak_after_head
		-- .statement.<style> {
		--			margin-top:
		--			margin-bottom:
		--			margin-left:
		--			margin-right:
		--			[font-style,-weight,-variant]: body font
		--			}	
		-- .statement.<style> .statement-label {
		--			[font-style,-weight,-variant]: head font
		-- 		}
		-- .statement.<style> .statement-info {
		--			[font-style,-weight,-variant]: normal
		--	}
		--@TODO: handle indent, 'text-ident' on the first paragraph only, before heading
		--@TODO: handle space after theorem head. Need to use space chars???
		local style_def = styles[style]
		local margin_top = length_format(style_def.margin_top)
		local margin_bottom = length_format(style_def.margin_bottom)
		local margin_right = length_format(style_def.margin_right)
		local margin_left = length_format(style_def.margin_left)
		local body_font = font_format(style_def.body_font)
		local head_font = font_format(style_def.head_font)
		-- make sure head and info aren't affected by body_font
		if body_font then
			head_font = head_font or ''
			head_font = 'font-style: normal; font-weight: normal;'
									..' font-variant: normal; '..head_font
		end
		local indent = length_format(style_def.indent) or ''
		-- local punctuation = style_def.punctuation HANDLED BY WRITE
		local linebreak_after_head, space_after_head
		if style_def.linebreak_after_head then
			linebreak_after_head = true
		else
			space_after_head = length_format(style_def.space_after_head) 
														or '0.333em'
		end
		--local heading_pattern = style_def.heading_pattern or ''

		local css_spec = ''

		if margin_top or margin_bottom or margin_left or margin_right
				or body_font then
			css_spec = css_spec..'.statement.'..style..' {\n'
			if margin_top then
				css_spec = css_spec..'\tmargin-top: '..margin_top..';\n'
			end
			if margin_bottom then
				css_spec = css_spec..'\tmargin-bottom: '..margin_bottom..';\n'
			end
			if margin_left then
				css_spec = css_spec..'\tmargin-left: '..margin_left..';\n'
			end
			if margin_right then
				css_spec = css_spec..'\tmargin-right: '..margin_right..';\n'
			end
			if body_font then
				css_spec = css_spec..'\t'..body_font..'\n'
			end
			css_spec = css_spec..'}\n'
		end
		if head_font then
			css_spec = css_spec..'.statement.'..style..' .statement-label {\n'
			css_spec = css_spec..'\t'..head_font..'\n'
			css_spec = css_spec..'}\n'
		end
		if indent ~= '' then
			css_spec = css_spec..'.statement.'..style..' p:first-child {\n'
			css_spec = css_spec..'\t text-indent: '..indent..';\n'
			css_spec = css_spec..'}\n'
		end
		-- linebreak after heading or space after heading
		-- linebreak after heading: use '\a' and white-space: pre
		-- space after heading: use word-spacing
		if linebreak_after_head then
			css_spec = css_spec..'.statement.'..style..' .statement-spah:after {\n'
			css_spec = css_spec.."\tcontent: '\\a';\n"
			css_spec = css_spec..'\twhite-space: pre;\n'
			css_spec = css_spec..'}\n'
		elseif space_after_head then
			css_spec = css_spec..'.statement.'..style..' .statement-spah {\n'
			css_spec = css_spec..'\tword-spacing: '..space_after_head..';\n'
			css_spec = css_spec..'}\n'
		end

		-- info style: always clean (as in AMS theorems)
		css_spec = css_spec..'.statement.'..style..' .statement-info {\n'
		css_spec = css_spec..'\t'..'font-style: normal; font-weight: normal;'
									..' font-variant: normal;\n'
		css_spec = css_spec..'}\n'




		-- wrap all in <style> tags
		css_spec = '<style>\n'..css_spec..'</style>\n'

		-- insert
		blocks:insert(pandoc.RawBlock('html',css_spec))

	else -- any other format, no way to define statement kinds

	end

	-- place the blocks in header_includes or return them
	if #blocks == 0 then
		return {}
	elseif self.setup.options.define_in_header then
		if not self.setup.includes.header then
			self.setup.includes.header = pandoc.List:new()
		end
		self.setup.includes.header:extend(blocks)
		return {}
	else
		return blocks
	end

end
