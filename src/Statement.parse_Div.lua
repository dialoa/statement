---Statement:parse_Div parse a Div element into a statement
-- Parses a pandoc Div element into a statement, setting its
-- kind, identifier, label, info, acronym, content. 
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
--@param elem pandoc Div element (optional) element to be parsed
--											defaults to self.element
--@return bool true if successful, false if not
function Statement:parse_Div(elem)
	local setup = self.setup -- points to the setup table
	local options = setup.options -- points to the options table
	local kinds = setup.kinds -- points to the kinds table
	local aliases = setup.aliases -- points to the aliases table
	elem = elem or self.element
	local kind

	-- safety check
	if not elem.t or elem.t ~= 'Div' then
		message('ERROR', 	'Non-Div element passed to the parse Div function,'
											..' this should not have happened.')
		return
	end

	-- find the element's base kind
	--	Div_is_statement() returns the kinds matched by self.element
	local kinds_matched = self:Div_is_statement()
	if not kinds_matched then 
		message('ERROR', 	'Div element passed to the parse Div function,'
											..' without Div_is_statement check,'
											..'this should not have happened.')
		return 
	end
	-- warn if there's still more than one kind
	if #kinds_matched > 1 then
		local str = ''
		for _,match in ipairs(kinds_matched) do
			str = str .. ' ' .. match
		end
		message('WARNING', 'A Div matched several statement kinds: '
			.. str .. '. Treated as kind '.. kinds_matched[1] ..'.')
	end
	self.kind = kinds_matched[1]

	-- store statement content, attributes
	self.content = elem.content -- element content
	
	-- extract any label, info, acronym
	-- @TODO if attributes_syntax is enabled, parse the attribute syntax
	-- Cf. <https://github.com/ickc/pandoc-amsthm>
	self:parse_Div_heading()

	-- if custom label, create a new kind
	if self.custom_label then
		self:new_kind_from_label()
	end

	-- if unnumbered, we may need to create a new kind
	-- if numbered, increase the statement's count
	self:set_is_numbered(elem) -- set self.is_numbered
	if not self.is_numbered then
		self:new_kind_unnumbered()
	else
		self:increment_count() -- update the kind's counter
	end

	self:set_crossref_label() -- set crossref label
	self:set_identifier(elem) -- set identifier, store crossref label for id

	return true

end