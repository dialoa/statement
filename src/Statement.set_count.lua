---Statement:set_count: increment a statement kind's counter
-- Increments the kind's count of this statement kind or
-- its shared counter's kind.
-- Note: set_is_numbered ensures that the kind's counter
-- is a counting one.
--@return nil
function Statement:set_count()
	local kinds = self.setup.kinds -- pointer to the kinds table
	local counter = kinds[self.kind].counter
	-- kind to count: shared counter's kind or self.kind
	local kind_to_count = kinds[counter] and counter
												or self.kind

	kinds[kind_to_count].count =	kinds[kind_to_count].count
																and kinds[kind_to_count].count + 1
																or 1
end