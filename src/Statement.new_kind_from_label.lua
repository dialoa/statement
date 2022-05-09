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
	-- can safely be used as LaTeX envt name and html class.
	-- we go through utf8 chars and only keep ASCII alphanum ones
	-- we add 'statement_' in case the label matches a LaTeX command
	local function create_key_from_label(inlines)
		local result = 'sta_'
		for _,code in utf8.codes(stringify(inlines)) do
			if (code >= 48 and code <= 57) -- digits 
					or (code >= 65 and code <= 90) -- A-Z 
					or (code >= 97 and code <= 122) then
				result = result..utf8.char(code):lower()
			else
				result = result..'_'
			end
		end
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
	-- the style's custom_label_changes field holds
	-- changes needed when a custom label is used.
	-- we create a <style>_custom if not already done.
	if styles[style].custom_label_changes then

		if not styles[style..'_custom'] then

			-- create a modified map of the style
			local custom_style_map = {}
			for k,v in pairs(styles[style].custom_label_changes) do
				custom_style_map[k] = v
			end
			for k,v in pairs(styles[style]) do
				if not custom_style_map[k] then
					custom_style_map[k] = v
				end
			end
			setup:set_style(style..'_custom', custom_style_map)

		end

		style = style..'_custom'

	end

	-- set the new kind
	setup:set_kind(new_kind, {
			prefix = kinds[kind].prefix,
			style = style,
			label = custom_label,
			counter = 'none'
	})

	-- set this statement's kind to the new kind
	self.kind = new_kind

end
