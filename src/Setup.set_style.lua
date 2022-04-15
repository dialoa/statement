---Setup:set_style: create or set a style based on an options map
-- Creates a new style or modify an existing one, based on options.
--@param name string style key
--@param map map of options
function Setup:set_style(style,map)
	local styles = self.styles -- points to the styles map
	local map = map or {}
	local new_style = {}
	local based_on

	-- basis: user-defined, existing style, 'plain' if available, or 'empty'
	if map.based_on and styles[stringify(map.based_on)] then
		based_on = stringify(map.based_on)
	elseif styles[style] then
		based_on = style
	elseif styles['plain'] then
		based_on = 'plain'
	elseif styles['empty'] then
		based_on = 'empty'
	else
		message('WARNING','Filter defaults misconfigured: no `empty` style provided.'
			..' Definition for '..style..' must be complete, if not things may break.')
	end

	-- do_not_define_in_FORMAT fields
	for key,value in pairs(map) do
		if key:match('^do_not_define_in_') then
			new_style[key] = stringify(value)
		end
	end

	-- validate and insert options, or copy from the style it's based on
	local length_fields = {
		'margin_top', 'margin_bottom', 'margin_left', 'margin_right',
		'indent', 'space_after_head'
	}
	local font_fields = {
		'body_font', 'head_font'
	}
	local string_fields = { 
		'punctuation', 'heading_pattern'
	}
	for _,length_field in ipairs(length_fields) do
		new_style[length_field] = (map[length_field] and self:length_format(map[length_field])
																and stringify(map[length_field]))
															or styles[based_on][length_field]
	end
	for _,font_field in ipairs(font_fields) do
		new_style[font_field] = (map[font_field] and self:font_format(map[font_field])
																and map[font_field])
														or styles[based_on][font_field]
	end
	for _,string_field in ipairs(string_fields) do
		new_style[string_field] = map[string_field] and stringify(map[string_field])
															or styles[based_on][string_field]
	end

	-- store the result
	styles[style] = new_style

end