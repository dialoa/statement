-- # Statement class

--- Statement: class for statement objects.
-- @field kind string the statement's kind (key of the `kinds` table)
-- @field id string the statement's id
-- @field cust_label Inlines the statement custom's label, if any
-- @field info Inlines the statement's info
Statement = {
	kind = nil, -- string, key of `kinds`
	identifier = nil, -- string, Pandoc identifier
	custom_label = nil, -- Inlines, user-provided label
	crossref_label = nil, -- Inlines, label used to crossreference the statement
	label = nil, -- Inlines, label to display in non-LaTeX format e.g. "Theorem 1.1"
	acronym = nil, -- Inlines, acronym
	info = nil, -- Inlines, user-provided info
	content = nil, -- Blocks, statement's content
	is_numbered = true, -- whether a statement is numbered
}
--- create a statement object from a pandoc element.
-- @param elem pandoc Div or DefinitionList
-- @param setup Setup class object, the document's statements setup
-- @return statement object or nil if elem isn't a statement
function Statement:new(elem, setup)

	-- create an object of Statement class
	local o = {}
	self.__index = self 
	setmetatable(o, self)

	o.setup = setup
	-- determine if it has a statement kind or return nil
	o.kind = o:find_kind(elem)

	if o.kind then

		o.content = elem.content -- element content
		-- extract label, acronym
		o:extract_label() -- extract label, acronym
		-- if custom label, create a new kind
		if o.custom_label then
			o:new_kind_from_label()
		end
		-- if unnumbered, we may need to create a new kind
		o:set_is_numbered(elem) -- set self.is_numbered
		if not o.is_numbered then
			o:new_kind_unnumbered()
		end
		o:extract_info() -- extract info
		o:set_crossref_label() -- set crossref label
		o:set_identifier(elem) -- set identifier, store crossref label for id
		if o.is_numbered then
			o:increment_count() -- update the kind's counter
		end

		-- return
		return o

	else
		return nil
	end

end

!input Statement.kinds_matched -- to tell whether an element is a statement, and what kind it matches

!input Statement.find_kind -- to decide an element's main kind

!input Statement.extract_fbb -- to extract content between first balanced brackets

!input Statement.extract_label -- to extract a statement's label

!input Statement.new_kind_from_label -- to create a new kind from the statement's label

!input Statement.new_kind_unnumbered -- to create a new kind from the statement's label

!input Statement.extract_info -- to extract a statement's info field

!input Statement.set_identifier -- to set id and store it

!input Statement.set_is_numbered -- determine whether statement is numbered

!input Statement.increment_count -- to update the count of this statement's kind

!input Statement.set_crossref_label -- to set the crossref label

!input Statement.write_style -- to write a style definition

!input Statement.write_kind -- to write a kind definition

!input Statement.write_label -- to write a statement's label

!input Statement.write -- to write a statement (main function)

