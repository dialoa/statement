--- update_meta: update the document's Meta element
--@param meta document's Meta element
--@return meta pandoc Meta object, updated meta or nil
local function update_meta(meta)

	-- only return if updated
	local is_updated = false

	-- update header-includes
	if options.supply_header then

		if meta['header-includes'] then
			meta['header-includes'] = 
				ensure_list(meta['header-includes']):extend(header_includes)
		else
			meta['header-includes'] = header_includes
		end
		is_updated = true

	end

	return is_updated and meta or nil
end
