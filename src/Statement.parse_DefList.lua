---Statement:parse_DefList parse a DefinitionList element into a statement
-- Parses a DefinitionList element into a statement, setting its
-- kind, identifier, label, info, acronym, content. 
-- Turns its Plain blocks into Para, for uniformity with fenced Divs.
-- Assumes the element contains only one DefinitionList item.
-- Creates new kinds and styles as needed.
-- Updates:
--		self.content
--		self.identifier
-- 		self.label
--		self.custom_label
--		self.kind
--		self.acronym
--		self.crossref_label
-- 		
--@param elem pandoc DefinitionList element (optional) element to be parsed
--											defaults to self.element
--@return bool true if successful, false if not
function Statement:parse_DefList(elem)
	local setup = self.setup -- points to the setup table
	local options = setup.options -- points to the options table
	local kinds = setup.kinds -- points to the kinds table
	local aliases = setup.aliases -- points to the aliases table
	elem = elem or self.element
	local item -- the first DefinitionList item
	local expression, definitions -- the item's expression and definitions
	local identifier -- string, user-provided identifier if found

	-- safety check
	if not elem.t or elem.t ~= 'DefinitionList' then
		message('ERROR', 	'Non-DefinitionList element passed to the parse_DefList function,'
											..' this should not have happened.')
		return
	end

	-- ignore empty DefinitionList
	if not elem.content[1] then
		return
	end

	self.kind, item = self:parse_DefList_kind(elem.content[1])

	-- return if failed to match
	if not self.kind then
		message('ERROR', 	'DefinitionList element passed to the parse DefinitionList function,'
											..' without DefListitem_is_statement check,'
											..'this should not have happened.')
		return 
	end

	-- item[1]: expression defined
	-- item[2]: list of Blocks, definitions
	expression = item[1]
	definitions = item[2]

	-- Turn top-level Plain in definitions into Para
	for _,definition in ipairs(definitions) do
		for i = 1, #definition do
			if definition[i].t and definition[i].t == 'Plain' then
				definition[i] = pandoc.Para(definition[i].content)
			end
		end
	end

	-- Process expression: extract any label, info, acronym
	-- extract id,
	-- insert the remainder in the first paragraph of 
	-- the definition.

	-- extract any label, info, acronym from expression
	local result = self:parse_heading_inlines(expression)
	if result then
		self.acronym = result.acronym
		self.custom_label = result.custom_label
		self.info = result.info
		expression = result.remainder
	end

	-- look for an id in the expression
	local identifier, new_expression = self:parse_identifier(expression)
	if identifier then
		self.identifier = identifier
		expression = new_expression
	end

	-- clean up
	expression = Statement:trim_dot_space(expression)
	expression = Statement:trim_dot_space(expression, 'reverse')

	-- if any remainder, insert in the first Para of the first definition
	-- or create a new Para if necessary
	if expression and #expression > 0 then
		definitions[1] = definitions[1] or pandoc.List:new()
		if definitions[1][1] and definitions[1][1].t == 'Para' then
			definitions[1][1].content = expression:extend(
																		definitions[1][1].content)
		else 
			definitions[1]:insert(1, pandoc.Para(expression))
		end
	end

	-- concatenate definitions as the statement's content
	self.content = pandoc.List:new() -- Blocks
	for _,definition in ipairs(definitions) do
		if #definition > 0 then
			self.content:extend(definition)
		end
	end

	return true

end