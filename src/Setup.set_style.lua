---Setup:set_style: create or set a style based on an options map
-- Creates a new style or modify an existing one, based on options.
--@param name string style key
--@param map table style definition from user metadata
--@param new_styles table map of new styles to be defined
function Setup:set_style(style,map,new_styles)
	local styles = self.styles -- points to the styles map
	local length_format = Helpers.length_format
	local font_format = Helpers.length_format
	local map = map or {}
	local new_style = {}
	local based_on = map.based_on and stringify(map.based_on) or nil

	-- basis: user-defined basis, or default version of this style if any,
	-- 				otherwise 'plain', otherwise 'empty'
	-- user-defined can be a pre-existing (=default) style 
	--									or a new style other than itself
	if based_on then
		if styles[based_on] or 	new_styles and new_styles[based_on]
														and based_on ~= style then
			-- leave based_on as is
		elseif based_on == style then
			message('ERROR', 'Style '..style..' defined to be based on itself.'
								..'This is only allowed if defaults provide this style.')
			based_on = nil
		else
			message('ERROR', 'Style '..style..' could not be based on'
												..'`'..based_on..'`. Check if the latter'
												..' is defined.')
			based_on = nil
		end
	end
	if not based_on then 
 		if styles[style] then
			based_on = style
		elseif styles['plain'] then
			based_on = 'plain'
		elseif styles['empty'] then
			based_on = 'empty'
		else
			message('ERROR','Filter defaults misconfigured:'
				..' no `empty` style provided.'
				..' Definition for '..style..' must be complete.'
				.." If it isn't things may break.")
		end
	end

	-- do_not_define_in_FORMAT fields
	for key,value in pairs(map) do
		if key:match('^do_not_define_in_') then
			new_style[key] = stringify(value)
		end
	end

	-- validate and insert options, or copy from the style it's based on
	local length_fields = pandoc.List:new({
		'margin_top', 'margin_bottom', 'margin_left', 'margin_right',
		'indent'
	})
	local font_fields = {
		'body_font', 'head_font'
	}
	local string_fields = { 
		'punctuation', 'heading_pattern'
	}
	-- handles linebreak_after_head style
	-- (a) linebreak_after_head already set: ignore space_after_head
	-- (b) space_after_head is \n or \newline: set linebreak_after_head
	-- (c) otherwise, read space_after_head as a length
	-- special case: space_after_head can be `\n` or `\\n` or `\\newline`
	-- if not, assume it's a length
	if map.linebreak_after_head or styles[based_on].linebreak_after_head then
		new_style.linebreak_after_head = true		
	elseif map.space_after_head and
			(map.space_after_head == 
							pandoc.MetaInlines(pandoc.RawInline('tex', '\\n'))
				or map.space_after_head == 
							pandoc.MetaInlines(pandoc.RawInline('tex', '\\newline'))
				or map.space_after_head == 
							pandoc.MetaInlines(pandoc.RawInline('latex', '\\n'))
				or map.space_after_head == 
							pandoc.MetaInlines(pandoc.RawInline('latex', '\\newline'))
			) then
		new_style.linebreak_after_head = true
	else
		length_fields:insert('space_after_head')
	end

	for _,length_field in ipairs(length_fields) do
		new_style[length_field] = (map[length_field] 
															and length_format(map[length_field])
															and stringify(map[length_field]))
															or styles[based_on][length_field]
	end
	for _,font_field in ipairs(font_fields) do
		new_style[font_field] = (map[font_field] 
														and font_format(map[font_field])
														and map[font_field])
														or styles[based_on][font_field]
	end
	for _,string_field in ipairs(string_fields) do
		new_style[string_field] = map[string_field] 
															and stringify(map[string_field])
															or styles[based_on][string_field]
	end

	-- store the result
	styles[style] = new_style

end