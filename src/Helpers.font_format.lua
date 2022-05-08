--- Helpers.font_format: parse font features into the desired format
-- @param len Inlines or string to be interpreted
-- @param format (optional) desired format if other than FORMAT
-- @return string, font commands in the desired format or ''
Helpers.font_format = function (str, format)
	local format = format or FORMAT
	-- FEATURES and their conversion
	local FEATURES = {
		upright = {
			latex = '\\upshape',
			css = 'font-style: normal;',
		},
		italics = {
			latex = '\\itshape',
			css = 'font-style: italic;',
		},
		smallcaps = {
			latex = '\\scshape',
			css = 'font-variant: small-caps;',
		},
		bold = {
			latex = '\\bfseries',
			css = 'font-weight: bold;',
		},
		normal = {
			latex = '\\normalfont',
			css = 'font-style: normal; font-weight: normal; font-variant:normal;'
		}
	}
	-- provide some aliases
	local ALIASES = {
		italics = {'italic'},
		normal = {'normalfont'},
		smallcaps = {'small%-caps'}, -- used as a pattern, so `-` must be escaped
	}

	-- within this function, format is 'css' when css features are needed
	if format:match('html') then
		format = 'css'
	end

	-- ensure str is defined and a string
	str = type(str) == 'string' and str ~= '' and str
				or type(str) == 'Inlines' and #str > 0 and stringify(str)
				or nil

	if str then

		local result = ''

		for feature,definition in pairs(FEATURES) do
			if str:match(feature) and definition[format] then
				result = result..definition[format]
			-- avoid multiple copies by only looking for aliases
			-- if main feature key not found and breaking if we find any alias 
			elseif ALIASES[feature] then 
				for _,alias in ipairs(ALIASES[feature]) do
					if str:match(alias) and definition[format] then
						result = result..definition[format]
						break -- ensures no multiple copies
					end
				end
			end
		end

		return result

	end

	return ''

end