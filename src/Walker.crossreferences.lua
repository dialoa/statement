---Walker:crossreferences: creates a Blocks filter to 
-- handle crossreferences.
-- Links with empty content get crossref_label as their content
-- Uses:
--	self.setup.options.citations: whether to use citation syntax
-- Uses and updates:
-- 	self.blocks, the document's blocks
--@param blocks blocks to be processed
--@return nil
function Walker:crossreferences()
	local identifiers = self.setup.identifiers -- pointer to identifiers table
	local filter = {}

	filter.Link = function (link)
		if #link.content == 0 and link.target:sub(1,1) == '#' then
			local target_id = link.target:sub(2,-1)
			if identifiers[target_id] 
					and identifiers[target_id].statement == true then
				link.content = identifiers[target_id].crossref_label or link.content
				return link
			end
		end
	end

	-- if citation syntax is enabled, add a Cite filter
	if self.setup.options.citations then
		filter.Cite = function(cite)

			local has_statement_ref, has_biblio_ref

			-- warn if the citations mix cross-label refs with standard ones
	    for _,citation in ipairs(cite.citations) do
	        if identifiers[citation.id] then
	            has_statement_ref = true
	        else
	            has_biblio_ref = true
	        end
	    end
	    if has_statement_ref and has_biblio_ref then
        message('WARNING', 'A citation mixes bibliographic references \
            with custom label references '
            .. pandoc.utils.stringify(cite.content) )
        return
   		end

   		-- if statement crossreferences, turn Cite into Link(s)
	    if has_statement_ref then

        -- get style from the first citation
        local bracketed = true 
        if cite.citations[1].mode == 'AuthorInText' then
            bracketed = false
        end

        local inlines = pandoc.List:new()

        -- create link(s)

        for i = 1, #cite.citations do
           inlines:insert(pandoc.Link(
                identifiers[cite.citations[i].id].crossref_label,
                '#' .. cite.citations[i].id
            ))
            -- add separator if needed
            if #cite.citations > 1 and i < #cite.citations then
                inlines:insert(pandoc.Str('; '))
            end
        end

        -- adds brackets if needed
        if bracketed then
            inlines:insert(1, pandoc.Str('('))
            inlines:insert(pandoc.Str(')'))
        end

        return inlines

	    end -- end of `if has_statement_ref...`
		end -- end of filter.Cite function
	end -- end of `if self.setup.options.citations ...`

	return filter

end
