---Walker:collect_ids: Collect ids of non-statement in a document
-- Updates self.setup.identifiers
--@param blocks (optional) pandoc Blocks, a list of Block elements
--								defaults to self.blocks
--@return nil
function Walker:collect_ids(blocks)
	local blocks = blocks or self.blocks
	local identifiers = self.setup.identifiers -- identifiers table
	local types_with_identifier = { 'CodeBlock', 'Div', 'Header', 
						'Table', 'Code', 'Image', 'Link', 'Span',	}
	local filter = {} -- filter to be applied to blocks

	-- register_or_warn: register element's id if any; warning if duplicate
	local function register_or_warn(elem) 
		if elem.identifier and elem.identifier ~= '' then
			if identifiers[elem.identifier] then 
				message('WARNING', 'Duplicate identifier: '
													..elem.identifier..'.')
			else
				identifiers[elem.identifier] = {statement = false}
			end
		end
	end

	-- Div: register only if not a statement
	filter.Div = function (elem)
		if elem.identifier and elem.identifier ~= ''
				and not Statement:Div_is_statement(elem,self.setup) then
					register_or_warn(elem)
			end
	end

	-- Generic function for remaining types
	for _,type in ipairs(types_with_identifier) do
		-- make sure we don't erase a filter already defined
		filter[type] = filter[type] or register_or_warn
	end

	-- run the filter through blocks
	blocks:walk(filter)

end



