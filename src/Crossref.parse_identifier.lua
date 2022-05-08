---Crossref:parse_identifier: Parse an element's
-- identifier and return a map for the identifiers table.
-- @TODO in the future we'll process any flags included
-- in the identifier like `g:` for global identifiers.
--@param str string the Pandoc element identifier
--@return id string the identifier proper
--@return attr map of identifier attributes or nil 
function Crossref:parse_identifier(str)
	local id = str
	local attr = {}

	--@TODO: extract any flags in str, set attributes

	return id, attr
end



