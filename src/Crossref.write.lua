---Crossref:write: write a crossreferences list for output
-- The basic output for an item is
-- 		[prefix][core][suffix]
-- whre [core] is:
--		[automatic_prefix ]number
-- Example: [see ][theorem ]1.2[ and following].
-- Uses:
--@param: elem, pandoc Link element
function Crossref:write(references)
	local identifiers = self.identifiers
	local kinds = self.setup.kinds
	local delimiters = self.setup.options.crossref_delimiters
											or {'(',')'}
	local mode = references[1].mode or 'Normal' -- mode from first ref
	local inlines = pandoc.List:new()

	--write_core: create a reference's core text
	local function write_core(reference)
		local inlines = pandoc.List:new()

		-- does it have an automatic prefix?
		local mode = reference.agg_pre_mode 
									or self:get_pre_mode(reference)
		--@TODO: handle lower/upper case, plural
		if mode ~= 'none' then
			local label = kinds[identifiers[reference.id].kind].label
			if label then
				--@TODO formatting here
				inlines:extend(label)
				inlines:insert(pandoc.Space())
			end
		end

		-- is it an aggregate reference?
		if reference.agg_first_id then
			local id1 = reference.agg_first_id
			local id2 = reference.id
			local separator = reference.agg_count == 1
											and { pandoc.Str(','), pandoc.Space() }
											or { pandoc.Str(utf8.char(8211)) } -- en-dash
			inlines:extend(identifiers[id1].label)
			inlines:extend(separator)
			inlines:extend(identifiers[id2].label)
		else
			local label = identifiers[reference.id].label
			if label and #label > 0 then
				inlines:extend(label)
			else
				inlines:insert(pandoc.Str('??'))
			end
		end

		return inlines

	end

	-- MAIN FUNCTION BODY

	-- aggregate sequences of consecutive references
	if self.setup.options.aggregate_crossreferences then
		references = self:aggregate_references(references)
	end

	for i = 1, #references do
		reference = references[i]

		-- create core
		local core = write_core(reference)

		-- values for the link element
		local target = '#'..reference.id
		local title = reference.title and reference.title ~= '' 
									and reference.title:gsub('<>',stringify(core))
									or stringify(core)

		-- build inlines
		if reference.prefix then
			inlines:extend(reference.prefix)
		end
		inlines:insert( pandoc.Link(core, target, title) )
		if reference.suffix then
			inlines:extend(reference.suffix)
		end

		-- add separator if needed
		if #references > 1 and i < #references then
      inlines:extend({pandoc.Str(';'),pandoc.Space()})
    end

	end

	-- adds brackets if needed
	if mode == 'Normal' then
	    inlines:insert(1, pandoc.Str(delimiters[1]))
	    inlines:insert(pandoc.Str(delimiters[2]))
	end

  return inlines

end
