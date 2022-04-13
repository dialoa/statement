---Statement:new_kind_unnumbered create a new unnumbered kind
-- if needed, based on a statement's kind
-- Uses and updates:
--		self.kind, this statement's current kind
--		self.setup.kinds the kinds table
--		self.setup.styles the styles table
function Statement:new_kind_unnumbered()
	local kinds = self.setup.kinds -- pointer to the kinds table
	local styles = self.setup.styles -- pointer to the styles table	
	local kind = self.kind
	local kind_key, style_key

	-- do nothing if this statement's kind is already unumbered
	if kinds[kind] and kinds[kind].counter
			and kinds[kind].counter == 'none' then
		return
	end

	-- if there's already a `-unnumbered` variant for this kind
	-- switch the kind to this
	kind_key = kind..'-unnumbered'
	if kinds[kind_key] and kinds[kind_key].counter
			and kinds[kind_key].counter == 'none' then
		self.kind = kind_key
		return
	end

	-- otherwise create a new unnumbered variant
	kind_key = kind..'-unnumbered'
	style_key = kinds[kind].style -- use the original style

	-- ensure the kind key is new
	local n = 0
	while kinds[kind_key] do
		n = n + 1
		kind_key = kind..'-unnumbered-'..tostring(n)
	end

	-- create the new kind
	-- keep the original prefix and label; set its counter to 'none'
	self.setup.kinds[kind_key] = {}
	self.setup.kinds[kind_key].prefix = kinds[kind].prefix
	self.setup.kinds[kind_key].style = style_key
	self.setup.kinds[kind_key].label = kinds[kind].label -- Inlines
	self.setup.kinds[kind_key].counter = 'none'

	-- set this statement's kind to the new kind
	self.kind = kind_key

end