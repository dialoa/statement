--- Statement:write: format the statement as an output string.
-- @param format string (optional) format desired if other than FORMAT
-- @return Blocks blocks to be inserted. 
function Statement:write(format)
	local format = format or FORMAT
	local blocks = pandoc.List:new()

	-- do we have before_first includes to include before any
	-- definition? if yes include them here and wipe it out
	if self.setup.includes.before_first then
		blocks:extend(self.setup.includes.before_first)
		self.setup.includes.before_first = nil
	end

	-- do we need to write the kind definition first?
	-- if local blocks are returned, insert them
	local write_kind_local_blocks = self:write_kind()
	if write_kind_local_blocks then
		blocks:extend(write_kind_local_blocks)
	end

	-- format the statement

	if format:match('latex') then

		blocks:extend(self:write_latex())

	elseif format:match('html') then

		blocks:extend(self:write_html())

	elseif format:match('jats') then

		blocks:extend(self:write_jats())

	else

		blocks:extend(self:write_native())

	end
	
	return blocks

end