--- Helpers.font_format_native: parse font features into 
-- native pandoc elements: Emph, Strong, smallcaps Span.
-- Note that the function won't work if you pass it a List
-- that is not of type Blocks or Inlines. 
--@TODO requires >=2.17 to recognize Blocks and Inlines types
--@TODO provide Spans with classes for older Pandoc versions?
--@TODO type(elem) in Pandoc <2.17 doesn't return 'Inline' but 'Para' etc.
-- @param len Inlines or string to be interpreted
-- @return function, Inline(s) -> Inline(s) or Block(s) -> Block(s)
Helpers.font_format_native = function (str)
	-- FEATURES and their conversion
	local FEATURES = {
		italics = 	function(inlines) 
									return pandoc.Emph(inlines)
								end,
		smallcaps = function(inlines) 
									return pandoc.SmallCaps(inlines)
								end,
		bold = 	function(inlines) 
								return pandoc.Strong(inlines)
							end,
		underline = function(inlines) 
									return pandoc.Underline(inlines)
								end,
		strikeout = function(inlines)
									return pandoc.Strikeout(inlines)
								end,
		subscript = function(inlines)
									return pandoc.Subscript(inlines)
								end,
		superscript = function(inlines) 
									return pandoc.Superscript(inlines)
								end,
		code = function(inlines)
									return pandoc.Code(stringify(inlines))
								end,
	}
	-- provide some aliases
	local ALIASES = {
		italics = {'italic'},
		normal = {'normalfont'},
		smallcaps = {'small%-caps'}, -- used as a pattern, so `-` must be escaped
	}

	-- ensure str is defined and a string
	str = type(str) == 'string' and str ~= '' and str
				or type(str) == 'Inlines' and #str > 0 and stringify(str)
				or nil

	if str then

		-- build a list of functions to be applied
		local formatters = pandoc.List:new()

		for feature,definition in pairs(FEATURES) do
			if str:match(feature) then
				formatters:insert( definition )
			-- avoid multiple copies by only looking for aliases
			-- if main feature key not found and breaking if we find any alias 
			elseif ALIASES[feature] then 
				for _,alias in ipairs(ALIASES[feature]) do
					if str:match(alias) then
						formatters:insert( definition )
						break -- ensures no multiple copies
					end
				end
			end
		end

		if #formatters > 0 then

			-- Common Inlines formatting function
			local inlines_format = 	function(inlines)
													for _,formatter in ipairs(formatters) do
														inlines = formatter(inlines)
													end
													return inlines
												end

			-- return a function that handles all types
			-- 	- Inlines, Inline: wrap with inlines_format
			-- 	- Blocks, Block: wrap the content of leaf blocks (those
			--									whose content is inlines only)
			return function (obj)
				-- determine type
				obj_type = (type(obj) == 'Inlines' or type(obj) == 'Inline'
										or type(obj) == 'Blocks' or type(obj) == 'Block')
										and type(obj)
										or nil
				if not obj_type and type(obj) == 'List' and obj[1] then
					if type(obj[1]) == 'Inline' then
						obj = pandoc.Inlines(obj)
						obj_type = 'Inlines'
					elseif type(obj[1] == 'Block') then
						obj = pandoc.Blocks(obj)
						obj_type = 'Blocks'
					end
				end
				-- process object according to type and return it
					if obj_type == 'Inlines' or obj_type == 'Inline' then
						return inlines_format(obj)
					elseif obj_type == 'Block' and type(obj.content) == 'Inlines' then
						obj.content = inlines_format(obj.content)
						return obj
					elseif obj_type == 'Blocks' then
						return obj:walk( { 
								Block = function(elem)
										if elem.content and type(elem.content) == 'Inlines' then
											elem.content = inlines_format(elem.content)
											return elem
										end
									end 
							})
					else
						return obj
					end
				
				end

		end

	end

	return function(obj) return obj end

end
