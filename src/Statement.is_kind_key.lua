---Statement:is_kind_key: whether a string is a kind key or an alias.
-- If yes, return the kind key.
--@param str string to be tested
--@param setup (optional) a Setup class object, to be used when
--			the function is called from the setup object
--@return kind_key string a key of the kinds table
function Statement:is_kind_key(str, setup)
	setup = setup or self.setup
	local kinds = setup.kinds -- points to the kinds table
	local options = setup.options -- points to the options table
	local aliases = setup.aliases -- pointed to the aliases table

	-- safety check
	if type(str) ~= 'string' then
		message('ERROR', 'Testing whether a non-string is a kind key.'
											.. 'This should not have happened.')
		return
	end

	if kinds[str] then
		return str
	else
		-- try lowercase match, 
		-- and aliases that are all lowercase
		str = str:lower()
		if kinds[str] then
			return str
		elseif aliases[str] then
			return aliases[str]
		end
	end

end
