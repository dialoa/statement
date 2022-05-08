---Crossref:process: processes crossreferences in
-- a Pandoc Link or Cite, if present.
-- See `Crossref.lua` for the definition `references` lists.
function Crossref:process(elem)
	if elem and elem.t then
		
		local references

		if elem.t == 'Link' then
			references = self:parse_Link(elem)
		elseif elem.t == 'Cite' then
			references = self:parse_Cite(elem)
		end

		if references then
			return self:write(references)
		end
		
	end
end
