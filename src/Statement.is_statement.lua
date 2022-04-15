---Statement:is_statement Whether an element is a statement.
-- Simple wrapper for the kinds_matched function, makes for more
-- legible code elsewhere.
--@param elem pandoc element, should be Div or DefinitionList
--@param setup (optional) a Setup class object, to be used when
--			the function is called from the setup object
--@return bool whether the element is a statement
function Statement:is_statement(elem,setup)
	if self:kinds_matched(elem,setup) then
		return true
	else
		return false
	end
end