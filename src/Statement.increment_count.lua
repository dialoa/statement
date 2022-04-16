---Statement:increment_count: increment a statement kind's counter
-- Increments the kind's count of this statement kind or
-- its shared counter's kind.
function Statement:increment_count()
	local kinds = self.setup.kinds -- pointer to the kinds table
	local counter = kinds[self.kind].counter or 'none'
	local kind_to_count = self.kind

	--if shared counter, that kind is the count to increment
	if kinds[counter] then
		kind_to_count = counter
	end
	kinds[kind_to_count].count =	kinds[kind_to_count].count
																and kinds[kind_to_count].count + 1
																or 1

end