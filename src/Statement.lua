-- # Statement class

--- Statement: class for statement objects.
-- @field kind string the statement's kind (key of the `kinds` table)
-- @field id string the statement's id
-- @field cust_label Inlines the statement custom's label, if any
-- @field info Inlines the statement's info
Statement = {
	setup = nil, -- points to the Setup class object
	element = nil, -- original element to be turned into statement
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

	o.setup = setup -- points to the setup, needed by the class's methods
	o.element = elem -- points to the original element

	if o.element.t then
		if o.element.t == 'Div' and o:Div_is_statement() then
			o:parse_Div()
			return o
		elseif o.element.t == 'DefinitionList' then -- and o:DefinitionList_is_statement()
			-- @TODO parse Def List statements
			-- return o
		end
	end

end

!input Statement.is_statement -- to tell whether an element is a statement, and what kind it matches

!input Statement.Div_is_statement -- to tell whether an element is a statement, and what kind it matches

!input Statement.parse_Div -- parse Div element as statement

!input Statement.parse_Div_heading -- parse Div element as statement

!input Statement.extract_fbb -- to extract content between first balanced brackets

!input Statement.new_kind_from_label -- to create a new kind from the statement's label

!input Statement.new_kind_unnumbered -- to create a new kind from the statement's label

!input Statement.set_identifier -- to set id and store it

!input Statement.set_is_numbered -- determine whether statement is numbered

!input Statement.increment_count -- to update the count of this statement's kind

!input Statement.set_crossref_label -- to set the crossref label

!input Statement.write_style -- to write a style definition

!input Statement.write_kind -- to write a kind definition

!input Statement.write_label -- to write a statement's label

!input Statement.write -- to write a statement (main function)

