---Setup:update_meta: update a document's metadata
-- inserts the setup.includes.header in the document's metadata
--@param meta Pandoc Meta object
--@return meta Pandoc Meta object
function Setup:update_meta(meta)

	if self.options.supply_header and self.includes.header then

		if meta['header-includes'] then

			if type(meta['header-includes']) == 'List' then
				meta['header-includes']:extend(self.includes.header)
			else
				self.includes.header:insert(1, meta['header-includes'])
				meta['header-includes'] = self.includes.header
			end

		else

			meta['header-includes'] = self.includes.header

		end

	end

	return meta

end

