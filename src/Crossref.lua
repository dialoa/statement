-- # Crossref class

--- Crossref: class for the Crossref object.
-- The class contains a table of identifiers, and 
-- a constructor for References objects.
Crossref = {}

-- Identifiers map
Crossref.identifiers = {
	-- id = { 
	--				type = string, 'Div', 'Header', ... or 'Statement',
	--				label = inlines, index (1.1, 1.3.2) or crossref label (custom, acronym)
	--				font = string, font specification for the crossref label
	--				kind = string, key of the setup.kinds table
	-- 			}
}

--- References lists
-- the parse functions return a list of reference items.
-- items in these list have the following structure:
-- reference = {
--			id = string, key of the identifiers table,
--			flags = list of strings, flags added to the target,
--			prefix = inlines,
--			suffix =	inlines,
--			mode = nil or string, `Normal` or `InText`
--			text = inlines, user-specified text instead of label (Link references)
-- 			title = string, user-specified title (Link references)
--			agg_first_id = nil or string, id of the first item in a sequence
--			agg_count = nil or number, how many merges happened in aggregating
--	}


!input Crossref.collect_identifiers -- collect pre-existing identifiers

!input Crossref.parse_identifier -- parse any flags in an identifier 

!input Crossref.register_identifier -- register a new identifier

!input Crossref.process -- process a Link or Cite, converting crossreferences

!input Crossref.parse_target -- parse any flags in a reference target

!input Crossref.parse_Link -- tries to read a Link as crossreference

!input Crossref.parse_Cite -- tries to read Cite as crossreference

!input Crossref.write -- write a crossreferences list

!input Crossref.aggregate_references -- aggregate references, e.g. "1.1--1.3"

!input Crossref.get_pre_mode -- get the auto prefix mode of a reference

--- create a crossref object from a pandoc document and setup.
-- @param doc pandoc Document
-- @param setup Setup class object, the document's statements setup
-- @return Crossref object
function Crossref:new(doc, setup)

	-- create an object of Crossref class
	local o = {}
	self.__index = self 
	setmetatable(o, self)

	-- pointers 
	o.setup = setup -- points to the setup, needed by the class's methods
	o.doc = doc -- points to the document

	-- collect ids of non-statement in the Pandoc document
	o:collect_identifiers()

	return o

end
