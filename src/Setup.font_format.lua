--- Setup:length_format: parse font features into the desired format
--@TODO what if a space is provided (space after head)
-- @param len Inlines or string to be interpreted
-- @param format (optional) desired format if other than FORMAT
-- @return string specifying font features in the desired format or ''
function Setup:font_format(str, format)
	local format = format or FORMAT
	local result = ''
	if type(str) ~= 'string' then
		str = stringify(str)
	end

	-- within this function, format is 'css' when css features are needed
	if format:match('html') then
		format = 'css'
	end

	-- FEATURES and their conversion
	local FEATURES = {
		upright = {
			latex = '\\upshape',
			css = 'font-style: italic;',
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
			css = 'font-weight: bold;'
		},
	}
	-- provide 'small-caps' alias
	-- nb, we use the table key as a matching pattern, so `-` is escaped
	FEATURES['small%-caps'] = FEATURES.smallcaps

	for feature,definition in pairs(FEATURES) do
		if str:match(feature) and definition[format] then
			result = result..definition[format]
		end
	end

	return result

end
