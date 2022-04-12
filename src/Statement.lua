-- # Statement class

--- Statement: class for statement objects.
-- @field kind string the statement's kind (key of the `kinds` table)
-- @field id string the statement's id
-- @field cust_label Inlines the statement custom's label, if any
-- @field info Inlines the statement's info
Statement = {
	kind = nil, -- string, key of `kinds`
	id = nil, -- string, Pandoc id
	custom_label = nil, -- Inlines, user-provided label
	crossref_label = nil, -- Inlines, label used to crossreference the statement
	label = nil, -- Inlines, formatted label to display
	acronym = nil, -- Inlines, acronym
	info = nil, -- Inlines, user-provided info
	content = nil, -- Blocks, statement's content
	is_numbered = true, -- whether a statement is numbered
}
--- create a statement object from a pandoc element.
-- @param elem pandoc Div or list item (= table list of 2 elements)
-- @param setup Setup class object, the document's statements setup
-- @return statement object or nil if elem isn't a statement
function Statement:new(elem, setup)

	local kind = Statement:find_kind(elem, setup)
	if kind then

		-- create an object of Statement class
		local o = {}
		self.__index = self 
		setmetatable(o, self)

		-- populate the object
		o.setup = setup -- filter setup
		o.kind = kind -- element kind
		o.content = elem.content -- element content
		o:extract_label() -- extract label, acronym
		-- if custom label, create a new kind
		if o.custom_label then
			o:new_kind_from_label()
		end
		o:extract_info() -- extract info
		o:set_identifier(elem) -- set identifier based on elem.identifier or acroynym
		o:set_is_numbered(elem) -- set self.is_numbered
		if o.is_numbered then
			o:increment_count() -- update the kind's counter
		end
		o:set_crossref_label() -- set crossref label

		-- return
		return o
	
	else
		return nil
	end

end

Statement.find_kind = require('Statement.find_kind') -- to determine whether an element is a statement, and of what kind

Statement.extract_fbb = require('Statement.extract_fbb') -- to extract content between first balanced brackets

Statement.extract_label = require('Statement.extract_label') -- to extract a statement's label

Statement.new_kind_from_label = require('Statement.new_kind_from_label') -- to create a new kind from the statement's label

Statement.extract_info = require('Statement.extract_info') -- to extract a statement's info field

Statement.set_identifier = require('Statement.set_identifier') -- to set id and store it

Statement.set_is_numbered = require('Statement.set_is_numbered') -- determine whether statement is numbered

Statement.increment_count = require('Statement.increment_count') -- to update the count of this statement's kind

Statement.set_crossref_label = require('Statement.set_crossref_label') -- to set the crossref label

Statement.write_style = require('Statement.write_style') -- to write a style definition

Statement.write_kind = require('Statement.write_kind') -- to write a kind definition

Statement.write_label = require('Statement.write_label') -- to write a statement's label

Statement.write = require('Statement.write') -- to write a statement (main function)

