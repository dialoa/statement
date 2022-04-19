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

	-- format_link_content: replace `<>` strings with crossref_label
	-- if no text, just put the crossref_label
	--@param content, inlines
	--@paramcrossref_label, inlines
	--@return inlines
	function format_link_content(content,label)
		if #content == 0 then
			return label
		end
		-- walk the content with a Str filter
		content = content:walk({
						Str = function(elem)
							if elem.text == '<>' then return label end
						end
					})
		return content
	end

	-- format_link_title: replace `<>` strings with crossref_label
	-- of provide a default link title.
	--@param title string, 
	--@param crossref_label inlines
	--@param kind_label string (optional), the kind's label
	--@return string
	function format_link_title(title,crossref_label, kind_label)
		crossref_label = stringify(crossref_label)
		if title ~= '' then
			title:gsub('<>',crossref_label)
			return title
		else
			if kind_label then
				title = stringify(kind_label) .. ' '
			end
			title = title..crossref_label
			return title
		end
	end

	filter.Link = function (link)

		if link.target:sub(1,1) == '#' then
			local target_id = link.target:sub(2,-1)
			if identifiers[target_id] then
				-- check that target is a statement
				-- note that if it was a duplicate id the statement's 
				-- new id has been stored in 'try_instead'
				local id = 	(identifiers[target_id].statement and target_id)
						or identifiers[target_id].try_instead
				if id then 
					link.target = '#'..id
					link.content = format_link_content(link.content,
										identifiers[target_id].crossref_label
										)
					link.title = format_link_title(link.title,
										identifiers[id].crossref_label,
										identifiers[id].kind_label
										)
					return link
				end
			end
		end
	end

	-- if citation syntax is enabled, add a Cite filter
	if self.setup.options.citations then
		filter.Cite = function(cite)

		local has_statement_ref, has_biblio_ref

			-- warn if the citations mix cross-label refs with standard ones
	    for _,citation in ipairs(cite.citations) do
	        if identifiers[citation.id] 
	           and (identifiers[citation.id].statement
	           		or identifiers[citation.id].try_instead) then
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

   		-- if statement crossreferences, turn Cite into
   		-- prefix Inlines Link suffix Inlines; ...
	    if has_statement_ref then

	        -- get style from the first citation
	        local bracketed = true 
	        if cite.citations[1].mode == 'AuthorInText' then
	            bracketed = false
	        end

	        local inlines = pandoc.List:new()

	        -- create (list of) citation(s)

	        for i = 1, #cite.citations do
	        	citation = cite.citations[i]
				-- was it a duplicated id with another id to try instead?
				local id = 	(identifiers[citation.id].statement and citation.id)
							or identifiers[citation.id].try_instead
				-- values to create link
				local target = '#'..id
				local content = identifiers[id].crossref_label 
								or pandoc.Inlines(pandoc.Str('??'))
				local title = format_link_title('', content,
						identifiers[id].kind_label)

				-- prefix first
				if #citation.prefix > 0 then
					inlines:extend(citation.prefix)
					inlines:insert(pandoc.Space())
				end
				-- then link
	          	inlines:insert(pandoc.Link(content, target, title))
	          	-- then suffix
				if #citation.suffix > 0 then
					inlines:insert(pandoc.Space())
					inlines:extend(citation.suffix)
				end

	            -- add separator if needed
	            if #cite.citations > 1 and i < #cite.citations then
	                inlines:extend({pandoc.Str(';'),pandoc.Space()})
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
