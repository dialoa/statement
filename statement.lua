--[[-- # Statement - a Lua filter for statements in Pandoc's markdown

This Lua filter provides support for statements (principles,
arguments, vignettes, theorems, exercises etc.) in Pandoc's markdown.

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@author Thomas Hodgson <hello@twshodgson.net>
@copyright 2021 Julien Dutant, Thomas Hodgson
@license MIT - see LICENSE file for details.
@release 0.3

]]

-- # Global variables
stringify = pandoc.utils.stringify

-- options map
options = {
	amsthm = true, -- use the amsthm package in LaTeX
	aliases = true, -- use aliases (prefixes, labels) for statement classes
	swap_numbers = false, -- numbers before label
	define_in_header = true, -- defs in header, not local
	supply_header = true, -- modify header-includes 
	only_statement = false, -- only process Divs of 'statement' class
	fontsize = nil, -- document fontsize
}
-- kinds map. statement must exist
kinds = {
	-- prefix = string, crossreference prefix
	-- style = string, style (key of `styles`)
	-- counter = string, counter ('none', 'self', heading level,
	--			heading type, statement kind for shared counter)
}
-- styles map
styles = {}
-- alias map
aliases = {}
-- material to add in header 
header_includes = pandoc.List:new()
-- material to add in header (before defs) or at the first definition
-- make a list of blocks to trigger an insertion before first definition
before_definitions_includes = nil
-- LaTeX levels map
LaTeX_levels = {'section', 'subsection', 'subsubsection', 
	'paragraph', 'subparagrah'}
LaTeX_levels[0] = 'chapter'
LaTeX_levels[-1] = 'part'
LaTeX_levels[-2] = 'book'

-- modules
-- # Helper functions

--- message: send message to std_error
-- @param type string INFO, WARNING, ERROR
-- @param text string message text
function message(type, text)
    local level = {INFO = 0, WARNING = 1, ERROR = 2}
    if level[type] == nil then type = 'ERROR' end
    if level[PANDOC_STATE.verbosity] <= level[type] then
        io.stderr:write('[' .. type .. '] Collection lua filter: ' 
            .. text .. '\n')
    end
end

--- type: pandoc-friendly type function
-- pandoc.utils.type is only defined in Pandoc >= 2.17
-- if it isn't, we extend Lua's type function to give the same values
-- as pandoc.utils.type on Meta objects: Inlines, Inline, Blocks, Block,
-- string and booleans
-- Caution: not to be used on non-Meta Pandoc elements, the 
-- results will differ (only 'Block', 'Blocks', 'Inline', 'Inlines' in
-- >=2.17, the .t string in <2.17).
local type = pandoc.utils.type or function (obj)
        local tag = type(obj) == 'table' and obj.t and obj.t:gsub('^Meta', '')
        return tag and tag ~= 'Map' and tag or type(obj)
    end

--- ensure_list: turns an element into a list if needed
-- If elem is nil returns an empty list
-- @param elem a Pandoc element
-- @return a Pandoc List
function ensure_list(elem)
	return type(elem) == 'List' and elem or pandoc.List:new({elem})
