---Statement:parse_indentifier find and extract a \label{...}
-- or {#...} identifier from Inlines
function Statement:parse_identifier(inlines)
	local id -- string, identifier
	local result

	--pick_id: a filter to pick ids in RawInlines or Str
	local pick_id = {
		RawInline = function(elem)
			id = elem.text:match('^\\label{(%g+)}$')
			if id then return {} end
		end,
		Str = function(elem)
			id = elem.text:match('^{#(%g+)}$')
			if id then return {} end
		end,
	}

	if inlines and type(inlines) == 'Inlines' and #inlines > 0 then

		-- prevent modification of the source document by cloning
		-- and apply the filter
		result = inlines:clone():walk(pick_id)
		-- if something found, return the identifier and modified inlines
		if id then
			return id, result
		end

	end
end