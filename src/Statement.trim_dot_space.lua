---Statement:trim_dot_space: remove leading/trailing dot space in Inlines.
--@param inlines pandoc Inlines
--@param direction 'reverse' for trailing, otherwise leading
--@return result pandoc Inlines
function Statement:trim_dot_space(inlines, direction)
	local reverse = false
	if direction == 'reverse' then reverse = true end
	
	-- function to return first position in the desired direction
	function firstpos(list)
		return reverse and #list or 1
	end

	-- safety check
	if not inlines or #inlines == 0 then return inlines end

	-- remove sequences of spaces and dots
	local keep_looking = true
	while keep_looking do
		keep_looking = false
		if #inlines > 0 then
			if inlines[firstpos(inlines)].t == 'Space' then
				inlines:remove(firstpos(inlines))
				keep_looking = true
			elseif inlines[firstpos(inlines)].t == 'Str' then
				-- trim trailing dots and spaces from string text
				local str = inlines[firstpos(inlines)].text:match('(.*)[%.%s]+$')
				if str then
					if str == '' then
						inlines:remove(firstpos(inlines))
					else
						inlines[firstpos(inlines)].text = str
					end
					keep_looking = true
				end
			end
		end
	end

	return inlines
end
