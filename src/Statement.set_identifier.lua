--- Statement:set_identifier: set an element's id
-- store it with the crossref label in setup.labels_by_id
-- Updates:
--		self.identifier
--		self.setup.identifiers
--@param elem pandoc element for which we want to create an id
--@return nil
function Statement:set_identifier(elem)
	elem = elem or self.element
	local identifiers = self.setup.identifiers -- pointer to identifiers table
	local id

	-- safe_register: register id or id-1, id-2 avoiding duplicates
	-- store id and crossref_label in the identifiers table
	-- store kind label if this is a numbered statement
	--@param id string the identifier to be registered
	--@return id, the id generated
	function safe_register(id)
		local new_id = id
		local n = 0
		while identifiers[new_id] do
			n = n + 1
			new_id = id..'-'..tostring(n)
		end
		identifiers[new_id] = {
			statement = true,
			crossref_label = self.crossref_label,
			kind_label = self.is_numbered and kinds[self.kind].label,
		}

		-- udpate the 'self.identifier' field
		self.identifier = new_id
		-- update the element's identifier in case writer functions 
		-- return it to the document
		if self.element.attr then
			self.element.attr.identifier = new_id
		end
		return new_id
	end

	-- Function body

	--		user-specified id?
	if self.identifier then
		id = self.identifier
		local new_id = safe_register(id)
		if new_id ~= id then
			-- if the original id wasn't a statement, make
			-- this original id point to the statement instead.
			-- This recovers from the common mistake of entering
			-- [ref]{#target} instead of [ref](#target)
			if not identifiers[id].statement then
				identifiers[id].try_instead = new_id
				message('WARNING', 	'The ID `'..id..'` you gave to a `'..self.kind..'` statement'
														..' turns out to be a duplicate. Either you used it twice,'
														..' or it matches an automatically-generated section ID,'
														..' or you tried to refer to the statement with '
														..' an empty Span `[]{#'..id..'}` rather than a Link' 
														..' `[](#'..id..') somewhere.'
														.." I've changed the ID to `"..new_id..' and made '
														..' all crossreferences to `'..id..'` point to it'
														..' instead. Some crossreferences may not be correct,'
														..' you should give this statement another ID.')
			else
				message('WARNING', 	'The ID `'..id..'` you gave to a `'..self.kind..'` statement'
														.." turns out to be a duplicate: it's already the ID of"
														..'another statement: '
														..stringify(identifiers[id].crossref_label)..'.'
														..' Either you used it twice, or it happens to match'
														..' the automatically-generated ID of that other statement.'
														.." I've changed it to `"..new_id..' but all crossreferences'
														..' to `'..id..'` will point to the point to the other statement.'
														..' This is probably not what you want, you should '
														..' give this statement another ID.')
			end
		end -- end of changed id warnings

	-- 		acronym?
	elseif self.acronym then
		id = stringify(self.acronym):gsub('[^%w]','-')
		local new_id = safe_register(id)
		if new_id ~= id then
			message('WARNING', 'The acronym `'..id..'` you gave to a `'..self.kind..'` statement'
													..' could not be used as its ID because that ID already existed.'
													.." If you're not planning to crossrefer to this statement, "
													.." that's not a problem. But if you are the crossreferences "
													.." won't work as intended."
													.." Make sure you didn't try to refer to this statement with "
													..' an empty Span `[]{#'..id..'}` rather than a Link' 
													..' `[](#'..id..') somewhere, and otherwise give it a custom ID.'
													.." In the meanwhile I've given it ID "..new_id.." instead."
				)
		end

	--	custom label?
	elseif self.custom_label then
		id = stringify(self.custom_label):lower():gsub('[^%w]','-')
		local new_id = safe_register(id)
		if new_id ~= id then
			message('WARNING', 'The custom label `'..id..'` you gave to a `'..self.kind..'` statement'
													..' could not be used as its ID because that ID already existed.'
													.." If you're not planning to crossrefer to this statement, "
													.." that's not a problem. But if you are the crossreferences "
													.." won't work as intended."
													.." Make sure you didn't try to refer to this statement with "
													..' an empty Span `[]{#'..id..'}` rather than a Link' 
													..' `[](#'..id..') somewhere, and otherwise give it a custom ID.'
													.." In the meanwhile I've given it ID "..new_id.." instead."
				)
		end

	end

end