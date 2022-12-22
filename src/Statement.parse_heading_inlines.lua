--- Statement:parse_heading_inlines: parse statement heading inlines
-- into custom label, acronym, info if present, and extract
-- them from those inlines. Return them in a table.
-- @TODO: handle acronym-only statements
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
--		- a single bracketed content is assumed to be acronym rather than info.
-- Updates:
--		self.custom_label Inlines or nil, content of the label if found
--		self.acronym Inlines or nil, acronym
--		self.content Blocks, remainder of the statement after extraction
--@return table { acronym = Inlines or nil,
--								custom_label = Inlines or nil,
--								info = Inlines or nil
--								remainder = Inlines
--								}
--				or nil if no modification made
function Statement:parse_heading_inlines(inlines)
	local acro_delimiters = self.setup.options.acronym_delimiters 
											or {'(',')'} -- acronym delimiters
	local info_delimiters = self.setup.options.info_delimiters 
											or {'(',')'} -- info delimiters
	local custom_label, acronym, info

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
		result = self:trim_dot_space(result, 'reverse')

		-- Acronym is first content between balanced brackets
		-- encountered in forward order
		if #result > 0 then
			acro, result = self:extract_fbb(result, 'forward', acro_delimiters)
			self:trim_dot_space(result, 'forward')
		end

		-- Info is first Cite or content between balanced brackets 
		-- encountered in reverse order.
		if result[#result].t == 'Cite' then
			info = pandoc.Inlines(result[#result])
			result:remove(#result)
			result = self:trim_dot_space(result, 'reverse')
		else
			info, result = self:extract_fbb(result, 'reverse', info_delimiters)
			result = self:trim_dot_space(result, 'reverse')
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

	-- prevent modification of the source document by cloning
	if inlines and type(inlines) == 'Inlines' and #inlines > 0 then
		inlines = inlines:clone()
	else
		return
	end

	-- inlines start with Strong?
	-- if yes, try to parse and remove if successful
	if inlines[1].t == 'Strong' then
		info, custom_label, acronym = parse_Strong(inlines[1])
		if custom_label or info then
			inlines:remove(1)
			inlines = self:trim_dot_space(inlines, 'forward')
		end
	end

	-- if we don't have info yet, try to find it at the beginning
	-- of (what remains of) the Para's content.
	if not info then
		if inlines[1] and inlines[1].t == 'Cite' then
			info = pandoc.Inlines(inlines[1])
			inlines:remove(1)
			inlines = self:trim_dot_space(inlines, 'forward')
		else
			info, inlines = self:extract_fbb(inlines, 
																	'forward', info_delimiters)
			inlines = self:trim_dot_space(inlines, 'forward')
		end

	end

	-- return a table if we found anything
	if custom_label or info then
		return {
			acronym = acronym,
			custom_label = custom_label,
			info = info,
			remainder = #inlines>0 and inlines
									or nil
		}
	end

end
