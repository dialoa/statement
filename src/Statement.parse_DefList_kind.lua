---Statement:parse_DefList_kind: extracts the kind from a DefList, if any
-- A DefinitionList item is a statement if its defined expression starts
-- with a Str element whose text matches a statement kind (or alias).
--@param item item of DefinitionList element
--@return string or nil element's kind (key of `setup.kinds`) or nil
--@return item the modified DefinitionList item
function Statement:parse_DefList_kind(item)
	setup = setup or self.setup -- pointer to the setup table
	local kinds = setup.kinds -- pointer to the kinds table
	item = item or self.element 
					and self.element.t == 'DefinitionList' 
					and self.element.content[1]
	local expression -- Inlines expression defined, i.e. item[1]
	local kind -- kind key, if found
	--local new_item -- modified item

	if item then

		expression = item[1]
		if expression[1].t and expression[1].t == 'Str' then

			-- check that it does match a kind
			-- ignore any dot at the end of the string
			local str = expression[1].text:match('(.+)%.$') or expression[1].text
			kind = self:is_kind_key(str, setup)

			-- if found, extract it
			-- warning, side-effect: this modifies the document's own blocks.
		  if kind then

		  	expression = item[1]
		  	-- remove the 'Str' that matched
		  	expression:remove(1)
		  	-- remove any leading space dot left
		  	expression = self:trim_dot_space(expression, 'forward')
		  	-- store
		  	item[1] = expression
		  	-- return positive result
		  	return kind, item

		  end

		end

	end

end
