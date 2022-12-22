--- Statement:write_remove_qedhere remove the `\qedhere`
-- LaTeX command within a statement's content.
-- 
-- @param blocks Pandoc blocks list
-- @return blocks the modified blocks
function Statement:write_remove_qedhere(blocks)

	-- remove QED here for an element's `text` field
	-- if the element has a `format` attribute, check if it's `tex`
	local function rm_qedhere(el)
		if el.format and el.format ~= 'tex' then
			return 
		end 
    el.text = el.text:gsub('\\mbox{\\qedhere}', '')
    el.text = el.text:gsub('\\qedhere','')
    return el
  end
	
	local filter = {
		Math = rm_qedhere,
		RawInline = rm_qedhere,
		RawBlock = rm_qedhere,
	}

	return pandoc.walk_block(pandoc.Div(blocks), filter).content

end