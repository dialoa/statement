---Statement:DefListitem_is_statement: whether a DefinitionList item 
-- is a statement. If yes, returns the kind it matches.
-- An item is a statement if its defined expression starts
-- with a Str element whose text matches a statement kind (or alias).
--@param elem (optional) item of a pandoc DefinitionList,
--							defaults to self.element[1]
--@param setup (optional) a Setup class object, to be used when
--			the function is called from the setup object
--@return string or nil element's kind (key of `setup.kinds`) or nil
function Statement:DefListitem_is_statement(item, setup)
	setup = setup or self.setup -- pointer to the setup table
	local kinds = setup.kinds -- pointer to the kinds table
	item = item or self.element 
									and self.element.t == 'DefinitionList' 
									and self.element.content[1]
	local expression -- Inlines expression defined, i.e. item[1]
	local kind -- kind key, if found
	--local new_item -- modified item

	expression = item[1]
	if expression[1].t and expression[1].t == 'Str' then

		-- ignore any dot at the end of the string
		local str = expression[1].text:match('(.+)%.$') or expression[1].text
		-- try a key match, return
	  return self:is_kind_key(str, setup)

	end

end
