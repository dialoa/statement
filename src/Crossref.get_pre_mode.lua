---Crossref.get_pre_mode: what auto prefix an item uses
	--@return string auto prefix flag or 'none'
function Crossref:get_pre_mode(item)
	local flag_pattern = '^[pP]res?$'

	for _,flag in ipairs(item.flags) do
		if flag:match(flag_pattern) then
			return flag
		end
	end
	return 'none'
end
