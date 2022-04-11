--- Statement:new_kind_from_label: create and set a new kind from a 
-- statement's custom label. 
-- updates the self.setup.kinds table with a new kind
function Statement:new_kind_from_label()
	local kind = kind or self.kind

	-- create_key_from_label: turn inlines into a key that
	-- can safely be used as LaTeX envt name and html class
	local function create_key_from_label(inlines)
		local result = stringify(inlines):gsub('[^%w]','_'):lower()
		if result == '' then result = '_' end
		return result
	end

	-- Main function body

	if not self.label then
		return
	end

	local kind_key = create_key_from_label(self.label)

	-- ensure we use a new kind key
	local n = 1
	while self.setup.kinds[kind_key] do
		kind_key = label_str..'-'..tostring(n)
		n = n + 1
	end

	-- create the new kind by cloning the original one
	-- set its new label to custom_label and its counter to 'none'
	self.setup.kinds[kind_key] = {}
	for k,v in pairs(self.setup.kinds[kind]) do
		 self.setup.kinds[kind_key][k] = v
	end
	self.setup.kinds[kind_key].label = self.label -- Inlines
	self.setup.kinds[kind_key].counter = 'none'

	-- set this statement's kind to the new kind
	self.kind = kind_key

end
