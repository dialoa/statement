--- Walker:walk: walk through a list of blocks, processing statements
--@param blocks (optional) pandoc Blocks to be processed
--								defaults to self.blocks
function Walker:walk(blocks)
	local blocks = blocks or self.blocks
	-- recursion setup
	-- NB, won't look for statements in table cells
	-- element types with elem.content of Blocks type
	local content_is_blocks = pandoc.List:new(
															{'BlockQuote', 'Div', 'Note'})
	-- element types with elem.content a list of Blocks type
	local content_is_list_of_blocks = pandoc.List:new(
							{'BulletList', 'DefinitionList', 'OrderedList'})
	local result = pandoc.List:new()
	local is_modified = false -- whether anything is changed in this doc

	-- go through the blocks in order
	--		- find headings and update counters
	--		- find statements and process them
	for _,block in ipairs(blocks) do

		-- headers: increment counters if they exist
		-- ignore 'unnumbered' headers: <https://pandoc.org/MANUAL.html#extension-header_attributes>
		if self.setup.counters and block.t == 'Header' 
			and not block.classes:includes('unnumbered') then

				self.setup:increment_counter(block.level)
				result:insert(block)

		-- Divs: check if they are statements
		elseif block.t == 'Div' then

			-- try to create a statement
			sta = Statement:new(block, self.setup)

			-- replace the block with the formatted statement, if any
			if sta then
				result:extend(sta:write())
				is_modified = true

			-- if none, process the Div's contents
			else

				local sub_blocks = self:walk(block.content)
				if sub_blocks then
					block.content = sub_blocks
					is_modified = true
					result:insert(block)
				else
					result:insert(block)
				end

			end

		-- ends Div block processing

		-- DefinitionLists: scan for statements
		-- The element is a list, each item is a pair (inlines, 
		-- list of blocks). We need to check the list item per item,
		-- split it if it contains statements, and process the
		-- contents of non-statement items recursively.
		elseif self.setup.options.definition_lists 
						and block.t == 'DefinitionList' then

			-- `previous_items`: store non-statement items one by one until
			-- we encounter a statement 
			local previous_items = pandoc.List:new() -- to store previous items
--			local block_modified = false -- any changes in this block?

			for _,item in ipairs(block.content) do

				-- if we succeed in creating a statement, flush out
				-- any previous items in a DefinitionList and insert
				-- the statement.
				local successful_insert = false 
				-- if item is supposed to be a statement, try parsing and insert.
				-- note that Statement:new needs a single-item DefinitionList,
				-- so we create one and pass it.
				if Statement:DefListitem_is_statement(item, self.setup) then

					-- try to parse
					sta = Statement:new(pandoc.DefinitionList({item}), self.setup)
					if sta then
						-- if previous items, flush them out in a new DefinitionList
						if #previous_items > 0 then
							result:insert(pandoc.DefinitionList(previous_items))
							previous_items = pandoc.List:new()
						end
						result:extend(sta:write())
						is_modified = true
						successful_insert = true
					end
				end

				-- if not a statement or failed to parse, treat as 
				-- standard DefinitionList item: process the contents
				-- recursively and insert in previous items.
				if not successful_insert then 

					-- recursively process the item's contents (list of Blocks)
					-- recall a DefinitionList item is a pair
					-- item[1] Inlines expression defined
					-- item[2] List of Blocks (list of lists of block elements)
					local new_content = pandoc.List:new()
					for _,blocks in ipairs(item[2]) do
						local sub_blocks = self:walk(blocks)
						if sub_blocks then
							is_modified = true
							new_content:insert(sub_blocks)
						else
							new_content:insert(blocks)
						end
					end
					-- if we've modified anything in the recursion, insert
					-- the new content
					if is_modified then
						item[2] = new_content
					end

					-- store the item to be included in a future DefinitionList
					previous_items:insert(item)

				end

			end -- end of the item loop

			-- if any previous_items left, insert as DefinitionList

			if #previous_items > 0 then
				result:insert(pandoc.DefinitionList(previous_items))
				previous_items = pandoc.List:new()
			end

		-- ends DefinitionList block processing

		-- element with blocks content: process recursively
		elseif content_is_blocks:includes(block.t) then

			local sub_blocks = self:walk(block.content)
			if sub_blocks then
				block.content = sub_blocks
				is_modified = true
				result:insert(block)
			else
				result:insert(block)
			end

		-- element with list of blocks content: process recursively
		elseif content_is_list_of_blocks:includes(block.t) then

			-- rebuild the list item by item, processing each
			local content = pandoc.List:new()
			for _,item in ipairs(block.content) do
				local sub_blocks = self:walk(item)
				if sub_blocks then
					is_modified = true
					content:insert(sub_blocks)
				else
					content:insert(item)
				end
			end
			if is_modified then
				block.content = content
				result:insert(block)
			else
				result:insert(block)
			end

		else -- any other element, just insert the block

			result:insert(block)

		end

	end

	return is_modified and pandoc.Blocks(result) or nil

end