---Crossref:write: write a crossreferences list for output
-- The basic output for an item is
-- 		[prefix][core][suffix]
-- whre [core] is:
--		[automatic_prefix ]number
-- Example: [see ][theorem ]1.2[ and following].
-- Uses:
--@param: elem, pandoc Link element
function Crossref:write(references)
	local text = pandoc.text -- Pandoc's text module for utf8 strings
	local identifiers = self.identifiers
	local kinds = self.setup.kinds
	local delimiters = self.setup.options.crossref_delimiters
											or {'(',')'}
	local mode = references[1].mode or 'Normal' -- mode from first ref
	local inlines = pandoc.List:new()

	--write_core: create a reference's core text
	local function write_core(reference)
		local mode = reference.agg_pre_mode 
								or self:get_pre_mode(reference) -- auto prefix setting
		-- if it has a custom text, we return that
		if reference.text then
			return reference.text
		end
		-- otherwise we build inlines
		local inlines = pandoc.List:new()

		-- write auto prefix 
		-- capitalize: label is Inlines and its text might contain utf8
		-- chars, we make the first char of the first Str element upper or
		-- lower case.
		if mode ~= 'none' then
			local auto_pre = kinds[identifiers[reference.id].kind].label
			if auto_pre and auto_pre[1] then
				if auto_pre[1].t == 'Str' then
					local str
					if mode == 'pre' or mode == 'pres' then
						str = text.lower(text.sub(auto_pre[1].text, 1, 1))
					elseif mode == 'Pre' or mode == 'Pres' then
						str = text.upper(text.sub(auto_pre[1].text, 1, 1))
					end
					str = str..text.sub(auto_pre[1].text, 2, -1)
					auto_pre[1].text = str
				end
				inlines:extend(auto_pre)
				inlines:insert(pandoc.Space())
			end
		end

		-- write aggregate reference or simple reference
		if reference.agg_first_id then
			local id1 = reference.agg_first_id
			local id2 = reference.id
			local separator = reference.agg_count == 1
											and { pandoc.Str(','), pandoc.Space() }
											or { pandoc.Str(utf8.char(8211)) } -- en-dash
			inlines:extend(identifiers[id1].label)
			inlines:extend(separator)
			inlines:extend(identifiers[id2].label)
		else -- simple reference
			local label = identifiers[reference.id].label
			if label and #label > 0 then
				inlines:extend(label)
			else
				inlines:insert(pandoc.Str('??'))
			end
		end

		-- apply crossref_font if we have one
		local crossref_font = identifiers[reference.id].crossref_font
		if crossref_font then
			inlines = Helpers.font_format_native(crossref_font)(inlines)
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