end
--- length_format: parse a length in the desired format
-- @param len Inlines or string to be interpreted
-- @param format (optional) desired format if other than FORMAT
-- @return string specifying the length in the desired format or ''
function length_format(str, format)
	local format = format or FORMAT
	-- within this function, format is 'css' when css lengths are needed
	if format:match('html') then
		format = 'css'
	end

	-- UNITS and their conversions
	local UNITS = {
		pc = {},	-- pica, 12pt
		pt = {},	-- point, 1/72.27 inch, 28.45 mm
		cm = {}, 	-- cm
		mm = {}, 	-- mm
		bp = { 		-- big point, 1/72 inch, 1.00375 pt
			css = {1.00375, 'pt'},
		},
		dd = { 		-- dido point, 1.07 pt
			css = {1.07, 'pt'},
		},
		cc = { 		-- cicero, 12dd, 12.84 pt
			css = {12.84, 'pt'},
		},
		sp = { 		-- scaled pt, 1/65536 pt
			css = {28.45/65536, 'mm'},
		},
		px = { 		-- pixel, using default conversion 16px = 12pt
			latex = {3/4, 'pt'},
		},
		em = {},	-- em, width of 'm'
		ex = {},	-- ex, height of 'x'
		mu = {		-- mu, 1/18 of em
			css = {1/18, 'em'},
		},
		ch = {		-- width of '0', roughly .5 em
			latex = {0.5, 'em'},
		},
		rem = {		-- root element font size
					-- proper latex conversion needs doc's fontsize
			latex = {1, 'em'},
		},
		vw = { 		-- 1% of the viewport's width
			latex = {0.01, '\\textwidth'},
		},
		vh = {		-- 1% of the viewport's height
			latex = {0.01, '\\textheight'},
		},
		vmin = { 	-- 1% of the viewport's minimal dimension
			latex = {0.01, '\\textwidth'},
		},
		vmax = {	-- 1% of the viewport's maximal dimension
			latex = {0.01, '\\textheight'},
		},
	}
	-- '%' and 'in' keys can't be used in the constructor, add now
	UNITS['in'] = {} 	-- inch, 72.27 pt
	UNITS['%'] = {		-- %, percentage of the parent element's width
			latex = {0.01, '\\linewidth'}
	}
	-- LATEX_LENGTHS and their conversions
	local LATEX_LENGTHS = {
		baselineskip = {	-- height between lines, roughly 2.7 ex
			css = {2.7, 'ex'},
		},
		linewidth = {		-- line width, use length of the parent element
			css = {100, '%'},
		},
		textwidth = {		-- width of text, use length of the parent element
			css = {100, '%'},
		},
		paperwidth = {		-- paper width, use viewport width
			css = {100, 'vw'}
		},
		paperheight = {		-- paper width, use viewport height
			css = {100, 'vh'}
		},
		evensidemargin = {	-- even side margin, 40pt or 6.5% paperwidth
			css = {6.5, 'vw'},
		},
		oddsidemargin = {	-- odd side margin, 40pt or 6.5% paperwidth
			css = {6.5, 'vw'},
		},
		topmargin = {		-- top margin, about half of side margins
			css = {3, 'vw'}
		},
		parindent = {		-- parindent; @TODO better read meta.indent
			css = {1, 'em'}
		},
		tabcolsep = {		-- separation of table columns, typically .5em
			css = {.5, 'em'}
		},
		columnsep = {		-- separation of text columns, roughly 0.8 em
			css = {0.8, 'em'},
		},
	}
	-- add `\` to LATEX_LENGTHS keys
	local new_latex_lengths = {} -- needs to make a copy
	for key,value in pairs(LATEX_LENGTHS) do
		new_latex_lengths['\\'..key] = value
	end
	LATEX_LENGTHS = new_latex_lengths

	--- parse_length: parse a '<number><unit>' string.
	-- checks the unit against UNITS and LATEX_LENGTHS
	--@param str string to be parsed
	--@return number amount parsed
	--@return table with `amount` and `unit` fields 
	local function parse_length(str)
		if type(str) ~= 'string' then
			return nil
		end

		local amount, unit
		-- match number and unit, possibly separated by spaces
		-- nb, %g for printable characters except spaces
		amount, unit = str:match('%s*(%-?%s*%d*%.?%d*)%s*(%g+)%s*')
		-- need to remove spaces from `amount` before attempting tonumber
		if amount then amount = amount:gsub(' ','') end
		-- check that `amount` is a number and `unit` a legit unit
		-- convert them if a conversion is provided for `format`
		if amount and tonumber(amount) then
			if UNITS[unit] or LATEX_LENGTHS[unit] then
				amount = tonumber(amount)
				-- conversion if available
				if UNITS[unit] and UNITS[unit][format] then
					amount = amount * UNITS[unit][format][1]
					unit = UNITS[unit][format][2]
				elseif LATEX_LENGTHS[unit] and LATEX_LENGTHS[unit][format] then
					amount = amount * LATEX_LENGTHS[unit][format][1]
					unit = LATEX_LENGTHS[unit][format][2]
				end
				-- return result as table
				return { 
					amount = amount,
					unit = unit,
				}
			end -- unit not legit
		end -- amount not a number
	end

	--- parse_plus_minus: parse a '<length>plus<length>minus<length>'
	-- string.
	--@param str string to be parse
	--@return table with `main`, `plus`, `minus` fields, each a
	-- 	table with `amount` and `unit` fields or nil
	local function parse_plus_minus(str)

		local main, plus, minus

		-- special case: length is just '0'
		if tonumber(str) and tonumber(str) == 0 then
			return {
					main = {amount = 0, unit = 'em'} 
				}
		end
		-- otherwise try matching plus and minus
		if not main then
			main,plus,minus = str:match('(.*)plus(.*)minus(.*)')
		end
		if not main then
			-- illegal in LaTeX but we'll allow it
			main,minus,plus = str:match('(.*)minus(.*)plus(.*)')
		end
		if not main then
			main,plus = str:match('(.*)plus(.*)')
		end
		if not main then
			main,minus = str:match('(.*)minus(.*)')
		end
		if not main then
			main = str
		end
		-- parse each into amount and unit (or nil if unintelligible)
		return {
			main = parse_length(main),
			plus = parse_length(plus),
			minus = parse_length(minus),
		}

	end

	-- MAIN BODY of the function

	-- ensure str is a string
	if not type(str) == 'string' then
		if type(str) == 'Inlines' then
			str = stringify(str)
		else
			return nil
		end
	end

	-- parse `str` into a length table
	-- length = {
	--		main = { amount = number, unit = string} or nil
	--		plus = { amount = number, unit = string} or nil
	--		minus = { amount = number, unit = string} or nil
	-- }
	local length = parse_plus_minus(str)
	
	-- issue a warning if table found
	if not length or not length.main then
		message('WARNING', 
			'Could not parse the length specification: '..str..'.')
		return nil
	end

	-- return a string appropriate to the output format
	-- LaTeX: <number><unit> plus <number><unit> minus <number><unit>
	-- css: <number><unit>
	if format == 'latex' then

		local result = string.format('%.10g', length.main.amount)
						.. length.main.unit
		for _,key in ipairs({'plus','minus'}) do
			if length[key] then
				result = result..' '..key..' '
					.. string.format('%10.g', length[key].amount)
					.. length[key].unit
			end
		end

		return result

	elseif format == 'css' then

		local result = string.format('%.10g', length.main.amount)
						.. length.main.unit

		return result

	else -- other formats: return nothing

		return nil

	end

end
--- extract_first_bal_brackets: extract the first content found between 
-- balanced brackets from an Inlines list, searching forward or 
-- backwards. Returns that content and the reminder, or nil and the 
-- original content.
-- @param inlines an Inlines list
-- @param direction string, 'reverse' or 'forward' search direction
-- @param delimiters table of beginning and ending delimiters, 
--		e.g. {'[',']'} for square brackets. Defaults to {'(',')'}
-- @return bracketed Inlines, Inlines bracketed content found, or nil
-- @return remainder Inlines, remainder of the content after extraction,
-- 		or all the content if nothing has been found.
function extract_first_bal_brackets(inlines, direction, delimiters)

	-- check and load parameters
	local bb, eb = '(', ')'
	local reverse = false
	if type(inlines) ~= 'Inlines' or #inlines == 0 then
		return nil, inlines
	end
	if direction == 'reverse' then reverse = true end
	if delimiters and type(delimiters) == 'table' 
		and #delimiters == 2 then
			bb, eb = delimiters[1], delimiters[2]
	end
	-- in reverse mode swap around open and closing delimiters
	if reverse then
		bb, eb = eb, bb
	end

	-- functions to accomodate the direction of processing
	function first_pos(list)
		return reverse and #list or 1
	end
	function last_pos(list)
		return reverse and 1 or #list
	end
	function insert_last(list, item)
		if reverse then list:insert(1, item) else list:insert(item) end
	end
	function insert_first(list, item)
		if reverse then list:insert(item) else list:insert(1, item) end
	end
	function first_item(list) 
		return list[first_pos(list)]
	end
	function first_char(s)
		return reverse and s:sub(-1,-1) or s:sub(1,1)
	end
	function all_but_first_char(s)
		return reverse and s:sub(1,-2) or s:sub(2,-1)
	end
	function append_to_str(s, ch)
		return reverse and ch..s or s..ch
	end

	-- prepare return values
	local bracketed, rest = pandoc.List:new(), inlines:clone()

	-- check that we start (end, in reverse mode) 
	-- with a beginning delimiter. If yes remove it
	if first_item(rest).t ~= 'Str' 
		or first_char(first_item(rest).text) ~= bb then
			return nil, inlines
	else
		-- remove the delimiter. special case: Str is just the delimiter
		if first_item(rest).text == bb then
			rest:remove(first_pos(rest))
			-- remove leading/trailing space after bracket if needed
			if first_item(rest).t == 'Space' then
				rest:remove(first_pos(rest))
			end
		else -- standard case, bracket is just the first char of Str
			first_item(rest).text = all_but_first_char(
										first_item(rest).text)
		end
	end

	-- loop to go through all Str elements and find the balanced
	-- closing bracket
	local nb_brackets = 1

	while nb_brackets > 0 and #rest > 0 do

		-- extract first element
		local elem = first_item(rest)
		rest:remove(first_pos(rest))

		-- non Str elements are just stored in the bracketed content
		if elem.t ~= 'Str' then 
			insert_last(bracketed, elem)
		else
		-- Str elements: scan for brackets

			local str = elem.text
			local bracketed_part, outside_part = '', ''
			while str:len() > 0 do

				-- extract first char
				local char = first_char(str)
				str = all_but_first_char(str)

				-- have we found the closing bracket? if yes,
				-- store the reminder of the string without the bracket.
				-- if no, change the bracket count if needed and add the
				-- char to bracketed material
				if char == eb and nb_brackets == 1 then
					nb_brackets = 0
					outside_part = str
					break
				else
					if char == bb then
						nb_brackets = nb_brackets + 1
					elseif char == eb then
						nb_brackets = nb_brackets -1
					end
					bracketed_part = append_to_str(bracketed_part, char)
				end
			end

			-- store the bracketed part
			if bracketed_part:len() > 0 then
				insert_last(bracketed, pandoc.Str(bracketed_part))
			end
			-- if there is a part outside of the brackets,
			-- re-insert it in rest
			if outside_part:len() > 0 then
				insert_first(rest, pandoc.Str(outside_part))
			end

		end

	end

	-- if nb_bracket is down to 0, we've found balanced brackets content,
	-- otherwise return empty handed
	if nb_brackets == 0 then
		return bracketed, rest
	else
		return nil, inlines
	end

end
-- # Statement class

--- Statement: class for statement objects.
-- @field kind string the statement's kind (key of the `kinds` table)
-- @field id string the statement's id
-- @field cust_label Inlines the statement custom's label, if any
-- @field info Inlines the statement's info
Statement = {
	kind = nil, -- string, key of `kinds`
	id = nil, -- string, Pandoc id
	cust_label = nil, -- Inlines, user-provided label
	info = nil, -- Inlines, user-provided info
	content = nil, -- Blocks, statement's content
}
--- create a statement object from a pandoc element.
-- @param elem pandoc Div or list item (= table list of 2 elements)
-- @param kind string (optional) statement's kind (key of `kinds`)
-- @return statement object or nil if elem isn't a statement
function Statement:new(elem)

	local kind = Statement:find_kind(elem)
	if kind then

		-- create an object of Statement class
		o = {}
		self.__index = self 
		setmetatable(o, self)

		-- populate the object
		-- kind
		o.kind = kind
		o.content = elem.content
		o:extract_info()

		-- return
		return o
	
	else
		return nil
	end

end
--- find_kind: find whether an element is a statement and of what kind
-- This function extracts custom label and info from self.content,
-- as these will be needed to determine the final kind.
-- @param elem pandoc Div or item in a pandoc DefinitionList
-- @return string or nil the key of `kinds` if found, nil otherwise
function Statement:find_kind(elem)

	if elem.t and elem.t == 'Div' then

		-- collect the element's classes that match a statement kind
		-- check aliases if `options.aliases` is true
		local matches = pandoc.List:new()
		for _,class in ipairs(elem.classes) do
			if kinds[class] and not matches:find(class) then
				matches:insert(class)
			elseif options.aliases
				and aliases[class] and not matches:find(aliases[class]) then
				matches:insert(aliases[class])
			end
		end

		-- return if no match
		if #matches == 0 then return nil end
		-- return if we only process 'statement' Divs and it isn't one
		if options.only_statement and not matches:find('statement') then
			return nil
		end

		-- if we have other matches that 'statement', remove the latter
		if #matches > 1 and matches:includes('statement') then
			local _, pos = matches:find('statement')
			matches:remove(pos)
		end

		-- warn if we still have more than one match
		if #matches > 1 then
			local str = ''
			for _,match in ipairs(matches) do
				str = str .. ' ' .. match
			end
			message('WARNING', 'A Div matches several statement kinds: '
				.. str .. '. Treated as kind '.. matches[1] ..'.')
		end

		-- extract custom label and info, if any



		-- kind must be modified if the statement has a custom label
		-- or has the 'unnumbered' class
		local new_kind

		-- return the first match, a key of `kinds`
		return matches[1]

	elseif type(elem) == 'table' then

		-- process DefinitionList items here
		-- they are table with two elements:
		-- [1] Inlines, the definiens
		-- [2] Blocks, the definiendum

	end

	return nil -- not a statement kind

end

--- extract_label: extract label and acronym from a statement Div.
--@TODO adapt to the class, use self.content
-- A label is a Strong element at the beginning of the Div, ending or 
-- followed by a dot. An acronym is between brackets, within the label
-- at the end of the label. If the label only contains an acronym,
-- it is used as label, brackets preserved.
-- if `acronym_mode` is set to false we do not search for acronyms. 
-- @param div a pandoc Div element (of class `statement`)
-- @param acronym_mode bool whether to search for an acronym
-- @param delimiters table acronym delimiters; default {'(',')'}
-- @return lab, acro, div, where`label` and `acronym` are Inlines or 
-- or nil, and `div` the pandoc Div element with label removed. 
function Statement:extract_label(div, acronym_mode, delimiters)

	if acronym_mode == false then else acronym_mode = true end
	if not delimiters or type(delimiters) ~= 'table' 
		or #delimiters ~= 2 then
			delimiters = {'(',')'}
	end

	local first_block, lab, acro = nil, nil, nil
	local has_label = false

	-- first block must be a Para that starts with a Strong element
	if not div.content[1] or div.content[1].t ~= 'Para' 
		or not div.content[1].content
		or div.content[1].content[1].t ~= 'Strong' then
			return nil, nil, div
	else
		first_block = div.content[1]:clone() -- Para element
		lab = first_block.content[1] -- Strong element
		first_block.content:remove(1) -- take the Strong elem out
	end

	-- the label must end by or be followed by a dot
	-- if a dot is found, take it out.
	-- ends by a dot?
	if lab.content[#lab.content] 
		and lab.content[#lab.content].t == 'Str'
		and lab.content[#lab.content].text:match('%.$') then
			-- remove the dot
			if lab.content[#lab.content].text:len() > 1 then
				lab.content[#lab.content].text =
					lab.content[#lab.content].text:sub(1,-2)
				has_label = true
			else -- special case: Str was just a dot
				lab.content:remove(#lab.content)
				-- remove trailing Space if needed
				if lab.content[#lab.content]
					and lab.content[#lab.content].t == 'Space' then
						lab.content:remove(#lab.content)
				end
				-- do not validate if empty
				if #lab.content > 0 then
					has_label = true
				end
			end
	end
	-- followed by a dot?
	if first_block.content[1]
		and first_block.content[1].t == 'Str'
		and first_block.content[1].text:match('^%.') then
			-- remove the dot
			if first_block.content[1].text:len() > 1 then
				first_block.content[1].text =
					first_block.content[1].text:sub(2,-1)
					has_label = true
			else -- special case: Str was just a dot
				first_block.content:remove(1)
				-- validate even if empty
				has_label = true
			end
	end

	-- search for an acronym within the label
	-- we only store it if removing it leaves some label
	local saved_content = lab.content:clone()
	acro, lab.content = extract_first_bal_brackets(lab.content, 'reverse')
	if acro and #lab.content == 0 then
		acro, lab.content = nil, saved_content
	end

	-- remove trailing Space on the label if needed
	if #lab.content > 0 and lab.content[#lab.content].t == 'Space' then
		lab.content:remove(#lab.content)
	end

	-- remove leading Space on the first block if needed
	if first_block.content[1] 
		and first_block.content[1].t == 'Space' then
			first_block.content:remove(1)
	end

	-- return label, modified div if label found, original div otherwise
	if has_label then
		div.content[1] = first_block
		return lab, acro, div
	else
		return nil, nil, div
	end
end

--- extract_info: extra specified info from the statement's content.
-- Scans the content's first block for an info specification (Cite
-- or text within delimiters). If found, remove and place in the
-- statement's `info` field.
-- This should be run after extracting any custom label. 
function Statement:extract_info()

	-- first block must be Para or Plain
	if self.content and 
	  (self.content[1].t=='Para' or self.content[1].t=='Plain') then

	  	local first_block = self.content[1]:clone()
	  	local inf

		-- remove one leading space if any
		if first_block.content[1].t == 'Space' then
			first_block:remove(1)
		end

		-- info must be a Cite element, or bracketed content - not both
		if first_block.content[1].t == 'Cite' then
			inf = pandoc.Inlines(first_block.content[1])
			first_block.content:remove(1)
		else
			-- bracketed content?
			inf, first_block.content = 
				extract_first_bal_brackets(first_block.content)
		end

		-- if info found, save it and save the modified block
		if inf then
			self.info = inf
			self.content[1] = first_block
		end

	end

end

--- format_kind: format the statement's kind.
-- If the statement's kind is not yet define, create blocks to define
-- it in the desired output format. These blocks are added to
-- `header_includes` or returned to be added locally, depending
-- on the `options.define_in_header` setting.
-- @param kind string (optional) kind to be formatted, if not self.kind
-- @param format string (optional) format desired if other than FORMAT
-- @return blocks or nil, blocks to be added locally if any
function Statement:format_kind(kind, format)
	local blocks = pandoc.List:new()
	local format = format or FORMAT
	local kind = kind or self.kind

	-- check if the kind is already defined
	if kinds[kind].is_defined then
		return
	else
		kinds[kind].is_defined = true
	end

	-- do we have before_definitions_includes to include before any
	-- definition? if yes include it here and wipe it out
	if before_definitions_includes then
		blocks:extend(before_definitions_includes)
		before_definitions_includes = nil
	end

	-- format
	if format:match('latex') then
	
		local label = kinds[kind].label 
						or pandoc.Inlines(pandoc.Str(''))
		local counter = kinds[kind].counter or 'none'
		local shared_counter, counter_within

		-- identify counter_within and shared_counter
		if counter ~= 'none' and counter ~= 'self' then
			if type(counter)=='number' and LaTeX_levels[counter] then
				counter_within = LaTeX_levels[counter]
			elseif kinds[counter] then
				shared_counter = counter
			else -- unintelligible, default to 'self'
				message('WARNING', 'unintelligible counter for kind'
					.. kind '. Defaulting to `self`.')
				counter = 'self'
			end
		end
		-- if shared counter, its kind must be defined before
		if shared_counter then
			local extra_blocks = self:format_kind(shared_counter)
			if extra_blocks then
				blocks:extend(extra_blocks)
			end
		end

		-- amsthm provides `newtheorem*` for unnumbered kinds
		local latex_cmd = options.amsthm and counter == 'none' 
			and '\\newtheorem*' or '\\newtheorem'

		-- \newtheorem{kind}{label}
		-- \newtheorem{kind}[shared_counter]{label}
		-- \newtheorem{kind}{label}[counter_within]

		local inlines = pandoc.List:new()
		inlines:insert(
			pandoc.RawInline('latex', latex_cmd .. '{'
				.. kind ..'}')
		)
		if shared_counter then
			inlines:insert(
			  pandoc.RawInline('latex', '['..shared_counter..']')
			)
		end
		inlines:insert(pandoc.RawInline('latex','{'))
		inlines:extend(label)
		inlines:insert(pandoc.RawInline('latex','}'))
		if counter_within then
			inlines:insert(
			  pandoc.RawInline('latex', '['..counter_within..']')
			)
		end
		blocks:insert(pandoc.Plain(inlines))

	elseif format:match('html') then

	else -- any other format, no way to define statement kinds

	end

	-- place the blocks in header_includes or return them
	if options.define_in_header then
		header_includes:extend(blocks)
		return {}
	else
		return blocks
	end

end

--- format: format the statement.
-- @param format string (optional) format desired if other than FORMAT
-- @return Blocks blocks to be inserted. 
function Statement:format(format)
	local blocks = pandoc.List:new()
	local format = format or FORMAT

	-- format the kind if needed
	-- if local blocks are returned, insert them
	local format_kind_local_blocks = self:format_kind()
	if format_kind_local_blocks then
		blocks:extend(format_kind_local_blocks)
	end

	-- format the statement
	if format:match('latex') then

		-- \begin{kind}[info inlines] content blocks \end{kind}
		local inlines = pandoc.List:new()
		inlines:insert(pandoc.RawInline('latex', 
							'\\begin{' .. self.kind .. '}'))
		if self.info then
			inlines:insert(pandoc.RawInline('latex', '['))
			inlines:extend(self.info)
			inlines:insert(pandoc.RawInline('latex', ']'))
		end
		blocks:insert(pandoc.Plain(inlines))
		blocks:extend(self.content)
		blocks:insert(pandoc.RawBlock('latex',
							'\\end{' .. self.kind .. '}'))

	elseif format:match('html') then

	else -- other formats, use blockquote

		-- prepare the statement heading
		local heading = pandoc.List:new()
		if kinds[self.kind].label then
			local inlines = pandoc.List:new()
			inlines:extend(kinds[self.kind].label)
			inlines:insert(pandoc.Space())
			inlines:insert(pandoc.Str('1.1')) -- placeholder for the counter
			inlines:insert(pandoc.Str('.')) -- delimiter
			heading:insert(pandoc.Strong(inlines))
		end

		-- info?
		if self.info then 
			heading:insert(pandoc.Space())
			heading:insert(pandoc.Str('('))
			heading:extend(self.info)
			heading:insert(pandoc.Str(')'))
		end

		-- combine statement heading with the first paragraph if any
		if self.content[1] and self.content[1].t == 'Para' then
			heading:insert(pandoc.Space())
			heading:extend(self.content[1].content)
		end

		-- insert the heading as first paragraph of content
		if #heading > 0 then
			self.content:insert(1, pandoc.Para(heading))
		end

		-- place all the content blocks in blockquote
		blocks:insert(pandoc.BlockQuote(self.content))

	end

	return blocks

end
--- setup: read options from meta and setup global variables
--@param meta document's Meta element
local function setup(meta)

	-- variables
	local language = 'en'

	-- constants: some defaults values for kinds and localisation
	local KINDS_NONE = {
		statement = {prefix = 'sta', style = 'empty', counter='none'},		
	}
	local KINDS_BASIC = {
		theorem = { prefix = 'thm', style = 'plain', counter = 1 },
		corollary = { prefix = 'cor', style = 'plain', counter = 'theorem' },
		lemma = { prefix = 'lem', style = 'plain', counter = 'theorem' },
		proposition = {prefix = 'prop', style = 'plain', counter = 'theorem' },
		conjecture = {prefix = 'conj', style = 'plain', counter = 'theorem' },
		fact = { style = 'plain', counter = 'theorem'},
		definition = {prefix = 'defn', style = 'definition', counter = 'theorem'},
		example = {prefix = 'exa', style = 'definition', counter = 'theorem'},
		problem = {prefix = 'prob', style = 'definition', counter = 'theorem'},
		exercise = {prefix = 'xca', style = 'definition', counter = 'theorem'},
		solution = {prefix = 'sol', style = 'definition', counter = 'theorem'},
		remark = {prefix = 'rem', style = 'remark', counter = 'theorem'},
		claim = {prefix = 'claim', style = 'remark', counter = 'theorem'},
		proof = {prefix = 'claim', style = 'proof', counter = 'none'},
	}
	KINDS_BASIC.statement = KINDS_NONE.statement
	-- local KINDS_AMS = {
	-- 	statement = {prefix = 'sta', style = 'empty', counter='none'},
	-- 	theorem = { prefix = 'thm', style = 'plain', counter = 1 },
	-- 	corollary = { prefix = 'cor', style = 'plain', counter = 'theorem' },
	-- 	lemma = { prefix = 'lem', style = 'plain', counter = 'theorem' },
	-- 	proposition = {prefix = 'prop', style = 'plain', counter = 'theorem' },
	-- 	conjecture = {prefix = 'conj', style = 'plain', counter = 'theorem' },
	-- 	fact = { style = 'plain', counter = 'theorem'},
	-- 	definition = {prefix = 'defn', style = 'definition', counter = 'theorem'},
	-- 	example = {prefix = 'exa', style = 'definition', counter = 'theorem'},
	-- 	problem = {prefix = 'prob', style = 'definition', counter = 'theorem'},
	-- 	exercise = {prefix = 'xca', style = 'definition', counter = 'theorem'},
	-- 	solution = {prefix = 'sol', style = 'definition', counter = 'theorem'},
	-- 	remark = {prefix = 'rem', style = 'remark', counter = 'theorem'},
	-- 	claim = {prefix = 'claim', style = 'remark', counter = 'theorem'},
	-- 	proof = {prefix = 'claim', style = 'proof', counter = 'theorem'},
	-- }
	-- KINDS_AMS.statement = KINDS_AMS.statement
	local STYLES_NONE = {
		empty = {
			margin_top = '1em',
			margin_bottom = '1em',
			margin_left = '2em',
			margin_right = '2em',
			indent = '0pt',
			head_font = nil,
			label_punctuation = '.',
			space_after_head = nil,
			heading_pattern = nil,
		},		
	}
	local STYLES_AMSTHM = {
		plain = { do_not_define_in_latex = true },
		definition = { do_not_define_in_latex = true },
		remark = { do_not_define_in_latex = true },
		proof = { do_not_define_in_latex = true },
	}
	STYLES_AMSTHM.empty = STYLES_NONE.empty
	local LOCALIZE = {
		en = {
			theorem = 'Theorem',
			corollary = 'Corollary',
			lemma = 'Lemma',
			proposition = 'Proposition',
			conjecture = 'Conjecture',
			fact = 'Fact',
			definition = 'Definition',
			example = 'Example',
			problem = 'Problem',
			exercise = 'Exercise',
			solution = 'Solution',
			remark = 'Remark',
			claim = 'Claim',
			proof = 'Proof',
		},
		fr = {
			theorem = 'Théorème',
			corollary = 'Corollaire',
			lemma = 'Lemma',
			proposition = 'Proposition',
			conjecture = 'Conjecture',
			fact = 'Fait',
			definition = 'Définition',
			example = 'Example',
			problem = 'Problème',
			exercise = 'Exercise',
			solution = 'Solution',
			remark = 'Remarque',
			claim = 'Affirmation',
			proof = 'Preuve',
		},

	}

	--- prepare_aliases_map: make list of aliases for stateemnt Div classes.
	-- A statement can be identified by its full kind name (`theorem`)
	-- or its prefix (`thm`). We find prefixes to build a list of aliases.
	-- This is deactivated by the option `no-aliases`. 
	-- @return alias map of alias = kind name
	local function prepare_aliases_map()

		-- populate the aliases map
		for kind_key,kind in pairs(kinds) do
			-- use the kind's prefix as alias, if any
			if kind.prefix then 
				aliases[kind.prefix] = kind_key
			end
			-- us the kind's label (converted to plain text), if any
			if kind.label then
				local alias = pandoc.write(pandoc.Pandoc({kind.label}), 'plain')
				alias = alias:gsub('\n','')
				aliases[alias] = kind_key
			end
		end

	end

	-- FUNCTION MAIN BODY
	-- if `statement` options map, process it
	if meta.statement then

		if meta.statement['defaults'] == 'basic' then
			kinds = KINDS_BASIC
			styles = STYLES_AMSTHM
		elseif meta.statement['defaults'] == 'none' then
			-- statement is required
			kinds = KINDS_NONE
			styles = STYLES_NONE
		else -- 'defaults' absent or unintelligible
			kinds = KINDS_BASIC
			styles = STYLES_AMSTHM
		end

		-- process boolean options
		local boolean_options = {
			amsthm = 'amsthm',
			aliases = 'aliases',
			swap_numbers = 'swap-numbers',
			supply_header = 'supply-header',
			only_statement = 'only-statement',
			define_in_header = 'define-in-header',
		}
		for key,option in pairs(boolean_options) do
			if type(meta.statement[option]) == 'boolean' then
				options[key] = meta.statement[option]
			end
		end

	end -- ends reading `meta.statement`

	-- PROCESS OPTIONS

	-- language. Set language if we have a LOCALIZE value for it
	if meta.lang then
		-- change the language only if we have a LOCALIZE value for it
		-- try the first two letters too
		local lang_str = stringify(meta.lang)
		if LOCALIZE[lang_str] then
			language = lang_str
		elseif LOCALIZE[lang_str:sub(1,2)] then
			language = lang_str:sub(1,2)
		end
	end

	-- pick the document fontsize, needed to convert some lengths
	if meta.fontsize then
		local fontstr = stringify(meta.fontsize)
		local size, unit = fontstr:match('(%d*.%d*)(.*)')
		if tonumber(size) then
			unit = unit:gsub("%s+", "")
			options.fontsize = {tonumber(size), unit}
		end
	end

	-- populate labels
	for kind_key, kind in pairs(kinds) do
		-- populate labels
		if not kind.label and LOCALIZE[language][kind_key] then
			kind.label = pandoc.Inlines(LOCALIZE[language][kind_key])
		end
	end

	-- prepare header_includes
	if options.amsthm and FORMAT:match('latex') then
		header_includes:insert(pandoc.MetaBlocks(pandoc.RawBlock(
			'latex', '\\usepackage{amsthm}'
			)))
		-- \swapnumbers (amsthm package only),
		-- place in header or in body before the first kind definition
		if options.swap_numbers then
			local block = pandoc.RawBlock('latex','\\swapnumbers')
			if options.define_in_header then
				header_includes:insert(pandoc.MetaBlocks(block))
			else
				before_definitions_includes = 
					ensure_list(before_definitions_includes)
				before_definitions_includes:insert(block)
			end
		end

	end

	-- prepare alias map
	if options.aliases then
		prepare_aliases_map()
	end

	return
end
--- walk_doc: processes the document.
-- @param doc Pandoc document
-- @return Pandoc document if modified or nil
local function walk_doc(doc)

	--- process_blocks: processes a list of blocks (pandoc Blocks)
	-- @param blocks
	-- @return blocks or nil if not modified
	local function process_blocks( blocks )

		result = pandoc.List:new()
		is_modified = false

		-- go through the document's element in order
		-- find statement Divs and process them
		-- find headings and update counters
		-- @todo: recursive processing where needed

		for i = 1, #blocks do
			local block = blocks[i]

			if block.t == 'Div' then

				-- try to create a statement
				sta = Statement:new(block)

				-- replace the block with the formatted statement, if any
				if sta then
					result:extend(sta:format())
					is_modified = true
				else
					result:insert(block)
				end

			else

				result:insert(block)

			end

		end

		return is_modified and result or nil

	end

	-- FUNCTION BODY
	-- only return something if doc modified
	local new_blocks = process_blocks(doc.blocks)

	if new_blocks then
		doc.blocks = new_blocks
		return doc
	else
		return nil
	end
end
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
-- end modules


return {
	-- process Meta for options first
	{
			Meta = setup		
	},
	-- process document, needs to be walked
	{
			Pandoc = walk_doc
	},
	-- update Meta 
	{
		Meta = update_meta
	},
}