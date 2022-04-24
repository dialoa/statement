--- Statement:new_kind_from_label: create and set a new kind from a 
-- statement's custom label. 
-- Uses:
--		setup:set_style to create a style based on another
--		self.kind the statement's kind
--		self.custom_label the statement's custom label
-- Updates:
--		self.setup.kinds
--		self.setup.styles
--
--@return nil
function Statement:new_kind_from_label()
	local setup = self.setup -- pointing to the setup
	local styles = self.setup.styles -- pointer to the styles table
	local kinds = self.setup.kinds -- pointer to the kinds table	
	local kind = kind or self.kind -- key of the original statement style
	local style = kinds[kind].style
	local custom_label = self.custom_label
	local new_kind, new_style -- keys of the new statement kind 
														-- and (if needed) the new style

	-- create_key_from_label: turn inlines into a key that
	-- can safely be used as LaTeX envt name and html class
	local function create_key_from_label(inlines)
		local result = stringify(inlines):gsub('[^%w]','_'):lower()
		if result == '' then result = '_' end
		return result
	end

	-- Main function body

	if not custom_label then
		return
	end

	-- create a new kind key from label
	local label_str = create_key_from_label(custom_label)
	-- ensure it's a new key
	local n = 0
	new_kind = label_str
	while kinds[new_kind] do
		n = n + 1
		new_kind = label_str..'-'..tostring(n)
	end

	-- do we need a new style too?
	-- custom_label_style of the original kind holds user-defined changes
	-- for the rest set the basis style as the original style
	if kinds[kind].custom_label_style then

		local style_changes_map = kinds[kind].custom_label_style
		style_changes_map.based_on = style

		-- get a new style key
		local str = new_kind -- use the new kind's name
		-- ensure it's a new key
		local n = 0
		new_style = str
		while styles[new_style] do
			n = n + 1
			new_style = str..'-'..tostring(n)
		end

		-- set the new style
		setup:set_style(new_style, style_changes_map)

	else

		new_style = style

	end

	-- set the new kind
	setup:set_kind(new_kind, {
			prefix = kinds[kind].prefix,
			style = new_style,
			label = custom_label,
			counter = 'none'
	})

	-- set this statement's kind to the new kind
	self.kind = new_kind

end
