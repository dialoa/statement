---Crossref:collect_identifiers: Collect identifiers of 
-- non-statements in the document.
-- Updates:
--		self.identifiers
--@param blocks pandoc Blocks, a list of Block elements
--@return nil
function Crossref:collect_identifiers()
	local setup = self.setup
	local blocks = self.doc.blocks
	local types_with_identifier = { 'CodeBlock', 'Div', 'Header', 
						'Table', 'Code', 'Image', 'Link', 'Span',	}
	local filter = {} -- filter to be applied to blocks

	-- get_filter: generate a filter (elem -> elem) that registers
	-- non-duplicate IDs with type `type`.
	local function get_filter(type) 
		return function(elem)
			if elem.identifier and elem.identifier ~= '' then
				-- parse the identifier
				local id, attr = Crossref:parse_identifier(elem.identifier)
				-- register the type
				attr.type = type
				-- register or warn
				success = self:register_identifier(id, attr, 'strict')
				if not success then 
					message('WARNING', 'Duplicate identifier: '..id..'.')
				end
			end

			end
	end

	-- Div: register only if not a statement
	filter.Div = function (elem)
		if elem.identifier and elem.identifier ~= ''
				and not Statement:Div_is_statement(elem, setup) then
					get_filter('Div')(elem)
			end
	end

	-- Generic function for remaining types
	for _,type in ipairs(types_with_identifier) do
		-- make sure we don't erase a filter already defined
		filter[type] = filter[type] or get_filter(type)
	end

	-- run the filter through blocks
	blocks:walk(filter)

end



