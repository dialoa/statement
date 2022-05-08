---Walker:crossreferences: creates a Blocks filter to 
-- handle crossreferences.
-- Links with empty content get crossref_label as their content
-- Uses:
--	self.setup.options.citations: whether to use citation syntax
--@return filter, table of functions (pandoc Filter)
function Walker:crossreferences()
	local options = self.setup.options
	local crossref = self.setup.crossref
	local filter = {}

	filter.Link = function (link)
					return crossref:process(link)
				end

	if options.citations then
		filter.Cite = function (cite)
						return crossref:process(cite)
					end
	end

	return filter

end
