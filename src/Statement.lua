-- # Statement class

--- Statement: class for statement objects.
Statement = {
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


!input Statement.is_statement -- to tell whether an element is a statement, and what kind it matches

!input Statement.is_kind_key -- to tell whether a string is a kind key, or the alias of one

!input Statement.parse_heading_inlines -- parse heading inlines into acronym, custom label, info, remainder

!input Statement.parse_identifier -- extract label{...} or {#...} identifiers from Inlines

!input Statement.Div_is_statement -- to tell whether an element is a statement, and what kind it matches

!input Statement.parse_Div -- parse Div element as statement

-- !input Statement.parse_Div_heading -- parse Div element as statement

!input Statement.DefListitem_is_statement -- to tell whether an Definition list item is a statement and of which kind

!input Statement.parse_DefList -- parse a DefinitionList

!input Statement.parse_DefList_kind -- extract kind name from a Definition List first item

!input Statement.extract_fbb -- to extract content between first balanced brackets

!input Statement.trim_dot_space -- remove leading/trailing dot space in Inlines

!input Statement.new_kind_from_label -- to create a new kind from the statement's label

!input Statement.new_kind_unnumbered -- to create a new kind from the statement's label

!input Statement.set_values -- set a statement's fields, post-parsing

!input Statement.set_identifier -- to set id and store it

!input Statement.set_is_numbered -- determine whether statement is numbered

!input Statement.set_labels -- to set label and crossref label

!input Statement.set_count -- to update the count of this statement's kind

!input Statement.write -- to write a statement (main function)

!input Statement.write_style -- to write a style definition

!input Statement.write_kind -- to write a kind definition

!input Statement.write_label -- to write a statement's label

!input Statement.write_latex -- to write a statement in LaTeX

!input Statement.write_html -- to write a statement in HTML

!input Statement.write_jats -- to write a statement in JATS

!input Statement.write_native -- to write a statement in other formats

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
			o:set_values()
			return o

		elseif o.element.t == 'DefinitionList' 
						and o.element.content[1]
						and o:DefListitem_is_statement(o.element.content[1]) then
			o:parse_DefList()
			o:set_values()
			return o

		end
	end

end
