--- walk_doc: processes the document.
-- @param doc Pandoc document
-- @return Pandoc document if modified or nil
local function walk_doc(doc)

	--- process_blocks: processes a list of blocks (pandoc Blocks)
	-- @param blocks
	-- @return blocks or nil if not modified
	local function process_blocks( blocks )

		result = pandoc.List:new()
		is_modified = false

		-- go through the document's element in order
		-- find statement Divs and process them
		-- find headings and update counters
		-- @todo: recursive processing where needed

		for i = 1, #blocks do
			local block = blocks[i]

			if block.t == 'Div' then

				-- try to create a statement
				sta = Statement:new(block)

				-- replace the block with the formatted statement, if any
				if sta then
					result:extend(sta:format())
					is_modified = true
				else
					result:insert(block)
				end

			else

				result:insert(block)

			end

		end

		return is_modified and result or nil

	end

	-- FUNCTION BODY
	-- only return something if doc modified
	local new_blocks = process_blocks(doc.blocks)

	if new_blocks then
		doc.blocks = new_blocks
		return doc
	else
		return nil
	end
end
