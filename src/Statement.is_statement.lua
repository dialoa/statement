---Statement:is_statement Whether an element is a statement.
-- Simple wrapper for the Div_is_statement and 
-- DefinitionList_is_statement functions.
--@param elem pandoc element, should be Div or DefinitionList
--@param setup (optional) a Setup class object, to be used when
--			the function is called from the setup object
--@return list or nil, pandoc List of kinds matched
function Statement:is_statement(elem,setup)
	setup = setup or self.setup
	if elem.t then
		if elem.t == 'Div' then
			return self:Div_is_statement(elem,setup)
		elseif elem.t == 'DefinitionList' 
					and elem.content[1] then
			return self:DefListitem_is_statement(elem.content[1],setup)
		end
	end
end