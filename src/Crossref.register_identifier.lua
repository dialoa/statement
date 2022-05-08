---Crossref:register_identifier: register a new identifier.
-- Different modes are provided
-- 		- 'strict': register only if not already existing
--		- 'redirect': if already present, register under a new
--							id and redirect the original to the new
--		- 'new': register, using a new name if needed
-- The 'redirect' and 'new' modes are always successful.
--@param id string the desired identifier
--@param attr table map of attributes
--@param mode (optional) string, mode (defaults to 'new')
--@return id string the identifier registered or nil
function Crossref:register_identifier(id, attr, mode)
	local identifiers = self.identifiers -- points to the identifiers table
	local id = id or '' -- in non-strict mode, empty id is ok
	local attr = attr or {}
	local mode = mode or 'new'

	-- all identifiers must have a type
	if not attr.type then
		attr.type = 'Unknown'
	end

	if mode == 'strict' and id ~= '' then
		if not identifiers[id] then
			identifiers[id] = attr
			return id
		end
	elseif mode == 'new' or mode == 'redirect' then
		-- ensure we have a new id
		local final_id = id
		local n = 0
		while final_id == '' or identifiers[final_id] do
			n = n + 1
			final_id = id..'-'..tostring(n)
		end
		-- register
		identifiers[final_id] = attr
		-- in redirect mode, redirect old id to new one
		if mode == 'redirect' then
			if identifiers[id] then
				identifiers[id].redirect = final_id
			end
		end
		-- return the final id
		return final_id
	end
end



