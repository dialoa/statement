---Statement:set_fields: set a statement's fields based on parsed values
-- This function is called after parsing a Div or DefinitionList
-- Uses:
--		self.kind
-- 		self.identifier
--		self.custom_label
--		self.acronym
--		self.info
--		self.content
-- Updates and sets:
--		self.kind   (may create a new kind from custom label)
--		self.identifier 	(assigns automatic IDs)
--		self.is_numbered  (whether the statement is numbered)
--		self.kinds[self.kind].count the statement's count
-- 		self.label
--		self.custom_label
--		self.crossref_label
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

	-- set label and crossref labels
	self:set_labels()

	-- set identifier
	self:set_identifier()

end