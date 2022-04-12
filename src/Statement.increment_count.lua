---Statement:increment_count: increment a statement kind's counter
-- Increments the kind's count of this statement kind or
-- its shared counter's kind.
function Statement:increment_count()
	kinds = self.setup.kinds -- pointer to the kinds table
	kind_key = self.kind
	-- shared counter?
	if kinds[kind_key].counter and kinds[kinds[kind_key].counter] then
		kind_key = kinds[kind_key].counter
	end
	kinds[kind_key].count = kinds[kind_key].count 
													and kinds[kind_key].count + 1
													or 1

end