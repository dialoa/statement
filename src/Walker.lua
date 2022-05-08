-- # Walker class

--- Walker: class to hold methods that walk through the document
Walker = {}

!input Walker.walk -- process blocks

!input Walker.crossreferences -- filter to process crossreferences to statements

!input Walker.statements_in_lists -- filter, LaTeX hack for statements within lists

-- Walker:new: create a Walker class object based on document's setup
--@param setup a Setup class object
--@param doc Pandoc document
--@return Walker class object
function Walker:new(setup, doc)

	-- create an object of the Walker class
	local o = {}
	self.__index = self 
	setmetatable(o, self)

	-- pointer to the setup table
	o.setup = setup

	-- pointer to the blocks list
	o.blocks = doc.blocks

	-- add crossreference manager to the setup
	o.setup.crossref = Crossref:new(doc, setup)

	return o

end