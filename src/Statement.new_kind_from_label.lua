--- Statement:new_kind_from_label: create and set a new kind from a 
-- statement's custom label. 
-- updates the self.setup.kinds table with a new kind
function Statement:new_kind_from_label()
	local kind = kind or self.kind
	local kind_key, style_key

	-- create_key_from_label: turn inlines into a key that
	-- can safely be used as LaTeX envt name and html class
	local function create_key_from_label(inlines)
		local result = stringify(inlines):gsub('[^%w]','_'):lower()
		if result == '' then result = '_' end
		return result
	end

	-- Main function body

	if not self.custom_label then
		return
	end

	local label_str = create_key_from_label(self.custom_label)
	kind_key = label_str
	style_key = self.setup.kinds[kind].style -- original style

	-- do we need a new style too?
	if self.setup.kinds[kind].custom_label_style then
		local new_style = {}
		-- copy the fields from the original statement style
		-- except 'is_defined'
		for k,v in pairs(self.setup.styles[style_key]) do
			if k ~= 'is_defined' then
				new_style[k] = v
			end
		end
		-- insert the custom_label_style modifications
		for k,v in pairs(self.setup.kinds[kind].custom_label_style) do
			new_style[k] = v
		end
		-- ensure we use a new style key
		style_key = label_str
		local n = 1
		while self.setup.styles[style_key] do
			style_key = label_str..'-'..tostring(n)
		end
		-- store the new style
		self.setup.styles[style_key] = new_style
	end

	-- ensure we use a new kind key
	local n = 1
	while self.setup.kinds[kind_key] do
		kind_key = label_str..'-'..tostring(n)
		n = n + 1
	end

	-- create the new kind
	-- keep the original prefix; new style if needed
	-- set its new label to custom_label; set its counter to 'none'
	self.setup.kinds[kind_key] = {}
	self.setup.kinds[kind_key].prefix = self.setup.kinds[kind].prefix
	self.setup.kinds[kind_key].style = style_key
	self.setup.kinds[kind_key].label = self.custom_label -- Inlines
	self.setup.kinds[kind_key].counter = 'none'

	-- set this statement's kind to the new kind
	self.kind = kind_key

end
