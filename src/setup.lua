--- Setup class: statement filter setup.
-- manages filter options, statement kinds, statement styles.
Setup = {}

--- Setup.options: global filter options
Setup.options = {
	amsthm = true, -- use the amsthm package in LaTeX
	aliases = true, -- use aliases (prefixes, labels) for statement classes
	acronyms = true, -- use acronyms in custom labels
	swap_numbers = false, -- numbers before label
	define_in_header = true, -- defs in header, not local
	supply_header = true, -- modify header-includes 
	only_statement = false, -- only process Divs of 'statement' class
	citations = true, -- allow citation syntax for crossreferences
	language = 'en', -- LOCALE setting
	fontsize = nil, -- document fontsize
	LaTeX_section_level = 1, -- heading level for to LaTeX's 'section'
}

--- Setup.kinds: kinds of statement, e.g. 'theorem', 'proof'
Setup.kinds = {
	-- kindname = { 
	--			prefix = string, crossreference prefix
	--			label = Inlines, statement's label e.g. "Theorem"
	-- 			style = string, style (key of `styles`)
	-- 			counter = string, 'none', 'self', 
	--								<kindname> string, kind for shared counter,
	--								<level> number, heading level to count within
	--			count = nil or number, this kind's counter value
}

--- Setup.styles: styles of statement, e.g. 'plain', 'remark'
Setup.styles = {
	-- stylename = {
	--			do_not_define_in_latex = bool, whether to define in LaTeX 
	--	}
}

--- Setup.aliases: aliases for statement kind names ('thm' for 'theorem')
Setup.aliases = {
	-- aliasname = kindname string, key of the Setup:kinds table
}

--- Setup.counters: list of level counters
Setup.counters = {
	-- 1 = { count = number, count of level 1 headings
	--				 reset = {kind_keys}, list of kind_keys to reset when this counter is 
	--															incremented
	--				format = string, e.g. '%1.%2.' for level_1.level_2. 
	--													or '%p.%s' for <parent string>.<self value>
	--		}
}

--- Setup.identifiers: document identifiers. Populated as we walk the doc
Setup.identifiers = {
	-- identifier = {
	--									is_statement = bool, whether it's a statement
	--									crossref_label = inlines, label to use in crossreferences
	--							}
}

-- Setup.includes: code to be included in header or before first statement
Setup.includes = {
	header = nil,
	before_first = nil,
}

Setup.DEFAULTS = require('Setup.DEFAULTS') -- default kinds and styles

Setup.LOCALE = require('Setup.LOCALE') -- Label translations

Setup.read_options = require('Setup.read_options') -- function to read options

Setup.create = require('Setup.create_kinds_and_styles') -- to create kinds and styles

Setup.create_counters = require('Setup.create_counters') -- to create level counters

Setup.write_counter = require('Setup.write_counter') -- to create level counters

Setup.increment_counter = require('Setup.increment_counter') -- to incremeent a level counter

Setup.update_meta = require('Setup.update_meta') -- to update a document's meta

Setup.length_format = require('Setup.length_format') -- to convert length values

Setup.font_format = require('Setup.font_format') -- to convert font features values

--- Setup:new: construct a Setup object 
--@param meta Pandoc Meta object
--@return a Setup object
function Setup:new(meta)

		-- create an object of Statement class
		local s = {}
		self.__index = self 
		setmetatable(s, self)

		-- read options from document's meta
		s:read_options(meta)

		-- prepare Setup.includes
		s:set_includes()

		-- create kinds and styles
		-- (localizes labels, builds alias map)
		s:create_kinds_and_styles(meta)

		-- prepare counters
		s:create_counters()

		return s
end

--- Setup:set_includes: prepare the Setup.includes table
--@param format string (optional) Pandoc output format, defaults to FORMAT
function Setup:set_includes(format)
	local format = format or FORMAT

	-- LaTeX specific
	if format:match('latex') then

		-- load amsthm package unless option `amsthm` is false
		if self.options.amsthm then
			if not self.includes.header then
				self.includes.header = pandoc.List:new()
			end
			self.includes.header:insert(pandoc.MetaBlocks(pandoc.RawBlock(
															'latex', '\\usepackage{amsthm}'
															)))
		end

		-- \swapnumbers (amsthm package only)
		-- place in header or in body before the first kind definition
		if self.options.amsthm and self.options.swap_numbers then 

			local block = pandoc.RawBlock('latex','\\swapnumbers')
			if self.options.define_in_header then 
					self.includes.header:insert(pandoc.MetaBlocks(block))
			else
				if not self.includes.before_first then
					self.includes.before_first = pandoc.List:new()
				end
				self.includes.before_first:insert(block)
			end

		end

	end

end

--- Setup:get_LaTeX_section_level: determine the heading level
-- corresponding to LaTeX's 'section' and store it in Setup.options
--@param meta document's metadata
--@param format string (optional) output format (defaults to FORMAT)
function Setup:get_LaTeX_section_level(meta,format)
	local format = format or FORMAT
	local top_level = PANDOC_WRITER_OPTIONS.top_level_division
	top_level = top_level:gsub('top-level-','')

	if top_level == 'section' then
		return 1
	elseif top_level == 'chapter' then
		return 2
	elseif top_level == 'part' then
		return 3
	end
	-- top_level is default, infer from documentclass and classoption
	if format == 'latex' and meta.documentclass then
		-- book, scrbook, memoir: section is level 2
		if meta.documentclass == 'book' 
						or meta.documentclass == 'amsbook'
						or meta.documentclass == 'scrbook'
						or meta.documentclass == 'report' then
				return 2 
		elseif meta.documentclass == 'memoir' then
			local level = 2 -- default, unless option 'article' is set
			if meta.classoption then
				for _,option in ipairs(ensure_list(classoption)) do
					if option == 'article' then
						level = 1
					end
				end
			end
			return level
		end
	end
	-- if everything else fails, assume section is 1
	return 1
end

--- Setup:get_level_by_LaTeX_name: convert LaTeX name to Pandoc level
--@param name string LaTeX name
function Setup:get_level_by_LaTeX_name(name) 
	local LaTeX_names = {'book', 'part', 'section', 'subsection', 
						'subsubsection', 'paragraph', 'subparagraph'}
	-- offset value. Pandoc level = LaTeX_names index - offset
	local offset = 3 - self.options.LaTeX_section_level
	-- determine whether `name` is in LaTeX names and where
	for index,LaTeX_name in ipairs(LaTeX_names) do
		if name == LaTeX_name then
			return index - offset
		end
	end

	return nil
end

--- Setup:get_LaTeX_name_by_level: convert Pandoc level to LaTeX name
--@param level number 
function Setup:get_LaTeX_name_by_level(level)
	local LaTeX_names = {'book', 'part', 'section', 'subsection', 
		'subsubsection', 'paragraph', 'subparagraph'}
	-- LaTeX_names[level + offset] = LaTeX name
	local offset = 3 - self.options.LaTeX_section_level

	if type(level)=='number' then
		return LaTeX_names[level + offset]
	end

	return nil
end