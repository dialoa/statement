--- Statement:set_identifier: set a statement's id
-- and register it with the crossref manager.
-- Updates:
--		self.identifier
--		self.elem.attr.identifier
--@return nil
function Statement:set_identifier()
	local elem = self.element
	local crossref = self.setup.crossref -- points to the crossref manager
	local style = self.setup.kinds[self.kind].style
	local crossref_font = self.setup.styles[style].crossref_font

	---register: register id using a given mode
	-- store its kind, crossref_label, crossref_font
	-- store the new id in self.identifier and elem.attr.identifier 
	--@param id string the identifier to be registered
	--@param attr map, any attributes that were set by parsing the id
	--@param mode string mode to be used, 'new', 'redirect', 'strict'
	--@return id, the id generated
	function register(id, attr, mode)
		attr = attr or {}
		local final_id

		-- add attributes
		attr.type = 'Statement'
		attr.label = self.crossref_label
		attr.kind = self.kind
		attr.crossref_font = crossref_font

		-- register
		final_id = crossref:register_identifier(id, attr, mode)

		-- udpate the statement's `self.identifier` field
		self.identifier = final_id
		-- update the element's identifier 
		-- (in case writers return it to the document)
		if elem.attr then
			elem.attr.identifier = final_id
		end

		return final_id
	end

	-- MAIN FUNCTION BODY
	
	--		user-specified id?
	if self.identifier then
		local id, attr = crossref:parse_identifier(self.identifier)
		local final_id = register(id, attr, 'redirect')
		if final_id ~= id then
			message('WARNING', 	'The ID `'..id..'` you gave to a `'..self.kind..'` statement'
													..' turns out to be a duplicate. Either you used it twice,'
													..' or it matches an automatically-generated section ID,'
													..' or you tried to refer to the statement with '
													..' an empty Span `[]{#'..id..'}` rather than a Link' 
													..' `[](#'..id..') somewhere.'
													.." I've changed the ID to `"..final_id..' and made '
													..' all crossreferences to `'..id..'` point to it'
													..' instead. Some crossreferences may not be correct,'
													..' you should give this statement another ID.')
	end

	-- 		acronym?
	elseif self.acronym then
		local id = stringify(self.acronym):gsub('[^%w]','-')
		local final_id = register(id, {}, 'new')
		if final_id ~= id then
			message('WARNING', 'The acronym `'..id..'` you gave to a `'..self.kind..'` statement'
													..' could not be used as its ID because that ID already existed.'
													.." If you're not planning to crossrefer to this statement, "
													.." that's not a problem. But if you are the crossreferences "
													.." won't work as intended."
													.." Make sure you didn't try to refer to this statement with "
													..' an empty Span `[]{#'..id..'}` rather than a Link' 
													..' `[](#'..id..') somewhere, and otherwise give it a custom ID.'
													.." In the meanwhile I've given it ID "..final_id.." instead."
				)
		end

	--	custom label?
	elseif self.custom_label then
		local id = stringify(self.custom_label):lower():gsub('[^%w]','-')
		local final_id = register(id, {}, 'new')
		if final_id ~= id then
			message('WARNING', 'The custom label `'..id..'` you gave to a `'..self.kind..'` statement'
													..' could not be used as its ID because that ID already existed.'
													.." If you're not planning to crossrefer to this statement, "
													.." that's not a problem. But if you are the crossreferences "
													.." won't work as intended."
													.." Make sure you didn't try to refer to this statement with "
													..' an empty Span `[]{#'..id..'}` rather than a Link' 
													..' `[](#'..id..') somewhere, and otherwise give it a custom ID.'
													.." In the meanwhile I've given it ID "..final_id.." instead."
				)
		end

	end

end