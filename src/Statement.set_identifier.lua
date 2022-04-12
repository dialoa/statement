--- Statement:set_identifier: set an element's id
-- store it with the crossref label in setup.labels_by_id
function Statement:set_identifier(elem)
	local id

	if elem.identifier and elem.identifier ~= '' then
		id = elem.identifier
	elseif self.acronym then
		id = stringify(self.acronym):gsub('[^%w]','-')
	end

	if id and id ~= '' then
		if self.setup.labels_by_id[id] then
			message('WARNING', 'Two statements with the same identifier: '..id..'.'
								..' The second is ignored.')
		else
					self.id = id
					self.setup.labels_by_id[id] = 'CROSSREF'
		end
	end

end