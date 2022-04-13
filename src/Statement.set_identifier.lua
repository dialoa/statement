--- Statement:set_identifier: set an element's id
-- store it with the crossref label in setup.labels_by_id
-- Updates:
--		self.identifier
--		self.setup.identifiers
--@param elem pandoc element for which we want to create an id
--@return nil
function Statement:set_identifier(elem)
	local identifiers = self.setup.identifiers -- pointer to identifiers table
	local id

	-- register: register id and crossref_label in the identifiers table
	--@param id string the identifier to be registered
	function register(id)
		if id ~= '' then 
			identifiers[id] = {
				statement = true,
				crossref_label = self.crossref_label
			}
			self.identifier = id
		end
	end
	-- safe_register: register id or id-1, id-2 avoiding duplicates
	function safe_register(id)
		local n = 0
		local str = id
		while identifiers[str] do
			n = n + 1
			str = id..'-'..tostring(n)
		end
		register(str)
	end

	-- Function body: try to create an identifier
	local id = elem.identifier or ''
	--		user-specified id?
	if id ~= '' then 
			if identifiers[id] then
				message('WARNING', "A statement's identifier is a duplicate:"
					..' '..id..'. It is ignored, crossreferences may fail.')
			else
				register(id)
			end

	-- 		acronym?
	elseif self.acronym then
		id = stringify(self.acronym):gsub('[^%w]','-')
		safe_register(id)

	--	custom label?
	elseif self.custom_label then
		id = stringify(self.custom_label):lower():gsub('[^%w]','-')
		safe_register(id)
	end

end