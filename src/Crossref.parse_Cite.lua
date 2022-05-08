---Crossref:parse_Cite: tries to parse a Cite element
-- as a list of crossreferences.
-- Mixes of crossreferences and biblio (or others) aren't allowed.
-- See `Crossref.lua` for a definition of reference items.
-- Uses:
-- 	self.identifiers
--@param: elem, pandoc Cite element
--@return: table, list of reference items, or nil
function Crossref:parse_Cite(cite)
	local identifiers = self.identifiers

	-- Check whether citations include crossref and/or biblio refs
	local has_crossref, has_biblio_ref

  for _,citation in ipairs(cite.citations) do
  	local id, flags = self:parse_target(citation.id)
  	if identifiers[id] then 
  		-- apply redirect if needed
  		id = identifiers[id].redirect or id
  		-- record if we found a crossreference citation or another type
  		if identifiers[id].type == 'Statement' then
          has_crossref = true
      else
          has_biblio_ref = true
      end  		
  	else
  		has_biblio_ref = true
  	end
  end

  -- Return if it has biblio refs, with a warning if there was a mix.
  if has_biblio_ref then
  	if has_crossref then
	    message('WARNING', 'A citation mixes bibliographic references'
	        ..' with custom label references: '..stringify(cite.content))
	  end
    return
	end

	-- Otherwise build the references list
	references = pandoc.List:new()

	for _,citation in ipairs(cite.citations) do
		local ref = {}
  	ref.id, ref.flags = self:parse_target(citation.id)
  	-- apply redirect if needed
  	ref.id = identifiers[ref.id].redirect or ref.id
  	-- mode: `Normal` or `InText`
  	ref.mode = 	citation.mode == 'AuthorInText' and 'InText'
  							or citation.mode == 'NormalCitation' and 'Normal'
  							or nil
  	-- prefix and suffix
  	-- for uniformity with Links, space added
  	if #citation.prefix > 0 then
  		ref.prefix = citation.prefix:clone()
  		ref.prefix:insert(pandoc.Space())
  	end
  	if #citation.suffix > 0 then
  		ref.suffix = citation.suffix:clone()
  		ref.suffix:insert(1, pandoc.Space())
  	end

  	references:insert(ref)

	end

	return references

end
