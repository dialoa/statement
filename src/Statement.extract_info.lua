--- Statement:extract_info: extra specified info from the statement's content.
-- Scans the content's first block for an info specification (Cite
-- or text within delimiters). If found, remove and place in the
-- statement's `info` field.
-- This should be run after extracting any custom label. 
function Statement:extract_info()

	-- first block must be Para or Plain
	if self.content and 
	  (self.content[1].t=='Para' or self.content[1].t=='Plain') then

	  	local first_block = self.content[1]:clone()
	  	local inf

		-- remove one leading space if any
		if first_block.content[1].t == 'Space' then
			first_block:remove(1)
		end

		-- info must be a Cite element, or bracketed content - not both
		if first_block.content[1].t == 'Cite' then
			inf = pandoc.Inlines(first_block.content[1])
			first_block.content:remove(1)
		else
			-- bracketed content?
			inf, first_block.content = 
				self:extract_fbb(first_block.content)
		end

		-- if info found, save it and save the modified block
		if inf then
			self.info = inf
			self.content[1] = first_block
		end

	end

end
