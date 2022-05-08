---Crossref:parse_Link: tries to parse a Link element  
-- as a crossreference. 
-- See `Crossref.lua` for a definition of reference items.
-- Uses:
--	self.identifiers
--@param: elem, pandoc Link element
--@return: table, list of (one) reference item or nil
function Crossref:parse_Link(link)
	local identifiers = self.identifiers
	local id, flags

	---parse_link_content: parses link content into
	-- prefix and suffix or custom text.
	-- The first <>, if any, says where the automatic text
	-- goes. Non-empty text without <> is a custom text.
	-- Examples:
	-- '' -> prefix = nil, suffix = nil, text = nil
	-- 'this statement' ->  text = 'this statement', prefix,suffix = nil,nil
	-- 'as in <>' -> prefix 'as in ', suffix,text = nil,nil
	-- 'as in (<>)' -> prefix 'as in (', suffix = ')', text = nil
	-- 'see (<>) above' -> prefix 'see (', suffix = ') above', text = nil
	-- Uses:
	--	self.identifires
	--@param: inlines, text of the link
	--@return: table, list of (one) reference item
	local function parse_link_content(inlines)
		local text, prefix, suffix

		if #inlines > 0 then
			text = pandoc.List:new()
			-- by default, insert elements in the custom text
			-- but if we find <>, put what we have in prefix
			-- and the rest in suffix.
			for i = 1, #inlines do
				if inlines[i].t == 'Str'
						and inlines[i].text:match('<>') then
					-- put what we have so far in prefix, 
					-- the rest in suffix
					prefix = text
					text = nil
					suffix = pandoc.List:new()
					for j = i+1, #inlines do
						suffix:insert(inlines[j])
					end
					-- split the string if needed
					s,e = inlines[i].text:find('<>')
					if s > 1 then 
						prefix:insert(pandoc.Str(inlines[i].text:sub(1,s-1)))
					end
					if e < #inlines[i].text then
						suffix:insert(1, pandoc.Str(inlines[i].text:sub(e+1,-1)))
					end
					break

				else

					text:insert(inlines[i])

				end
			end
		end

		return text, prefix, suffix
	end

	-- MAIN FUNCTION BODY

	-- Check whether the link is crossref and set id
	local is_crossref = false
	if link.target:sub(1,1) == '#' then
		id, flags = self:parse_target(link.target:sub(2,-1))
		if identifiers[id] then
			-- redirect if needed
			id = identifiers[id].redirect or id
			-- check whether the target is a statement
			if identifiers[id].type == 'Statement' then
				is_crossref = true
			end
		end
	end

	-- parse a crossreference if found
	if is_crossref then
		local ref = {}
		ref.id = id
		ref.flags = flags
		ref.mode = 'InText'
		ref.text, ref.prefix, ref.suffix =	parse_link_content(link.content)
		ref.title = link.title ~= '' and link.title or nil

		return { ref }
	end
end
