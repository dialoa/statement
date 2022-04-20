---Statement:set_fields: set a statement's fields based on parsed values
-- This function is called after parsing a Div or DefinitionList
-- Updates:
--		self.content
--		self.identifier
-- 		self.label
--		self.custom_label
--		self.kind
--		self.acronym
--		self.crossref_label
-- 		
--@param elem pandoc Div element (optional) element to be parsed
--											defaults to self.element
--@return bool true if successful, false if not
function Statement:set_values()

	-- if custom label, create a new kind
	if self.custom_label then
		self:new_kind_from_label()
	end

	-- if unnumbered, we may need to create a new kind
	-- if numbered, increase the statement's count
	self:set_is_numbered() -- set self.is_numbered
	if not self.is_numbered then
		self:new_kind_unnumbered()
	else
		self:set_count() -- update the kind's counter
	end

	self:set_crossref_label() -- set crossref label
	self:set_identifier() -- set identifier, store crossref label for id

end