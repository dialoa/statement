--- Statement:parse_Div_heading: parse Div heading into custom label,
-- acronym, info if present, and extract it from the content.
-- Expected format, where [...] means optional:
--		[**[[Acronym] Custom Label] [Info1].**] [Info2[.]] Content
--		[**[[Acronym] Custom Label] [Info1]**.] [Info2[.]] Content
-- Where:
--		- Acronym is Inlines delimited by matching parentheses, e.g. (NPE)
--		- Info1, Info2 are either Inlines delimited by matching 
--			parentheses, or a Cite element,
--		- only one of Info1 or Info2 is present. The latter is treated
--			as part of the content otherwise.
--		- single spaces before the heading or surrounding the dot
--			are tolerated.
-- Updates:
--		self.custom_label Inlines or nil, content of the label if found
--		self.acronym Inlines or nil, acronym
--		self.content Blocks, remainder of the statement after extraction
--@return nil 
function Statement:parse_Div_heading()
	local content = self.content
	local acro_delimiters = self.setup.options.acronym_delimiters 
											or {'(',')'} -- acronym delimiters
	local info_delimiters = self.setup.options.info_delimiters 
											or {'(',')'} -- info delimiters
	local para, custom_label, acronym, info
	local is_modified = false

	--- trim_dot_space: remove leading/trailing dot space.
	--@param inlines pandoc Inlines
	--@param direction 'reverse' for trailing, otherwise leading
	--@return result pandoc Inlines
	function trim_dot_space(inlines, direction)
		local reverse = false
		if direction == 'reverse' then reverse = true end
		
		-- function to return first position in the desired direction
		function firstpos(list)
			return reverse and #list or 1
		end

		-- safety check
		if #inlines == 0 then return inlines end

		-- remove space, dot, space
		if inlines[firstpos(inlines)].t == 'Space' then
			inlines:remove(firstpos(inlines))
		end
		if inlines[firstpos(inlines)].t == 'Str' 
				and inlines[firstpos(inlines)].text:match('%.$') then
			if inlines[firstpos(inlines)].text == '.' then
				inlines:remove(firstpos(inlines))
			else
				local str = inlines[firstpos(inlines)].text:match('(.*)%.$')
				inlines[firstpos(inlines)] = pandoc.Str(str)
			end
		end
		if inlines[firstpos(inlines)].t == 'Space' then
			inlines:remove(firstpos(inlines))
		end
		return inlines
	end

	--- parse_Strong: try to parse a Strong element into acronym,
	-- label and info.
	-- @param elem pandoc Strong element
	-- @return info, Inlines or Cite information if found
	-- @return cust_lab, Inlines custom label if found
	-- @return acronym, Inlines, acronym if found
	function parse_Strong(elem)
		-- must clone to avoid changing the original element 
		-- in case parsing fails
		local result = elem.content:clone()
		local info, cust_lab, acro

		-- remove trailing space / dot
		result = trim_dot_space(result, 'reverse')

		-- Info is first Cite or content between balanced brackets 
		-- encountered in reverse order.
		if result[#result].t == 'Cite' then
			info = pandoc.Inlines(result[#result])
			result:remove(#result)
			result = trim_dot_space(result, 'reverse')
		else
			info, result = self:extract_fbb(result, 'reverse', info_delimiters)
			result = trim_dot_space(result, 'reverse')
		end

		-- Acronym is first content between balanced brackets
		-- encountered in forward order
		if #result > 0 then
			acro, result = self:extract_fbb(result, 'forward', acro_delimiters)
			trim_dot_space(result, 'forward')
		end
			
		-- Custom label is whatever remains
		if #result > 0 then
			cust_lab = result
		end

		-- If we have acro but not cust_label that's a failure
		if acro and not cust_lab then
			return nil, nil, nil
		else
			return info, cust_lab, acro
		end
	end

	-- FUNCTION BODY

	-- the first block must be a Para; we clone it for processing
	if content[1] and content[1].t and content[1].t == 'Para' then
		para = content[1]:clone()
	else
		return
	end

	-- Para starts with Strong?
	-- if yes, try to parse and remove if successful
	if para.content and para.content[1].t == 'Strong' then
		info, custom_label, acronym = parse_Strong(para.content[1])
		if custom_label or info then
			para.content:remove(1)
			para.content = trim_dot_space(para.content, 'forward')
		end
	end


	-- if we don't have info yet, try to find it at the beginning
	-- of (what remains of) the Para's content.
	if not info then
		if para.content[1] and para.content[1].t == 'Cite' then
			info = pandoc.Inlines(para.content[1])
			para.content:remove(1)
			para.content = trim_dot_space(para.content, 'forward')
		else
			info, para.content = self:extract_fbb(para.content, 
																	'forward', info_delimiters)
			para.content = trim_dot_space(para.content, 'forward')
		end

	end

	-- if we found anything, store components and update statement's 
	-- first block.
	if custom_label or info then
		if acronym then
			self.acronym = acronym
		end
		self.custom_label = custom_label
		self.info = info
		self.content[1] = para
	end

end
