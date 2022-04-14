-- # Walker class

--- Walker: class to hold methods that walk through the document
Walker = {}

!input Walker.collect_ids -- function to collect non-statement ids

!input Walker.crossreferences -- filter to process crossreferences to statements

!input Walker.statements_in_lists -- filter, LaTeX hack for statements within lists

-- Walker:new: create a Walker class object based on document's setup
--@param setup a Setup class object
--@param doc Pandoc document
--@return Walker class object
function Walker:new(setup, doc)

	-- create an object of the Walker class
	local o = {}
	self.__index = self 
	setmetatable(o, self)

	-- pointer to the setup table
	o.setup = setup
	o.blocks = doc.blocks

	-- collect ids of non-statement elements
	-- this is to ensure that automatic statement id creation doesn't
	-- create duplicates
	o:collect_ids()

	return o

end

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
	local is_modified = false

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

		--recursively process elements whose content is blocks
		elseif content_is_blocks:includes(block.t) then

			local sub_blocks = self:walk(block.content)
			if sub_blocks then
				block.content = sub_blocks
				is_modified = true
				result:insert(block)
			else
				result:insert(block)
			end

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

	return is_modified and result or nil

end