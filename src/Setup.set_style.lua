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

	---merge_valid_options: build a map of valid options
	-- from a main map and basis map.
	-- we'll apply this to the main map but also
	-- to the `custom_label_changes` submap.
	--@param map, table or nil the values explicitly specified
	--@param basis, table or nil the based_on backup values
	local function merge_valid_options(map,basis)
		local new_map = {}
		-- length fields: not that `space_after_head` is added below if needed
		local length_fields = pandoc.List:new({
			'margin_top', 'margin_bottom', 'margin_left', 'margin_right',
			'indent',
		})
		-- Note: keeping font fields separate in case we wanted to validate them.
		-- Presently no validation, they are treated like string fields.
		local font_fields = {
			'body_font', 'head_font', 'crossref_font',
		}
		local string_fields = { 
			'punctuation', 'heading_pattern'
		}

		-- handles linebreak_after_head style
		-- (a) linebreak_after_head already is set: ignore space_after_head
		-- (b) space_after_head is \n or \newline: set linebreak_after_head
		-- (c) otherwise, read space_after_head as a length
		-- special case: space_after_head can be `\n` or `\\n` or `\\newline`
		-- if not, assume it's a length
		if map and map.linebreak_after_head 
				or basis and basis.linebreak_after_head then
			new_map.linebreak_after_head = true		
		elseif map and map.space_after_head and
				(map.space_after_head == 
								pandoc.MetaInlines(pandoc.RawInline('tex', '\\n'))
					or map.space_after_head == 
								pandoc.MetaInlines(pandoc.RawInline('tex', '\\newline'))
					or map.space_after_head == 
								pandoc.MetaInlines(pandoc.RawInline('latex', '\\n'))
					or map.space_after_head == 
								pandoc.MetaInlines(pandoc.RawInline('latex', '\\newline'))
				) then
			new_map.linebreak_after_head = true
		else
			length_fields:insert('space_after_head')
		end

		-- insert fields
		for _,length_field in ipairs(length_fields) do
			new_map[length_field] = (map and map[length_field] 
																and length_format(map[length_field])
																and stringify(map[length_field]))
																or basis and basis[length_field]
		end
		for _,font_field in ipairs(font_fields) do
			new_map[font_field] = map and map[font_field]
															and stringify(map[font_field])
															or basis and basis[font_field]
		end
		for _,string_field in ipairs(string_fields) do
			new_map[string_field] = map and map[string_field] 
																and stringify(map[string_field])
																or basis and basis[string_field]
		end

		return new_map

	end

	-- MAIN FUNCTION BODY

	-- determine the style's basis: 
	--	(1) user-defined basis, or 
	--	(2) default version of this style if any,
	--	(3) otherwise 'plain', otherwise 'empty'
	-- user-defined basis may be one of the new styles to be defined
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

	-- read do_not_define_in_FORMAT fields 
	for key,value in pairs(map) do
		if key:match('^do_not_define_in_') then
			new_style[key] = stringify(value)
		end
	end

	-- create the custom_label_changes map
	if map.custom_label_changes 
			or styles[based_on].custom_label_changes then
		new_style.custom_label_changes = 
					merge_valid_options(map.custom_label_changes, 
															styles[based_on].custom_label_changes)
	end

	-- merge remaining options
	local merge = merge_valid_options(map, styles[based_on])
	for k,v in pairs(merge) do
		new_style[k] = v
	end 

	-- Special checks to avoid LaTeX crashes
	if not new_style.space_after_head 
		or new_style.space_after_head == '' then
			new_style.space_after_head = '0pt'
	end

	-- store the result
	styles[style] = new_style

end