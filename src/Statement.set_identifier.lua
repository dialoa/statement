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

	-- safe_register: register id or id-1, id-2 avoiding duplicates
	-- store id and crossref_label in the identifiers table
	-- store kind label if this is a numbered statement
	--@param id string the identifier to be registered
	--@return id, the id generated
	function safe_register(id)
		local n = 0
		local str = id
		while identifiers[str] do
			n = n + 1
			str = id..'-'..tostring(n)
		end
		identifiers[id] = {
			statement = true,
			crossref_label = self.crossref_label,
			kind_label = self.is_numbered and kinds[self.kind].label,
		}
		self.identifier = id
		-- update the element's identifier in case writer functions 
		-- return it to the document
		if self.element.attr then
			self.element.attr.identifier = id
		end
		return str
	end

	-- Function body: try to create an identifier
	local id = elem.identifier or ''
	--		user-specified id?
	if id ~= '' then
			-- if the user-specified id is a duplicate, create a new one and warn
			-- user may have written an empty Span `[]{#id}` instead of `[](#id)`
			if identifiers[id] then
				local new_id = safe_register(id)
				-- storing the new id as something to try instead of the duplicated id
				identifiers[id].try_instead = new_id
				message('WARNING', 	"A "..self.kind.." statement's identifier `"..id.."`"
														..' was a duplicate, I changed it to `'..new_id..'`.'
														..' Some crossreferences may fail.'
														..' Have you used an empty Span `[]{#'..id..'}'
														..' instead of a Link `[](#'..id..') somewhere?')
			else
				safe_register(id)
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