--- Statement:extract_fbb: extract the first content found between 
-- balanced brackets from an Inlines list, searching forward or 
-- backwards. Returns that content and the reminder, or nil and the 
-- original content.
-- @param inlines an Inlines list
-- @param direction string, 'reverse' or 'forward' search direction
-- @param delimiters table of beginning and ending delimiters, 
--		e.g. {'[',']'} for square brackets. Defaults to {'(',')'}
-- @return bracketed Inlines, Inlines bracketed content found, or nil
-- @return remainder Inlines, remainder of the content after extraction,
-- 		or all the content if nothing has been found.
function Statement:extract_fbb(inlines, direction, delimiters)

	-- check and load parameters
	local bb, eb = '(', ')'
	local reverse = false
	if type(inlines) ~= 'Inlines' or #inlines == 0 then
		return nil, inlines
	end
	if direction == 'reverse' then reverse = true end
	if delimiters and type(delimiters) == 'table' 
		and #delimiters == 2 then
			bb, eb = delimiters[1], delimiters[2]
	end
	-- in reverse mode swap around open and closing delimiters
	if reverse then
		bb, eb = eb, bb
	end

	-- functions to accomodate the direction of processing
	function first_pos(list)
		return reverse and #list or 1
	end
	function last_pos(list)
		return reverse and 1 or #list
	end
	function insert_last(list, item)
		if reverse then list:insert(1, item) else list:insert(item) end
	end
	function insert_first(list, item)
		if reverse then list:insert(item) else list:insert(1, item) end
	end
	function first_item(list) 
		return list[first_pos(list)]
	end
	function first_char(s)
		return reverse and s:sub(-1,-1) or s:sub(1,1)
	end
	function all_but_first_char(s)
		return reverse and s:sub(1,-2) or s:sub(2,-1)
	end
	function append_to_str(s, ch)
		return reverse and ch..s or s..ch
	end

	-- prepare return values
	local bracketed, rest = pandoc.List:new(), inlines:clone()

	-- check that we start (end, in reverse mode) 
	-- with a beginning delimiter. If yes remove it
	if first_item(rest).t ~= 'Str' 
		or first_char(first_item(rest).text) ~= bb then
			return nil, inlines
	else
		-- remove the delimiter. special case: Str is just the delimiter
		if first_item(rest).text == bb then
			rest:remove(first_pos(rest))
			-- remove leading/trailing space after bracket if needed
			if first_item(rest).t == 'Space' then
				rest:remove(first_pos(rest))
			end
		else -- standard case, bracket is just the first char of Str
			first_item(rest).text = all_but_first_char(
										first_item(rest).text)
		end
	end

	-- loop to go through all Str elements and find the balanced
	-- closing bracket
	local nb_brackets = 1

	while nb_brackets > 0 and #rest > 0 do

		-- extract first element
		local elem = first_item(rest)
		rest:remove(first_pos(rest))

		-- non Str elements are just stored in the bracketed content
		if elem.t ~= 'Str' then 
			insert_last(bracketed, elem)
		else
		-- Str elements: scan for brackets

			local str = elem.text
			local bracketed_part, outside_part = '', ''
			while str:len() > 0 do

				-- extract first char
				local char = first_char(str)
				str = all_but_first_char(str)

				-- have we found the closing bracket? if yes,
				-- store the reminder of the string without the bracket.
				-- if no, change the bracket count if needed and add the
				-- char to bracketed material
				if char == eb and nb_brackets == 1 then
					nb_brackets = 0
					outside_part = str
					break
				else
					if char == bb then
						nb_brackets = nb_brackets + 1
					elseif char == eb then
						nb_brackets = nb_brackets -1
					end
					bracketed_part = append_to_str(bracketed_part, char)
				end
			end

			-- store the bracketed part
			if bracketed_part:len() > 0 then
				insert_last(bracketed, pandoc.Str(bracketed_part))
			end
			-- if there is a part outside of the brackets,
			-- re-insert it in rest
			if outside_part:len() > 0 then
				insert_first(rest, pandoc.Str(outside_part))
			end

		end

	end

	-- if nb_bracket is down to 0, we've found balanced brackets content,
	-- otherwise return empty handed
	if nb_brackets == 0 then
		return bracketed, rest
	else
		return nil, inlines
	end

end
