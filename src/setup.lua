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
	definition_lists = true, -- process DefinitionLists
	citations = true, -- allow citation syntax for crossreferences
	count_within = nil, -- default count-within
	pandoc_amsthm = true, -- process pandoc-amsthm style meta and theorems
	language = 'en', -- LOCALE setting
	fontsize = nil, -- document fontsize
	LaTeX_section_level = 1, -- heading level for to LaTeX's 'section'
	LaTeX_in_list_afterskip = '.5em', -- space after statement first item in list
	LaTeX_in_list_rightskip = '2em', -- right margin for statement first item in list
	acronym_delimiters = {'(',')'}, -- in output, in case we want to open this to the user
	info_delimiters = {'(',')'}, -- in output, in case we want to open this to the user
	aggregate_crossreferences = true, -- aggregate sequences of crossrefs of the same type
	counter_delimiter = '.', -- separates section number and statement number
													 --	when writing a statement label or crossreference
}

--- Setup.meta, pointer to the doc's meta
--			needed by the JATS writer
Setup.meta = nil 

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
	--			is_written = nil or boolean, whether the kind def has been written
}

--- Setup.styles: styles of statement, e.g. 'plain', 'remark'
Setup.styles = {
	-- stylename = {
	--		do_not_define_in_latex = bool, whether to define in LaTeX amsthm
	--		is_written = nil or bool, whether the definition has been written
	--		based_on = 'plain' -- based on another style
	--		margin_top = '\\baselineskip', -- space before
	--		margin_bottom = '\\baselineskip', -- space after
	--		margin_left = nil, -- left skip
	--		margin_right = nil, -- right skip
	--		body_font = 'italics', -- body font
	--		indent = nil, -- indent amount
	--		head_font = 'bold', -- head font
	--		punctuation = '.', -- punctuation after statement heading
	--		space_after_head = '1em', -- horizontal space after heading 
	-- 		linebreak_after_head = bool, -- linebreak after heading
	--		heading_pattern = nil, -- heading pattern (not used yet)
	--		crossref_font = 'smallcaps' -- font for crossref labels
	--		custom_label_changes = { -- changes when using a custom label
	--					... (style map fields)
	-- 		}
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

--- Setup.crossref: Crossref object, contains crossref.identifiers table
-- and methods to handle it.
Setup.crossref = nil

-- Setup.includes: code to be included in header or before first statement
Setup.includes = {
	header = nil,
	before_first = nil,
}

-- Setup.LATEX_NAMES: often-used LaTeX names list
Setup.LATEX_NAMES = pandoc.List:new(
											{'book', 'part', 'section', 'subsection', 
											'subsubsection', 'paragraph', 'subparagraph'}
										)

!input Setup.DEFAULTS -- default kinds and styles

!input Setup.LOCALE -- Label translations

!input Setup.validate_defaults -- to validate DEFAULTS files

!input Setup.read_options -- function to read options

!input Setup.create_kinds_and_styles -- to create kinds and styles

!input Setup.create_kinds_and_styles_defaults -- to create default kinds and styles

!input Setup.create_kinds_and_styles_user -- to create user-defined kinds and styles

!input Setup.create_aliases -- to create aliases of kinds keys

!input Setup.set_style -- to create or set a stype

!input Setup.set_kind -- to create or set a stype

!input Setup.create_counters -- to create level counters

!input Setup.write_counter -- to create level counters

!input Setup.increment_counter -- to incremeent a level counter

!input Setup.update_meta -- to update a document's meta

--- Setup:new: construct a Setup object 
--@param meta Pandoc Meta object
--@return a Setup object
function Setup:new(meta)

		-- create an object of Statement class
		local s = {}
		self.__index = self 
		setmetatable(s, self)

		-- set the meta pointer
		s.meta = meta

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

--- Setup:set_LaTeX_section_level: determine the heading level
-- corresponding to LaTeX's 'section' and store it in Setup.options
--@param meta document's metadata
--@param format string (optional) output format (defaults to FORMAT)
function Setup:set_LaTeX_section_level(meta,format)
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
-- returns level if it's already a level
--@param name string or number LaTeX name or level as string or number
--@return level number or nil level
function Setup:get_level_by_LaTeX_name(name)
	LaTeX_names = self.LATEX_NAMES
	-- offset value. Pandoc level = LaTeX_names index - offset
	local offset = 3 - self.options.LaTeX_section_level
	-- if level number we return it
	if tonumber(name) then
		return tonumber(name)
	end
	-- determine whether `name` is in LaTeX names and where
	_,index = LaTeX_names:find(name)
	if index then
		return index - offset
	end
end

--- Setup:get_LaTeX_name_by_level: convert Pandoc level to LaTeX name
-- returns LaTeX name if it's already one
--@param level number or string, level as string or number or LaTeX name
function Setup:get_LaTeX_name_by_level(level)
	LaTeX_names = self.LATEX_NAMES
	-- LaTeX_names[level + offset] = LaTeX name
	local offset = 3 - self.options.LaTeX_section_level
	-- if LaTeX name we return it
	if type(level) == 'string' and LaTeX_names:find(level) then
		return level
	end

	if tonumber(level) then
		return LaTeX_names[tonumber(level) + offset] or nil
	end

	return nil
end