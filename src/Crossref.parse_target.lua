---Crossref:parse_target: Parse a crossreference
-- target into flags (if any) and identifier.
--@param str string the crossreference target
--@return id string the identifier proper
--@return flags pandoc List of flags, might be empty
function Crossref:parse_target(str)
	local flag_patterns = {'pre', 'Pre', 'pres', 'Pres', 'g'} -- Lua patterns
	local separator = ':' -- could open to customization in the future
	local flags = pandoc.List:new()
	local id

	---extract_flag: extract one flag from the identifier
	--@param: str, string from which the flag is to be extracted
	--@param: flag, string, flag found
	--@param: remainder, string remainder of the string
	local function extract_flag(str)
		local i,j = str:find('^%w+'..separator)
		-- proceed only if non-empty remainder found
		if j and j < #str then
			local flag = str:sub(i,j - #separator)
			local remainder = str:sub(j+1, #str)
			-- return only if it's an official flag
			for _,pattern in ipairs(flag_patterns) do
				if flag:match(pattern) then
					return flag, remainder
				end
			end
		end
	end

	-- Main function body
	while str do
		local flag, remainder = extract_flag(str)
		if flag then
			flags:insert(flag)
			str = remainder
		else
			id = str
			str = nil
		end
	end

	return id, flags

end