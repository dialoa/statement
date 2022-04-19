--- Setup:length_format: parse font features into the desired format
--@TODO what if a space is provided (space after head)
-- @param len Inlines or string to be interpreted
-- @param format (optional) desired format if other than FORMAT
-- @return string or function or nil
--				string specifying font features in the desired format 
--				or (native format) function Inlines -> Inlines
--				or nil
function Setup:font_format(str, format)
	local format = format or FORMAT
	local result = ''
	-- ensure str is defined and a string
	if not str then
		return nil
	end
	if type(str) ~= 'string' then
		if type(str) == 'Inlines' then
			str = stringify(str)
		else
			return nil
		end
	end

	-- within this function, format is 'css' when css features are needed
	if format:match('html') then
		format = 'css'
	end
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
