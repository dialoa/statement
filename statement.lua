--[[-- # Statement - a Lua filter for statements in Pandoc's markdown

This Lua filter provides support for statements (principles,
arguments, vignettes, theorems, exercises etc.) in Pandoc's markdown.

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@author Thomas Hodgson <hello@twshodgson.net>
@copyright 2021-2022 Julien Dutant, Thomas Hodgson
@license MIT - see LICENSE file for details.
@release 0.5.1

]]

-- # Global helper functions
---Helpers class: helper functions
--This class collects helper functions that do not depend 
--on the filter's data structure.
Helpers = {}

-- # Global functions

stringify = pandoc.utils.stringify

--- type: pandoc-friendly type function
-- pandoc.utils.type is only defined in Pandoc >= 2.17
-- if it isn't, we extend Lua's type function to give the same values
-- as pandoc.utils.type on Meta objects: Inlines, Inline, Blocks, Block,
-- string and boolean
-- Caution: not to be used on non-Meta Pandoc elements, the 
-- results will differ (only 'Block', 'Blocks', 'Inline', 'Inlines' in
-- >=2.17, the .t string in <2.17).
Helpers.type = pandoc.utils.type or function (obj)
        local tag = type(obj) == 'table' and obj.t and obj.t:gsub('^Meta', '')
        -- convert to Block, Blocks, Inline, Inlines
        return tag and tag ~= 'Map' and tag or type(obj)
    end
type = Helpers.type

--- ensure_list: turns an element into a list if needed
-- If elem is nil returns an empty list
-- @param elem a Pandoc element
-- @return a Pandoc List
ensure_list = function (elem)
    return type(elem) == 'List' and elem or pandoc.List:new({elem})
end

---message: send message to std_error
-- @param type string INFO, WARNING, ERROR
-- @param text string message text
message = function (type, text)
    local level = {INFO = 0, WARNING = 1, ERROR = 2}
    if level[type] == nil then type = 'ERROR' end
    if level[PANDOC_STATE.verbosity] <= level[type] then
        io.stderr:write('[' .. type .. '] Collection lua filter: ' 
            .. text .. '\n')
    end
end

-- ## Functions stored in Helpers fields
--- Helpers.font_format: parse font features into the desired format
-- @param len Inlines or string to be interpreted
-- @param format (optional) desired format if other than FORMAT
-- @return string, font commands in the desired format or ''
Helpers.font_format = function (str, format)
	local format = format or FORMAT
	-- FEATURES and their conversion
	local FEATURES = {
		upright = {
			latex = '\\upshape',
			css = 'font-style: normal;',
		},
		italics = {
			latex = '\\itshape',
			css = 'font-style: italic;',
		},
		smallcaps = {
			latex = '\\scshape',
			css = 'font-variant: small-caps;',
		},
		bold = {
			latex = '\\bfseries',
			css = 'font-weight: bold;',
		},
		normal = {
			latex = '\\normalfont',
			css = 'font-style: normal; font-weight: normal; font-variant:normal;'
		}
	}
	-- provide some aliases
	local ALIASES = {
		italics = {'italic'},
		normal = {'normalfont'},
		smallcaps = {'small%-caps'}, -- used as a pattern, so `-` must be escaped
	}

	-- within this function, format is 'css' when css features are needed
	if format:match('html') then
		format = 'css'
	end

	-- ensure str is defined and a string
	str = type(str) == 'string' and str ~= '' and str
				or type(str) == 'Inlines' and #str > 0 and stringify(str)
				or nil

	if str then

		local result = ''

		for feature,definition in pairs(FEATURES) do
			if str:match(feature) and definition[format] then
				result = result..definition[format]
			-- avoid multiple copies by only looking for aliases
			-- if main feature key not found and breaking if we find any alias 
			elseif ALIASES[feature] then 
				for _,alias in ipairs(ALIASES[feature]) do
					if str:match(alias) and definition[format] then
						result = result..definition[format]
						break -- ensures no multiple copies
					end
				end
			end
		end

		return result

	end

	return ''

end

--- Helpers.font_format_native: parse font features into 
-- native pandoc elements: Emph, Strong, smallcaps Span.
-- Note that the function won't work if you pass it a List
-- that is not of type Blocks or Inlines. 
--@TODO requires >=2.17 to recognize Blocks and Inlines types
--@TODO provide Spans with classes for older Pandoc versions?
--@TODO type(elem) in Pandoc <2.17 doesn't return 'Inline' but 'Para' etc.
-- @param len Inlines or string to be interpreted
-- @return function, Inline(s) -> Inline(s) or Block(s) -> Block(s)
Helpers.font_format_native = function (str)
	-- FEATURES and their conversion
	local FEATURES = {
		italics = 	function(inlines) 
									return pandoc.Emph(inlines)
								end,
		smallcaps = function(inlines) 
									return pandoc.SmallCaps(inlines)
								end,
		bold = 	function(inlines) 
								return pandoc.Strong(inlines)
							end,
		underline = function(inlines) 
									return pandoc.Underline(inlines)
								end,
		strikeout = function(inlines)
									return pandoc.Strikeout(inlines)
								end,
		subscript = function(inlines)
									return pandoc.Subscript(inlines)
								end,
		superscript = function(inlines) 
									return pandoc.Superscript(inlines)
								end,
		code = function(inlines)
									return pandoc.Code(stringify(inlines))
								end,
	}
	-- provide some aliases
	local ALIASES = {
		italics = {'italic'},
		normal = {'normalfont'},
		smallcaps = {'small%-caps'}, -- used as a pattern, so `-` must be escaped
	}

	-- ensure str is defined and a string
	str = type(str) == 'string' and str ~= '' and str
				or type(str) == 'Inlines' and #str > 0 and stringify(str)
				or nil

	if str then

		-- build a list of functions to be applied
		local formatters = pandoc.List:new()

		for feature,definition in pairs(FEATURES) do
			if str:match(feature) then
				formatters:insert( definition )
			-- avoid multiple copies by only looking for aliases
			-- if main feature key not found and breaking if we find any alias 
			elseif ALIASES[feature] then 
				for _,alias in ipairs(ALIASES[feature]) do
					if str:match(alias) then
						formatters:insert( definition )
						break -- ensures no multiple copies
					end
				end
			end
		end

		if #formatters > 0 then

			-- Common Inlines formatting function
			local inlines_format = 	function(inlines)
													for _,formatter in ipairs(formatters) do
														inlines = formatter(inlines)
													end
													return inlines
												end

			-- return a function that handles all types
			-- 	- Inlines, Inline: wrap with inlines_format
			-- 	- Blocks, Block: wrap the content of leaf blocks (those
			--									whose content is inlines only)
			return function (obj)
				-- determine type
				obj_type = (type(obj) == 'Inlines' or type(obj) == 'Inline'
										or type(obj) == 'Blocks' or type(obj) == 'Block')
										and type(obj)
										or nil
				if not obj_type and type(obj) == 'List' and obj[1] then
					if type(obj[1]) == 'Inline' then
						obj = pandoc.Inlines(obj)
						obj_type = 'Inlines'
					elseif type(obj[1] == 'Block') then
						obj = pandoc.Blocks(obj)
						obj_type = 'Blocks'
					end
				end
				-- process object according to type and return it
					if obj_type == 'Inlines' or obj_type == 'Inline' then
						return inlines_format(obj)
					elseif obj_type == 'Block' and type(obj.content) == 'Inlines' then
						obj.content = inlines_format(obj.content)
						return obj
					elseif obj_type == 'Blocks' then
						return obj:walk( { 
								Block = function(elem)
										if elem.content and type(elem.content) == 'Inlines' then
											elem.content = inlines_format(elem.content)
											return elem
										end
									end 
							})
					else
						return obj
					end
				
				end

		end

	end

	return function(obj) return obj end

end

--- Helpers.length_format: parse a length in the desired format
-- @param len Inlines or string to be interpreted
-- @param format (optional) desired format if other than FORMAT
-- @return string specifying the length in the desired format or nil
Helpers.length_format = function (str, format)
	local format = format or FORMAT
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
	-- add `\` to LATEX_LENGTHS keys (can't be done directly)
	local new_latex_lengths = {} -- needs to make a copy
	for key,value in pairs(LATEX_LENGTHS) do
		new_latex_lengths['\\'..key] = value
	end
	LATEX_LENGTHS = new_latex_lengths
	-- HTML_ENTITIES and their translations in 'main plus minus' format
	local HTML_ENTITIES = {}
	HTML_ENTITIES['&nbsp;'] = '0.333em plus 0.666em minus 0.111em'
	HTML_ENTITIES['&#32;'] = '0.333em plus 0.666em minus 0.111em' -- space

	--- parse_length: parse a '<number><unit>' string.
	-- checks the unit against UNITS and LATEX_LENGTHS
	--@param str string to be parsed or nil
	--@return number amount parsed
	--@return table with `amount` and `unit` fields or nil
	local function parse_length(str)
		if not str then 
			return nil 
		end

		local amount, unit
		-- match number and unit, possibly separated by spaces
		-- nb, %g for printable characters except spaces
		amount, unit = str:match('%s*(%-?%s*%d*%.?%d*)%s*(%g+)%s*')
		-- allow amount + unit, or no amount ('') + LaTeX unit
		if amount then
			-- need to remove spaces before attempting `tonumber`
			amount = amount:gsub('%s','')
			-- either we have a number + unit:
			if tonumber(amount) and (UNITS[unit] or LATEX_LENGTHS[unit]) then
				-- ensure amount is a number
				amount = tonumber(amount)
				-- conversion if available
				if UNITS[unit] and UNITS[unit][format] then
					amount = amount * UNITS[unit][format][1]
					unit = UNITS[unit][format][2]
				elseif LATEX_LENGTHS[unit] and LATEX_LENGTHS[unit][format] then
					amount = amount * LATEX_LENGTHS[unit][format][1]
					unit = LATEX_LENGTHS[unit][format][2]
				end -- end of conversions
				-- return result as table
				return { 
					amount = amount,
					unit = unit,
				}
			-- or we have a latex length on its own
			elseif amount=='' and LATEX_LENGTHS[unit] then
				amount = 1
				-- convert if possible
				if LATEX_LENGTHS[unit] and LATEX_LENGTHS[unit][format] then
					amount = LATEX_LENGTHS[unit][format][1]
					unit = LATEX_LENGTHS[unit][format][2]
				end -- end of conversions
				-- return result as table
				return { 
					amount = amount,
					unit = unit,
				}
			end -- no legit amount / unit combination
		end -- no string match
	end -- end of parse_length

	--- parse_plus_minus: parse a '<length>plus<length>minus<length>'
	-- string.
	--@param str string to be parse
	--@return table with `main`, `plus`, `minus` fields, each a
	-- 	table with `amount` and `unit` fields or nil
	local function parse_plus_minus(str)

		local main, plus, minus

		-- special cases: length is just '0' or space or HTML entity
		if tonumber(str) and tonumber(str) == 0 then
			return {
					main = {amount = 0, unit = 'em'} 
				}
		elseif str == ' ' then
		 	main,plus,minus = '0.333em', '0.666em', '0.111em' 
		elseif HTML_ENTITIES[str] then
			str = HTML_ENTITIES[str]
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

	-- within this function, format is 'css' when css features are needed
	if format:match('html') then
		format = 'css'
	end

	-- ensure str is defined and a string
	str = type(str) == 'string' and str ~= '' and str
				or type(str) == 'Inlines' and #str > 0 and stringify(str)

	if str then

		-- parse `str` into a length table
		-- length = {
		--		main = { amount = number, unit = string} or nil
		--		plus = { amount = number, unit = string} or nil
		--		minus = { amount = number, unit = string} or nil
		-- }
		local length = parse_plus_minus(str)

		if length then

			local result
		
			-- prepare a string appropriate to the output format
			-- note: string.format uses C's sprintf patterns
			-- '%.5g' for four digits after the dot.
			-- warning: '%.5g' may output exponent notation,
			--	'%.5f' would force floating point but leaves trailing 0s.
			-- LaTeX: <number><unit> plus <number><unit> minus <number><unit>
			-- css: <number><unit>
			if format == 'latex' then

				result = string.format('%.5g', length.main.amount)
								.. length.main.unit
				for _,key in ipairs({'plus','minus'}) do
					if length[key] then
						result = result..' '..key..' '
							.. string.format('%.5g', length[key].amount)
							.. length[key].unit
					end
				end

			elseif format == 'css' then

				result = string.format('%.5g', length.main.amount)
												.. length.main.unit

			end -- nothing in other formats

			return result

		end

	end

end


-- # Filter components
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
--- Setup.DEFAULTS: default sets of kinds and styles
-- See amsthm documentation <https://www.ctan.org/pkg/amsthm>
-- the 'none' definitions are always included but they can be 
-- overridden by others default sets or the user.
Setup.DEFAULTS = {}
Setup.DEFAULTS.KINDS = {
	none = {
		statement = {prefix = 'sta', style = 'empty', counter='none'},
	},
	basic = {
		theorem = { prefix = 'thm', style = 'plain', counter = 'self' },
		lemma = { prefix = 'lem', style = 'plain', counter = 'theorem' },
		corollary = { prefix = 'cor', style = 'plain', counter = 'theorem' },
		proposition = {prefix = 'prop', style = 'plain', counter = 'theorem' },
		conjecture = {prefix = 'conj', style = 'plain', counter = 'theorem' },
		fact = { style = 'plain', counter = 'theorem'},
		definition = {prefix = 'defn', style = 'definition', counter = 'theorem'},
		problem = {prefix = 'prob', style = 'definition', counter = 'theorem'},
		example = {prefix = 'exa', style = 'definition', counter = 'theorem'},
		exercise = {prefix = 'xca', style = 'definition', counter = 'theorem'},
		axiom = {prefix = 'ax', style = 'definition', counter = 'theorem'},
		solution = {prefix = 'sol', style = 'definition', counter = 'theorem'},
		remark = {prefix = 'rem', style = 'remark', counter = 'theorem'},
		claim = {prefix = 'claim', style = 'remark', counter = 'theorem'},
		proof = {prefix = 'proof', style = 'proof', counter = 'none'},
		criterion = {prefix = 'crit', style = 'plain', counter = 'theorem'},
		assumption = {prefix = 'ass', style = 'plain', counter = 'theorem'},
		algorithm = {prefix = 'alg', style = 'definition', counter = 'theorem'},
		condition = {prefix = 'cond', style = 'definition', counter = 'theorem'},
		question = {prefix = 'qu', style = 'definition', counter = 'theorem'},
		note = {prefix = 'note', style = 'remark', counter = 'theorem'},
		summary = {prefix = 'sum', style = 'remark', counter = 'theorem'},
		conclusion = {prefix = 'conc', style = 'remark', counter = 'theorem'},
	}
}
Setup.DEFAULTS.STYLES = {
	none = {
		empty = {
			margin_top = '1em',
			margin_bottom = '1em',
			margin_left = '2em',
			margin_right = '2em',
			body_font = '',
			indent = '0pt', -- applies to the label / first line only
			head_font = 'smallcaps',
			punctuation = '',
			space_after_head = '0pt', -- use '\n' or '\\n' or '\newline' for linebreak 
			heading_pattern = nil,
			custom_label_changes = {
											punctuation = '.',
											crossref_font = 'smallcaps',
											space_after_head = ' ',
			},
		},
	},
	basic = {
		plain = { do_not_define_in_latex = true,
			margin_top = '1em',
			margin_bottom = '1em',
			margin_left = nil,
			margin_right = nil,
			body_font = 'italics',
			indent = '0pt',
			head_font = 'bold',
			punctuation = '.',
			space_after_head = '1em',
			heading_pattern = nil,			
		 },
		definition = { do_not_define_in_latex = true,
			based_on = 'plain',
			body_font = '', -- '' used to reset the basis's field to nil
		 },
		remark = { do_not_define_in_latex = true,
			based_on = 'plain',
			body_font = '',
			head_font = 'italics',
		 },
		proof = { do_not_define_in_latex = false,
			based_on = 'plain',
			body_font = 'normal',
			head_font = 'italics',
		 }, -- Statement.write_style will take care of it
	},
}

--- Setup.LOCALE: localize statement labels
Setup.LOCALE = {
		ar = {
			algorithm = "الخوارزم",
			assumption = "فرضية",
			axiom = "مُسلّمة",
			claim = "متطلب",
			conclusion = "استنتاج",
			condition = "شرط",
			conjecture = "حدس",
			corollary = "لازمة",
			criterion = "معيار",
			definition = "تعريف",
			example = "مثال",
			exercise = "تمرين",
			fact = "حقيقة",
			lemma = "قضية مساعدة",
			notation = "تدوين",
			note = "ملاحظة",
			problem = "مشكلة",
			proof = "برهان",
			proposition = "اقتراح",
			question = "سؤال",
			remark = "تنبيه",
			solution = "حل",
			summary = "موجز",
			theorem = "نظرية",
		},
		bg = {
			algorithm = "Aлгоритъм",
			assumption = "Assumption",
			axiom = "Axiom",
			claim = "Claim",
			conclusion = "Заключение",
			condition = "Условие",
			conjecture = "Conjecture",
			corollary = "Corollary",
			criterion = "Criterion",
			definition = "Дефиниция",
			example = "Пример",
			exercise = "Упражнение",
			fact = "Факт",
			lemma = "Лема",
			notation = "Notation",
			note = "Бележка",
			problem = "Проблем",
			proof = "Доказателство",
			proposition = "Допускане",
			question = "Въпрос",
			remark = "Remark",
			solution = "Решение",
			summary = "Обобщение",
			theorem = "Теорема",
		},
		ca = {
			algorithm = "Algorisme",
			assumption = "Assumpció",
			axiom = "Axioma",
			claim = "Afirmació",
			conclusion = "Conclusió",
			condition = "Condició",
			conjecture = "Conjectura",
			corollary = "Corol·lari",
			criterion = "Criteri",
			definition = "Definició",
			example = "Exemple",
			exercise = "Exercici",
			fact = "Fet",
			lemma = "Lema",
			notation = "Notació",
			note = "Nota",
			problem = "Problema",
			proof = "Demostració",
			proposition = "Proposició",
			question = "Qüestió",
			remark = "Comentari",
			solution = "Solució",
			summary = "Resum",
			theorem = "Teorema",
		},
		cs = {
			algorithm = "Algoritmus",
			assumption = "Předpoklad",
			axiom = "Axiom",
			claim = "Tvrzení",
			conclusion = "Závěr",
			condition = "Podmínka",
			conjecture = "Hypotéza",
			corollary = "Důsledek",
			criterion = "Kritérium",
			definition = "Definice",
			example = "Příklad",
			exercise = "Cvičení",
			fact = "Fakt",
			lemma = "Lemma",
			notation = "Značení",
			note = "Poznámka",
			problem = "Úloha",
			proof = "Důkaz",
			proposition = "Tvrzení",
			question = "Otázka",
			remark = "Poznámka",
			solution = "Řešení",
			summary = "Souhrn",
			theorem = "Věta",
		},
		da = {
			algorithm = "Algoritme",
			assumption = "Antagelse",
			axiom = "Aksiom",
			claim = "Påstand",
			conclusion = "Konklusion",
			condition = "Betingelse",
			conjecture = "Formodning",
			corollary = "Korollar",
			criterion = "Kriterium",
			definition = "Definition",
			example = "Eksempel",
			exercise = "Øvelse",
			fact = "Faktum",
			lemma = "Lemma",
			notation = "Notation",
			note = "Note",
			problem = "Problem",
			proof = "Bevis",
			proposition = "Forslag",
			question = "Spørgsmål",
			remark = "Bemærkning",
			solution = "Løsning",
			summary = "Resumé",
			theorem = "Sætning",
		},
		de = {
			algorithm = "Algorithmus",
			assumption = "Annahme",
			axiom = "Axiom",
			claim = "Behauptung",
			conclusion = "Schlussfolgerung",
			condition = "Bedingung",
			conjecture = "Vermutung",
			corollary = "Korollar",
			criterion = "Kriterium",
			definition = "Definition",
			example = "Beispiel",
			exercise = "Aufgabe",
			fact = "Fakt",
			hypothesis = "Annahme",
			lemma = "Lemma",
			notation = "Notation",
			note = "Notiz",
			problem = "Problem",
			proof = "Beweis",
			proposition = "Satz",
			question = "Frage",
			remark = "Bemerkung",
			solution = "Lösung",
			summary = "Zusammenfassung",
			theorem = "Theorem",
		},
		el = {
			algorithm = "Αλγόριθμος",
			assumption = "Υπόθεση",
			axiom = "Αξίωμα",
			claim = "Ισχυρισμός",
			conclusion = "Συμπέρασμα",
			condition = "Συνθήκη",
			conjecture = "Εικασία",
			corollary = "Πόρισμα",
			criterion = "Κριτήριο",
			definition = "Ορισμός",
			example = "Παράδειγμα",
			exercise = "Άσκηση",
			fact = "Δεδομένο",
			lemma = "Λήμμα",
			notation = "Σημειογραφία",
			note = "Σημείωση",
			problem = "Πρόβλημα",
			proof = "Απόδειξη",
			proposition = "Πρόταση",
			question = "Ερώτημα",
			remark = "Παρατήρηση",
			solution = "Λύση",
			summary = "Σύνοψη",
			theorem = "Θεώρημα",
		},
		en = {
			algorithm = "Algorithm",
			assumption = "Assumption",
			axiom = "Axiom",
			claim = "Claim",
			conclusion = "Conclusion",
			condition = "Condition",
			conjecture = "Conjecture",
			corollary = "Corollary",
			criterion = "Criterion",
			definition = "Definition",
			example = "Example",
			exercise = "Exercise",
			fact = "Fact",
			hypothesis = "Hypothesis",
			lemma = "Lemma",
			notation = "Notation",
			note = "Note",
			problem = "Problem",
			proof = "Proof",
			proposition = "Proposition",
			question = "Question",
			remark = "Remark",
			solution = "Solution",
			summary = "Summary",
			theorem = "Theorem",
		},
		es = {
			algorithm = "Algoritmo",
			assumption = "Suposición",
			axiom = "Axioma",
			claim = "Afirmación",
			conclusion = "Conclusión",
			condition = "Condición",
			conjecture = "Conjetura",
			corollary = "Corolario",
			criterion = "Criterio",
			definition = "Definición",
			example = "Ejemplo",
			exercise = "Ejercicio",
			fact = "Hecho",
			hypothesis = "Hipótesis",
			lemma = "Lema",
			notation = "Notación",
			note = "Nota",
			problem = "Problema",
			proof = "Demostración",
			proposition = "Proposición",
			question = "Pregunta",
			remark = "Observación",
			solution = "Solución",
			summary = "Resumen",
			theorem = "Teorema",
		},
		eu = {
			algorithm = "Algoritmoa",
			assumption = "Hipotesia",
			axiom = "Axioma",
			claim = "Aldarrikapena",
			conclusion = "Ondorioa",
			condition = "Baldintza",
			conjecture = "Aierua",
			corollary = "Korolarioa",
			criterion = "Irizpidea",
			definition = "Definizioa",
			example = "Adibidea",
			exercise = "Ariketa",
			fact = "Egitatea",
			lemma = "Lema",
			notation = "Notazioa",
			note = "Oharra",
			problem = "Buruketa",
			proof = "Frogapena",
			proposition = "Proposizioa",
			question = "Galdera",
			remark = "Oharpena",
			solution = "Emaitza",
			summary = "Laburpena",
			theorem = "Teorema",
		},
		fi = {
			algorithm = "Algoritmi",
			assumption = "Oletus",
			axiom = "Aksiooma",
			claim = "Väite",
			conclusion = "Päätelmä",
			condition = "Ehto",
			conjecture = "Otaksuma",
			corollary = "Seurauslause",
			criterion = "Kriteeri",
			definition = "Määritelmä",
			example = "Esimerkki",
			exercise = "Harjoitus",
			fact = "Fakta",
			lemma = "Lemma",
			notation = "Merkintätapa",
			note = "Muistiinpano",
			problem = "Ongelma",
			proof = "Todistus",
			proposition = "Väittämä",
			question = "Kysymys",
			remark = "Huomautus",
			solution = "Ratkaisu",
			summary = "Yhteenveto",
			theorem = "Lause",
		},
		fr = {
			algorithm = "Algorithme",
			assumption = "Supposition",
			axiom = "Axiome",
			claim = "Affirmation",
			conclusion = "Conclusion",
			condition = "Condition",
			conjecture = "Conjecture",
			corollary = "Corollaire",
			criterion = "Critère",
			definition = "Définition",
			example = "Exemple",
			exercise = "Exercice",
			fact = "Fait",
			hypothesis = "Hypothèse",
			lemma = "Lemme",
			notation = "Notation",
			note = "Note",
			problem = "Problème",
			proof = "Démonstration",
			proposition = "Proposition",
			question = "Question",
			remark = "Remarque",
			solution = "Solution",
			summary = "Résumé",
			theorem = "Théorème",
		},
		gl = {
			algorithm = "Algoritmo",
			assumption = "Suposición",
			axiom = "Axioma",
			claim = "Afirmación",
			conclusion = "Conclusión",
			condition = "Condición",
			conjecture = "Conxetura",
			corollary = "Corolário",
			criterion = "Critério",
			definition = "Definición",
			example = "Exemplo",
			exercise = "Exercício",
			fact = "Facto",
			lemma = "Lema",
			notation = "Notación",
			note = "Nota",
			problem = "Problema",
			proof = "Demostración",
			proposition = "Proposición",
			question = "Pergunta",
			remark = "Observación",
			solution = "Solución",
			summary = "Resumo",
			theorem = "Teorema",
		},
		he = {
			algorithm = "אלגוריתם",
			assumption = "הנחה",
			axiom = "אקסיומה",
			claim = "טענה",
			conclusion = "סיכום",
			condition = "תנאי",
			conjecture = "השערה",
			corollary = "מסקנה",
			criterion = "קריטריון",
			definition = "הגדרה",
			example = "דוגמה",
			exercise = "תרגיל",
			fact = "עובדה",
			lemma = "למה",
			notation = "צורת רישום",
			note = "הערה",
			problem = "בעיה",
			proof = "הוכחה",
			proposition = "הצעה",
			question = "שאלה",
			remark = "הערה",
			solution = "פתרון",
			summary = "סיכום",
			theorem = "משפט",
		},
		hr = {
		},
		hu = {
			algorithm = "Algoritmus",
			assumption = "Feltevés",
			axiom = "Axióma",
			claim = "Igény",
			conclusion = "Következtetés",
			condition = "Feltétel",
			conjecture = "Feltevés",
			corollary = "Következmény",
			criterion = "Kritérium",
			definition = "Definíció",
			example = "Példa",
			exercise = "Gyakorlat",
			fact = "Tény",
			lemma = "Segédtétel",
			notation = "Jelölés",
			note = "Megjegyzés",
			problem = "Probléma",
			proof = "Bizonyítás",
			proposition = "Állítás",
			question = "Kérdés",
			remark = "Észrevétel",
			solution = "Megoldás",
			summary = "Összegzés",
			theorem = "Tétel",
		},
		ia = {
			algorithm = "Algorithmo",
			assumption = "Assumption",
			axiom = "Axioma",
			claim = "Assertion",
			conclusion = "Conclusion",
			condition = "Condition",
			conjecture = "Conjectura",
			corollary = "Corollario",
			criterion = "Criterio",
			definition = "Definition",
			example = "Exemplo",
			exercise = "Exercitio",
			fact = "Facto",
			lemma = "Lemma",
			notation = "Notation",
			note = "Nota",
			problem = "Problema",
			proof = "Demonstration",
			proposition = "Proposition",
			question = "Question",
			remark = "Observation",
			solution = "Solution",
			summary = "Summario",
			theorem = "Theorema",
		},
		id = {
			algorithm = "Algoritma",
			assumption = "Asumsi",
			axiom = "Aksioma",
			claim = "Klaim",
			conclusion = "Kesimpulan",
			condition = "Kondisi",
			conjecture = "Dugaan",
			corollary = "Korolari",
			criterion = "Kriteria",
			definition = "Definisi",
			example = "Contoh",
			exercise = "Latihan",
			fact = "Fakta",
			lemma = "Lemma",
			notation = "Notasi",
			note = "Nota",
			problem = "Masalah",
			proof = "Pruf",
			proposition = "Proposisi",
			question = "Pertanyaan",
			remark = "Catatan",
			solution = "Penyelesaian",
			summary = "Ringkasan",
			theorem = "Teorema",
		},
		it = {
			algorithm = "Algoritmo",
			assumption = "Assunzione",
			axiom = "Assioma",
			claim = "Asserzione",
			conclusion = "Conclusione",
			condition = "Condizione",
			conjecture = "Congettura",
			corollary = "Corollario",
			criterion = "Criterio",
			definition = "Definizione",
			example = "Esempio",
			exercise = "Esercizio",
			fact = "Fatto",
			hypothesis = "Ipotesi",
			lemma = "Lemma",
			notation = "Notazione",
			note = "Nota",
			problem = "Problema",
			proof = "Dimostrazione",
			proposition = "Proposizione",
			question = "Quesito",
			remark = "Osservazione",
			solution = "Soluzione",
			summary = "Sommario",
			theorem = "Teorema",
		},
		ja = {
			algorithm = "アルゴリズム",
			assumption = "仮定",
			axiom = "公理",
			claim = "主張",
			conclusion = "結論",
			condition = "条件",
			conjecture = "予想",
			corollary = "系",
			criterion = "基準",
			definition = "定義",
			example = "例",
			exercise = "演習",
			fact = "事実",
			lemma = "補題",
			notation = "記法",
			note = "註釈",
			problem = "問題",
			proof = "証明",
			proposition = "命題",
			question = "問",
			remark = "注意",
			solution = "解",
			summary = "要約",
			theorem = "定理",
		},
		ko = {
			algorithm = "알고리듬",
			assumption = "Assumption",
			axiom = "Axiom",
			claim = "Claim",
			conclusion = "Conclusion",
			condition = "Condition",
			conjecture = "Conjecture",
			corollary = "Corollary",
			criterion = "Criterion",
			definition = "Definition",
			example = "Example",
			exercise = "Exercise",
			fact = "Fact",
			lemma = "Lemma",
			notation = "Notation",
			note = "노우트(Note)",
			problem = "Problem",
			proof = "Proof",
			proposition = "Proposition",
			question = "Question",
			remark = "Remark",
			solution = "Solution",
			summary = "Summary",
			theorem = "Theorem",
		},
		nb = {
			algorithm = "Algoritme",
			assumption = "Antagelse",
			axiom = "Aksiom",
			claim = "Påstand",
			conclusion = "Konklusjon",
			condition = "Forutsetning",
			conjecture = "Konjektur",
			corollary = "Korollar",
			criterion = "Kriterie",
			definition = "Definisjon",
			example = "Eksempel",
			exercise = "Oppgave",
			fact = "Faktum",
			lemma = "Lemma",
			notation = "Notasjon",
			note = "Merknad",
			problem = "Problem",
			proof = "Bevis",
			proposition = "Proposisjon",
			question = "Spørsmål",
			remark = "Merknad",
			solution = "Løsning",
			summary = "Sammendrag",
			theorem = "Teorem",
		},
		nl = {
			algorithm = "Algoritme",
			assumption = "Aanname",
			axiom = "Axioma",
			claim = "Bewering",
			conclusion = "Conclusie",
			condition = "Voorwaarde",
			conjecture = "Vermoeden",
			corollary = "Corollarium",
			criterion = "Criterium",
			definition = "Definitie",
			example = "Voorbeeld",
			exercise = "Oefening",
			fact = "Feit",
			lemma = "Lemma",
			notation = "Notatie",
			note = "Noot",
			problem = "Opgave",
			proof = "Bewijs",
			proposition = "Propositie",
			question = "Vraag",
			remark = "Opmerking",
			solution = "Oplossing",
			summary = "Samenvatting",
			theorem = "Stelling",
		},
		nn = {
			algorithm = "Algoritme",
			assumption = "Asumpsjon",
			axiom = "Aksiom",
			claim = "Påstand",
			conclusion = "Konklusjon",
			condition = "Vilkår",
			conjecture = "Konjektur",
			corollary = "Korollar",
			criterion = "Kriterium",
			definition = "Definisjon",
			example = "Døme",
			exercise = "Øving",
			fact = "Faktum",
			lemma = "Lemma",
			notation = "Notasjon",
			note = "Notis",
			problem = "Problem",
			proof = "Prov",
			proposition = "Framlegg",
			question = "Spørsmål",
			remark = "Merknad",
			solution = "Løysing",
			summary = "Samandrag",
			theorem = "Teorem",
		},
		pl = {
			algorithm = "Algorytm",
			assumption = "Założenie",
			axiom = "Aksjomat",
			claim = "Stwierdzenie",
			conclusion = "Konkluzja",
			condition = "Warunek",
			conjecture = "Hipoteza",
			corollary = "Wniosek",
			criterion = "Kryterium",
			definition = "Definicja",
			example = "Przykład",
			exercise = "Ćwiczenie",
			fact = "Fakt",
			lemma = "Lemat",
			notation = "Notacja",
			note = "Notka",
			problem = "Problem",
			proof = "Dowód",
			proposition = "Propozycja",
			question = "Pytanie",
			remark = "Uwaga",
			solution = "Rozwiązanie",
			summary = "Podsumowanie",
			theorem = "Twierdzenie",
		},
		pt_br = {
			algorithm = "Algoritmo",
			assumption = "Suposição",
			axiom = "Axioma",
			claim = "Afirmação",
			conclusion = "Conclusão",
			condition = "Condição",
			conjecture = "Conjetura",
			corollary = "Corolário",
			criterion = "Critério",
			definition = "Definição",
			example = "Exemplo",
			exercise = "Exercício",
			fact = "Fato",
			lemma = "Lema",
			notation = "Notação",
			note = "Nota",
			problem = "Problema",
			proof = "Prova",
			proposition = "Proposição",
			question = "Pergunta",
			remark = "Observação",
			solution = "Solução",
			summary = "Resumo",
			theorem = "Teorema",
		},
		pt_pt = {
			algorithm = "Algoritmo",
			assumption = "Suposição",
			axiom = "Axioma",
			claim = "Afirmação",
			conclusion = "Conclusão",
			condition = "Condição",
			conjecture = "Conjectura",
			corollary = "Corolário",
			criterion = "Critério",
			definition = "Definição",
			example = "Exemplo",
			exercise = "Exercício",
			fact = "Facto",
			lemma = "Lema",
			notation = "Notação",
			note = "Nota",
			problem = "Problema",
			proof = "Prova",
			proposition = "Proposição",
			question = "Pergunta",
			remark = "Observação",
			solution = "Solução",
			summary = "Sumário",
			theorem = "Teorema",
		},
		ro = {
			algorithm = "Algoritm",
			assumption = "Ipoteză",
			axiom = "Axiomă",
			claim = "Afirmație",
			conclusion = "Concluzie",
			condition = "Condiție",
			conjecture = "Presupunere",
			corollary = "Corolar",
			criterion = "Criteriu",
			definition = "Definiție",
			example = "Exemplu",
			exercise = "Exercițiu",
			fact = "Fapt",
			lemma = "Lemă",
			notation = "Notație",
			note = "Notă",
			problem = "Problemă",
			proof = "Demonstrație",
			proposition = "Propoziție",
			question = "Întrebare",
			remark = "Remarcă",
			solution = "Soluție",
			summary = "Rezumat",
			theorem = "Teoremă",
		},
		ru = {
			algorithm = "Алгоритм",
			assumption = "Допущение",
			axiom = "Аксиома",
			claim = "Утверждение",
			conclusion = "Заключение",
			condition = "Условие",
			conjecture = "Предположение",
			corollary = "Вывод",
			criterion = "Критерий",
			definition = "Определение",
			example = "Пример",
			exercise = "Упражнение",
			fact = "Факт",
			lemma = "Лемма",
			notation = "Нотация",
			note = "Заметка",
			problem = "Задача",
			proof = "Доказательство",
			proposition = "Предложение",
			question = "Вопрос",
			remark = "Замечание",
			solution = "Решение",
			summary = "Сводка",
			theorem = "Теорема",
		},
		sk = {
			algorithm = "Algoritmus",
			assumption = "Predpoklad",
			axiom = "Axióma",
			claim = "Nárok",
			conclusion = "Záver",
			condition = "Podmienka",
			conjecture = "Hypotéza",
			corollary = "Korolár",
			criterion = "Kritérium",
			definition = "Definícia",
			example = "Príklad",
			exercise = "Úloha",
			fact = "Fakt",
			lemma = "Lemma",
			notation = "Notácia",
			note = "Poznámka",
			problem = "Problém",
			proof = "Dôkaz",
			proposition = "Tvrdenie",
			question = "Otázka",
			remark = "Pripomienka",
			solution = "Riešenie",
			summary = "Súhrn",
			theorem = "Teoréma",
		},
		sl = {
			algorithm = "Algoritem",
			assumption = "Assumption",
			axiom = "Aksiom",
			claim = "Trditev",
			conclusion = "Sklep",
			condition = "Pogoj",
			conjecture = "Domneva",
			corollary = "Korolar",
			criterion = "Kriterij",
			definition = "Definicija",
			example = "Zgled",
			exercise = "Vaja",
			fact = "Dejstvo",
			lemma = "Lema",
			notation = "Zapis",
			note = "Opomba",
			problem = "Problem",
			proof = "Dokaz",
			proposition = "Podmena",
			question = "Vprašanje",
			remark = "Pripomba",
			solution = "Rešitev",
			summary = "Povzetek",
			theorem = "Izrek",
		},
		sr = {
			algorithm = "Algoritam",
			assumption = "Pretpostavka",
			axiom = "Aksiom",
			claim = "Tvrdnja",
			conclusion = "Zaključak",
			condition = "Uslov",
			conjecture = "Pretpostavka",
			corollary = "Posledica",
			criterion = "Kriterijum",
			definition = "Definicija",
			example = "Primer",
			exercise = "Vežba",
			fact = "Činjenica",
			lemma = "Lemma",
			notation = "Zabeleška",
			note = "Napomena",
			problem = "Problem",
			proof = "Dokaz",
			proposition = "Predlog",
			question = "Pitanje",
			remark = "Napomena",
			solution = "Rešenje",
			summary = "Rezime",
			theorem = "Teorema",
		},
		sv = {
			algorithm = "Algoritm",
			assumption = "Antagande",
			axiom = "Axiom",
			claim = "Påstående",
			conclusion = "Slutsats",
			condition = "Villkor",
			conjecture = "Förmodan",
			corollary = "Korollarium",
			criterion = "Kriterium",
			definition = "Definition",
			example = "Exempel",
			exercise = "Övning",
			fact = "Faktum",
			lemma = "Lemma",
			notation = "Notation",
			note = "Not",
			problem = "Problem",
			proof = "Bevis",
			proposition = "Proposition",
			question = "Fråga",
			remark = "Anmärkning",
			solution = "Lösning",
			summary = "Sammanfattning",
			theorem = "Teorem",
		},
		tr = {
			algorithm = "Algoritma",
			assumption = "Varsayım",
			axiom = "Aksiyom",
			claim = "İddia",
			conclusion = "Sonuç",
			condition = "Koşul",
			conjecture = "Varsayım",
			corollary = "Doğal Sonuç",
			criterion = "Kriter",
			definition = "Tanım",
			example = "Örnek",
			exercise = "Alıştırma",
			fact = "Olgu",
			lemma = "Lemma",
			notation = "Notasyon",
			note = "Not",
			problem = "Problem",
			proof = "İspat",
			proposition = "Önerme",
			question = "Soru",
			remark = "Açıklama",
			solution = "Çözüm",
			summary = "Özet",
			theorem = "Teorem",
		},
		uk = {
			algorithm = "Алгоритм",
			assumption = "Припущення",
			axiom = "Аксіома",
			claim = "Твердження",
			conclusion = "Висновки",
			condition = "Умова",
			conjecture = "Припущення",
			corollary = "Наслідок",
			criterion = "Критерій",
			definition = "Визначення",
			example = "Приклад",
			exercise = "Вправа",
			fact = "Факт",
			lemma = "Лема",
			notation = "Позначення",
			note = "Зауваження",
			problem = "Задача",
			proof = "Доведення",
			proposition = "Твердження",
			question = "Питання",
			remark = "Примітка",
			solution = "Розв'язування",
			summary = "Резюме",
			theorem = "Теорема",
		},
		zh_cn = {
			algorithm = "算法",
			assumption = "假设",
			axiom = "公理",
			claim = "声明",
			conclusion = "结论",
			condition = "条件",
			conjecture = "猜想",
			corollary = "推论",
			criterion = "准则",
			definition = "定义",
			example = "例",
			exercise = "练习",
			fact = "事实",
			lemma = "引理",
			notation = "记号",
			note = "备忘",
			problem = "问题",
			proof = "证明",
			proposition = "命题",
			question = "问题",
			remark = "注",
			solution = "解答",
			summary = "小结",
			theorem = "定理",
		},
		zh_tw = {
			algorithm = "演算法",
			assumption = "假設",
			axiom = "公理",
			claim = "聲明",
			conclusion = "結論",
			condition = "條件",
			conjecture = "猜想",
			corollary = "推論",
			criterion = "準則",
			definition = "定義",
			example = "範例",
			exercise = "練習",
			fact = "事實",
			lemma = "引理",
			notation = "記號",
			note = "註記",
			problem = "問題",
			proof = "證明",
			proposition = "命題",
			question = "問題",
			remark = "備註",
			solution = "解法",
			summary = "摘要",
			theorem = "定理",
		},
}

---Setup:validate_defaults: check that the filter's DEFAULTS are
-- well configured. Prints an error if not.
function Setup:validate_defaults()
	local default_keys = pandoc.List:new() -- list of DEFAULTS.KINDS keys
	local valid = true

	-- check that we have 'none' defaults and that they provide 'statement'
	if not self.DEFAULTS.KINDS.none then
		message('ERROR', 'DEFAULTS file misconfigured: `none` defaults set missing in KINDS.')
		valid = false
	elseif not self.DEFAULTS.KINDS.none.statement then
		message('ERROR', 'DEFAULTS file misconfigured: `none` defaults lack the `statement` kind.')
		valid = false
	elseif not self.DEFAULTS.KINDS.none.statement.style then
		message('ERROR', 'DEFAULTS file misconfigured: `none.statement` has no style setting.')
		valid = false
	elseif not self.DEFAULTS.STYLES.none 
					or not self.DEFAULTS.STYLES.none[self.DEFAULTS.KINDS.none.statement.style] then
		message('ERROR', 'DEFAULTS file misconfigured: the none.statement style, '
										..self.DEFAULTS.KINDS.none.statement.style
										..' should be present in the STYLES.none table.')
		valid = false
	end
	if not self.DEFAULTS.STYLES.none then
		message('ERROR', 'DEFAULTS file misconfigured: `none` defaults set missing in STYLES.')
		valid = false
	end

	-- check that each default set has both kinds and styles
	for set,_ in pairs(self.DEFAULTS.KINDS) do
		if not self.DEFAULTS.STYLES[set] then
			message('ERROR', 'DEFAULTS file misconfigured: no `'
				..set..'` defaults in the STYLES table.')
			valid = false
		end
	end

	-- check that each kind has a counter and an existing style
	for set,_ in pairs(self.DEFAULTS.KINDS) do
		for kind,definition in pairs(self.DEFAULTS.KINDS[set]) do
			if not definition.counter then 
				message('ERROR', 'DEFAULTS file misconfigured: kind `'..kind..'`'
												..' in default set `'..set..'` has no counter.')
				valid = false
			end
			if not definition.style then 
				message('ERROR', 'DEFAULTS file misconfigured: kind `'..kind..'`'
												..' in default set `'..set..'` has no style.')
				valid = false
			end
			if not self.DEFAULTS.STYLES[set][definition.style] then 
				message('ERROR', 'DEFAULTS file misconfigured: style `'..definition.style..'`'
												..' needed by kind `'..kind..'` is missing in STYLES.'..set..'.')
				valid = false
			end
			if self.options and self.options.language
				and not self.LOCALE[self.options.language][kind] then
					message('WARNING', 'LOCALE file, entry `'..self.options.language..'`'
								.."doesn't provide a label for the kind `"..kind..'`'
								..' in defaults set `'..set..'`.')
				valid = false
			end
		end
	end

	if valid then
		message('INFO', 'Defaults files checked, all is in order.')
	end

end

--- Setup:read_options: read user options into the Setup.options table
--@param meta pandoc Meta object, document's metadata
--@return nil sets the Setup.options table
function Setup:read_options(meta) 

	-- user-defined localisations.
	-- Ready any user-provided translation map in 'stateemnt-locale' or 'locale'
	if meta['statement-locale'] or meta.locale then

		local function set_locale(lang,map)
			if type(map) ~= 'table' then 
				return
			end
			local lang_str = stringify(lang):lower():gsub('-','_')
			if not self.LOCALE[lang_str] then 
				self.LOCALE[lang_str] = {}
			end
			for key,translation in pairs(map) do
				if type(translation) == 'string' 
						or type(translation) == 'Inlines' then
					self.LOCALE[lang_str][key] = translation
				end
			end
		end

		if meta.locale and type(meta.locale) == 'table' then
			for lang,map in pairs(meta.locale) do
				set_locale(lang,map)
			end
		end
		if meta['statement-locale'] 
				and type(meta['statement-locale']) == 'table' then
			for lang,map in pairs(meta['statement-locale']) do
				set_locale(lang,map)
			end
		end

	end

	-- language. Set language if we have a self.LOCALE value for it
	if meta.lang then
		-- change the language only if we have a self.LOCALE value for it
		-- in the LOCALE table languages are encoded zh_CN rather than zh-CN
		-- try the first two letters too
		local lang_str = stringify(meta.lang):lower():gsub('-','_')
		if self.LOCALE[lang_str] then
			self.options.language = lang_str
		elseif self.LOCALE[lang_str:sub(1,2)] then
			self.options.language = lang_str:sub(1,2)
		elseif self.LOCALE['en'] then
			self.options.language = 'en'
		else
			for lang_key,_ in pairs(self.LOCALE) do
				self.options.language = lang_key
				break
			end
			if lang_key then 
				message('ERROR', 'No translations for language '..lang_str..'.'
												 ..' English not available either.'
												 .." I've randomly picked `"..self.options.language..'`'
												 ..'instead.')
			else
				message('ERROR', 'Translation table LOCALE is empty, the filter will crash.')
			end
		end
	end

	-- pick the document fontsize, needed to convert some lengths
	if meta.fontsize then
		local fontstr = stringify(meta.fontsize)
		local size, unit = fontstr:match('(%d*.%d*)(.*)')
		if tonumber(size) then
			unit = unit:gsub("%s+", "")
			self.options.fontsize = {tonumber(size), unit}
		end
	end

	-- determine which level corresponds to LaTeX's 'section'
	self.LaTeX_section_level = self:set_LaTeX_section_level(meta)

	if meta.statement then

		-- read boolean options
		local boolean_options = {
			amsthm = 'amsthm',
			aliases = 'aliases',
			acronyms = 'acronyms',
			swap_numbers = 'swap-numbers',
			supply_header = 'supply-header',
			only_statement = 'only-statement',
			define_in_header = 'define-in-header',
			citations = 'citations',
			pandoc_amsthm = 'pandoc-amsthm',
		}
		for key,option in pairs(boolean_options) do
			if type(meta.statement[option]) == 'boolean' then
				self.options[key] = meta.statement[option]
			end
		end

		-- read count-within option, level or LaTeX level name
		-- two locations:
		-- (1) pandoc-amsthm style options, in amsthm: counter_depth (number)
		-- (2) statement:count-within
		-- The latter prevails.
		if self.options.pandoc_amsthm and meta.amsthm 
				and meta.amsthm.counter_depth then
			local count_within = tonumber(stringify(meta.amsthm.counter_depth))
			if self:get_LaTeX_name_by_level(count_within) then
				self.options.count_within = count_within
			end
		end
		if meta.statement['count-within'] then
			local count_within = stringify(meta.statement['count-within']):lower()
			if self:get_level_by_LaTeX_name(count_within) then
				self.options.count_within = count_within
			elseif self:get_LaTeX_name_by_level(count_within) then
				self.options.count_within = count_within
			end
		end

	end -- end of `meta.statement` processing


end

---Setup:create_kinds_and_styles: Create kinds and styles
-- Populates Setup.kinds and Setup.styles with
-- default and user-defined kinds and styles.
-- Localizes the language and create aliases.
-- Updates:
--		self.styles
--		self.kinds 
--		self.aliases
--@param meta pandoc Meta object, document's metadata
--@return nil
function Setup:create_kinds_and_styles(meta)
	local language = self.options.language

	-- create default kinds and styles
	self:create_kinds_and_styles_defaults(meta)

	-- create user-defined kinds and styles
	self:create_kinds_and_styles_user(meta)

	-- @TODO read user-defined localizations?

	-- Check that shared counters are well defined
	-- A kind can only share a counter with a kind that doesn't
	for kind, definition in pairs(self.kinds) do
		if definition.counter and self.kinds[definition.counter]
			and self.kinds[definition.counter].counter
			and self.kinds[self.kinds[definition.counter].counter] then
				message('ERROR', 'Statement kind `'..kind..'` shares a counter'
												..' with a statement kind that also shares a'
												..' counter (`'..definition.counter..'`).'
												..' This is not allowed, things may break.')
		end
	end
	
	-- Finalize the kinds table
	-- ensure all labels are Inlines
	-- localize statement labels that aren't yet defined
	for kind_key, kind in pairs(self.kinds) do
		if kind.label then
			kind.label = pandoc.Inlines(kind.label)
		else
			kind.label = self.LOCALE[language]
									and self.LOCALE[language][kind_key]
									and pandoc.Inlines(self.LOCALE[language][kind_key])
									or nil
		end
	end

	-- populate the aliases map
	self:create_aliases()

end

---Setup.create_kinds_and_styles_defaults: create the default
-- kinds and styles.
--@param meta pandoc Meta object, document's metadata
--@return nil sets the Setup.kinds, Setup.styles, Setup.aliases tables
function Setup:create_kinds_and_styles_defaults(meta)
	local chosen_defaults = 'basic' -- 'basic' unless user says otherwise

	-- add_default_set: adds a given set of defaults to kinds and styles
	local function add_default_set(set_key)
		for kind,definition in pairs(self.DEFAULTS.KINDS[set_key]) do
			self.kinds[kind] = definition
		end
		for style,definition in pairs(self.DEFAULTS.STYLES[set_key]) do
			self.styles[style] = definition
		end
	end

	-- based_on_styles: builds styles based on other styles
	local function based_on_styles()

		for style,definition in pairs(self.styles) do

			if definition.based_on and self.styles[definition.based_on] then
				source_style = self.styles[definition.based_on]
				if source_style.based_on then
					message('ERROR', 'Defaults misconfigured: style `'..style..'` '
											..' is based on a style (`'..definition.based_on..'`)'
											..' that is itself based on another style.'
											..' this is not allowed.')
				else

					for key,value in pairs(source_style) do
						if not definition[key] then
							definition[key] = source_style[key]
						end
					end

					-- '' keys in derived styles are used to erase fields
					for key,value in pairs(definition) do
						if value == '' then
							definition[key] = nil
						end
					end

					-- once defined, not based on anymore
					-- (Ensures that if user redefines the basis style, it doesn't
					--	affect new styles based on this derived style)
					definition.based_on = nil

					-- No need for this in Lua as tables are passed by references
					-- but putting it there as a reminder of what happens
					-- self.styles[style] = definition

				end
			end

		end

	end

	-- MAIN FUNCTION BODY

	-- does the user want to check the filter's DEFAULTS files?
	if meta.statement and meta.statement['validate-defaults'] then
		self:validate_defaults()
	end

	-- user-selected defaults?
	if meta.statement and meta.statement.defaults then
		local new_defaults = stringify(meta.statement.defaults)
		if self.DEFAULTS.KINDS[new_defaults] then
			chosen_defaults = new_defaults
		end
	end

	-- add the 'none' defaults no matter what, then the chosen ones
	add_default_set('none')
	if chosen_defaults ~= 'none' then
		add_default_set(chosen_defaults)
	end

	-- fill in styles based on other styles
	based_on_styles()

	-- styles: convert newlines in 'space_after_head' 
	-- to linebreak_after_head = true
	for style,definition in pairs(self.styles) do
		if definition.space_after_head and
			(definition.space_after_head == '\n'
				or definition.space_after_head == '\\n'
				or definition.space_after_head == '\\newline'
				) then
			self.styles[style].linebreak_after_head = true
			self.styles[style].space_after_head = nil
		end
	end

	-- if count_within, change defaults with 'self' counter 
	-- to 'count_within' counter
	if self.options.count_within then
		for kind,definition in pairs(self.kinds) do
			if definition.counter == 'self' then 
				self.kinds[kind].counter = self.options.count_within
			end
		end
	end

end

---Setup:create_kinds_and_styles_user: Create user-defined
-- kinds and styles. 
-- Styles may be based on other styles, so we need to 
-- proceed recursively without getting into endless loops.
-- Updates:
--		self.styles
--		self.kinds 
--@param meta pandoc Meta object, document's metadata
--@return nil 
function Setup:create_kinds_and_styles_user(meta)
	local options = self.options -- points to the options table
	local styles = self.styles -- points to the styles table
	local new_kinds, new_styles

	---dash_keys_to_underscore: replace dashes with underscores in a 
	--	map key's.
	--@param map table a map to be converted
	--@return
	local function dash_keys_to_underscore(map)
		new_map = {}
		for key,_ in pairs(map) do
			new_map[key:gsub('%-','_')] = map[key]
		end
		return new_map
	end

	-- insert_new_style: set a style in `new_styles`
	-- Insert a style in `new_styles`, erasing any previous value for it.
	-- If the definition isn't a map, assume an alias: 'style1: style2'
	--@param style string style key
	--@param definition definition map
	local function insert_new_style(style,definition)
		if type(definition) == 'table' then
			new_styles[style] = definition
		elseif definition then
			new_styles[style] = { based_on = stringify(definition) }
		end
	end

	--- insert_new_kind: function to insert a kind in `new_kinds`
	local function insert_new_kind(kind,definition)
		if type(definition) == 'table' then
			new_kinds[kind] = definition
		else
			message('ERROR', 'Could not understand the definition of'
												..'statement kind '..kind..'.'
												.." I've ignored it.")
		end
	end

	-- recursive function to define a style
	--@param style string the style name
	--@param definition map the style definition in user's metadata
	--@recursion trail pandoc List, list of styles defined in a recursion
	local function try_define_style(style, definition, recursion_trail)
		-- if already defined, we're good
		if definition.is_defined then return end
		-- replace dashes with underscores
		definition = dash_keys_to_underscore(definition)
		-- if `based_on` is set, possible cases:
		--		- basis not in defaults or new_styles: ignore
		--		- current style among those to be defined: circularity, ignore
		--		- bases is in new_styles and not defined: recursion step
		--		- basis is in new_styles but already defined: go ahead
		--		- basis is in styles and not in new_styles: go ahead
		if definition.based_on then
			local parent_style = stringify(definition.based_on)

			if not styles[parent_style] 
					and not new_styles[parent_style] then
				message('ERROR', 'Style `'..style..'` is supposed to be based'
													..' on style `'..parent_style..'`'
													..' but I cannot find the latter.'
													..' The `based-on` parameter will be ignored.')
				definition.based_on = nil

			elseif recursion_trail and recursion_trail:find(style) then
				local m_str = recursion_trail[1]
				for i = 2, #recursion_trail do
					m_str = m_str..' -> '..recursion_trail[i]
				end
				m_str = m_str..' -> '..style
				message('ERROR', 'Circularity in style definitions: '
													..m_str..'. The `based-on parameter'
													..' of style '..style..' is ignored.')
				definition.based_on = nil

			elseif new_styles[parent_style]
						and not new_styles[parent_style].is_defined then
				recursion_trail = recursion_trail or pandoc.List:new()
				recursion_trail:insert(style)
				try_define_style(parent_style, new_styles[parent_style], 
													recursion_trail)
				self:set_style(style, definition, new_styles)
				definition.is_defined = true
				recursion_trail:remove()
				return -- recursion complete, we exit

			end
		end
		-- any case other than the recursive one above,
		-- we're clear to define the style:
		self:set_style(style, definition, new_styles)
		definition.is_defined = true

	end

	--- parse_by_style: parse a list of kinds for a given style
	-- in the style of pandoc-amsthm kind definitions.
	-- remark: Case
	-- plain: [Theorem, Lemma, Corollary, Conjecture, Proposition]
	-- definition:
	-- - Definition
	-- remark-unnumbered: ...
	--@param style_key string key of the styles table
	--@param list List, string or Inlines, kinds
	local function parse_by_style(style_key, list, counter)
		if type(list) == 'string' or type(list) == 'Inlines' then
			list = pandoc.List:new( {list} )
		end
		if type(list) == 'List' then
			for _,item in ipairs(list) do
				-- each item is a kind's label, or a map (kind = list_subkinds)
				if type(item) == 'string' or type(item) == 'Inlines' then
					local kind = stringify(item):gsub('[^%w]','_')
					insert_new_kind(kind, {
							label = item,
							counter = counter, -- may be nil, set_kind takes care of it
							style = style_key,
					})
				end
			end
		end
	end
	--- parse_by_styles: parse a Meta map looking for 
	-- keys that correspond to a style, and parse each of these
	-- as a list of kinds.
	local function parse_by_styles(map)
		for style,list in pairs(styles) do
			if map[style] then 
				parse_by_style(style, map[style])
			end
			-- is there a <style>-unnumbered list to process as well?
			-- only process if it's not already a style
			if map[style..'-unnumbered'] 
					and not styles[style..'-unnumbered'] then 
				parse_by_style(style, map[style..'-unnumbered'], 'none')
			end
		end
	end

	-- MAIN FUNCTION BODY

	-- User-defined styles
	-- The ones in 'statement' prevail over those in 'statement-styles'
	-- @note using type(X) == 'table' to test both existence and type
	if type(meta['statement-styles']) == 'table' 
			or meta.statement and type(meta.statement.styles) == 'table' then

		-- gather the styles to be defined in a map
		-- the ones in 'statement' normally prevail over those in 'statement-styles'
		new_styles = {}

		if type(meta['statement-styles']) == 'table' then
			for style,definition in pairs(meta['statement-styles']) do
				insert_new_style(style, definition)
			end
		end
		if meta.statement and type(meta.statement.styles) == 'table' then
			for style,definition in pairs(meta.statement.styles) do
				insert_new_style(style, definition)
			end
		end

		-- main loop to define styles
		for style,definition in pairs(new_styles) do
			try_define_style(style, definition)
		end

	end -- end of user-defined styles

	-- User-defined kinds
	-- Can be found in four locations.
	--		(a) full definitions in 'statement:kinds:' and 'statement-kinds'
	--				(the former prevails)
	--		(b) by-style label only in 'statement' or 'pandoc-amsthm'				
	-- @note using type(X) == 'table' to test both existence and type
	if meta.statement
			or type(meta['statement-kinds']) == 'table' 
			or options.pandoc_amsthm and type(meta.amsthm) == 'table' then

		-- Gather kinds to be defined
		new_kinds = {} -- map

		-- Gather definitions from four locations
		-- latter ones erase former ones
		-- (1) pandoc-amsthm's `amsthm` field, kinds given by style
		if options.pandoc_amsthm and type(meta.amsthm) == 'table' then
			parse_by_styles(meta.amsthm)
		end
		-- (2) `statement` field, kinds given by style
		if meta.statement then 
			parse_by_styles(meta.statement)
		end
		-- (3) `statement-kinds` map of full definitions
		if type(meta['statement-kinds']) == 'table' then
			for kind,definition in pairs(meta['statement-kinds']) do
				insert_new_kind(kind,definition)
			end
		end
		-- (4) `statement:kinds` map of full definitions
		if meta.statement and type(meta.statement.kinds) == 'table' then
			for kind,definition in pairs(meta.statement.kinds) do
				insert_new_kind(kind,definition)
			end
		end

		-- main loop to define the kind definitions we've gathered
		for kind,definition in pairs(new_kinds) do
			self:set_kind(kind,definition,new_kinds)
		end

	end -- end of statement kinds

end

---Setup:create_aliases: create map of kind aliases
-- Populates self.aliases if the `aliases` options is set
function Setup:create_aliases()

	if not self.options.aliases then
		return
	end
	
	-- add_alias: function to add an alias to self.aliases
	-- 		ensure it's a string, use lowercase for case-insensitive matches
	local function add_alias(alias, kind_key)
		alias = stringify(alias):lower()
		-- warn if clash
		if self.aliases[alias] and self.aliases[alias] ~= kind_key then
			message('WARNING', 'Cannot use `'..alias..'` as an alias of `'..kind_key..'`'
													..', it is already an alias of `'..self.aliases[alias]..'`.')
		else
			self.aliases[alias] = kind_key
		end
	end


	for kind_key,kind in pairs(self.kinds) do
		-- user-defined aliases?
		if kind.aliases then
			for _,alias in ipairs(kind.aliases) do
				add_alias(alias,kind_key)
			end
		end
		-- use the kind's prefix as alias, if any
		if kind.prefix then
			add_alias(kind.prefix,kind_key) 
		end
		-- us the kind's label
		if kind.label then
			add_alias(kind.label,kind_key)
		end
	end


end

---Setup:set_style: create or set a style based on an options map
-- Creates a new style or modify an existing one, based on options.
--@param name string style key
--@param map table style definition from user metadata
--@param new_styles table map of new styles to be defined
function Setup:set_style(style,map,new_styles)
	local styles = self.styles -- points to the styles map
	local length_format = Helpers.length_format
	local font_format = Helpers.length_format
	local map = map or {}
	local new_style = {}
	local based_on = map.based_on and stringify(map.based_on) or nil

	---merge_valid_options: build a map of valid options
	-- from a main map and basis map.
	-- we'll apply this to the main map but also
	-- to the `custom_label_changes` submap.
	--@param map, table or nil the values explicitly specified
	--@param basis, table or nil the based_on backup values
	local function merge_valid_options(map,basis)
		local new_map = {}
		-- length fields: not that `space_after_head` is added below if needed
		local length_fields = pandoc.List:new({
			'margin_top', 'margin_bottom', 'margin_left', 'margin_right',
			'indent',
		})
		-- Note: keeping font fields separate in case we wanted to validate them.
		-- Presently no validation, they are treated like string fields.
		local font_fields = {
			'body_font', 'head_font', 'crossref_font',
		}
		local string_fields = { 
			'punctuation', 'heading_pattern'
		}

		-- handles linebreak_after_head style
		-- (a) linebreak_after_head already is set: ignore space_after_head
		-- (b) space_after_head is \n or \newline: set linebreak_after_head
		-- (c) otherwise, read space_after_head as a length
		-- special case: space_after_head can be `\n` or `\\n` or `\\newline`
		-- if not, assume it's a length
		if map and map.linebreak_after_head 
				or basis and basis.linebreak_after_head then
			new_map.linebreak_after_head = true		
		elseif map and map.space_after_head and
				(map.space_after_head == 
								pandoc.MetaInlines(pandoc.RawInline('tex', '\\n'))
					or map.space_after_head == 
								pandoc.MetaInlines(pandoc.RawInline('tex', '\\newline'))
					or map.space_after_head == 
								pandoc.MetaInlines(pandoc.RawInline('latex', '\\n'))
					or map.space_after_head == 
								pandoc.MetaInlines(pandoc.RawInline('latex', '\\newline'))
				) then
			new_map.linebreak_after_head = true
		else
			length_fields:insert('space_after_head')
		end

		-- insert fields
		for _,length_field in ipairs(length_fields) do
			new_map[length_field] = (map and map[length_field] 
																and length_format(map[length_field])
																and stringify(map[length_field]))
																or basis and basis[length_field]
		end
		for _,font_field in ipairs(font_fields) do
			new_map[font_field] = map and map[font_field]
															and stringify(map[font_field])
															or basis and basis[font_field]
		end
		for _,string_field in ipairs(string_fields) do
			new_map[string_field] = map and map[string_field] 
																and stringify(map[string_field])
																or basis and basis[string_field]
		end

		return new_map

	end

	-- MAIN FUNCTION BODY

	-- determine the style's basis: 
	--	(1) user-defined basis, or 
	--	(2) default version of this style if any,
	--	(3) otherwise 'plain', otherwise 'empty'
	-- user-defined basis may be one of the new styles to be defined
	if based_on then
		if styles[based_on] or 	new_styles and new_styles[based_on]
														and based_on ~= style then
			-- leave based_on as is
		elseif based_on == style then
			message('ERROR', 'Style '..style..' defined to be based on itself.'
								..'This is only allowed if defaults provide this style.')
			based_on = nil
		else
			message('ERROR', 'Style '..style..' could not be based on'
												..'`'..based_on..'`. Check if the latter'
												..' is defined.')
			based_on = nil
		end
	end
	if not based_on then 
 		if styles[style] then
			based_on = style
		elseif styles['plain'] then
			based_on = 'plain'
		elseif styles['empty'] then
			based_on = 'empty'
		else
			message('ERROR','Filter defaults misconfigured:'
				..' no `empty` style provided.'
				..' Definition for '..style..' must be complete.'
				.." If it isn't things may break.")
		end
	end

	-- read do_not_define_in_FORMAT fields 
	for key,value in pairs(map) do
		if key:match('^do_not_define_in_') then
			new_style[key] = stringify(value)
		end
	end

	-- create the custom_label_changes map
	if map.custom_label_changes 
			or styles[based_on].custom_label_changes then
		new_style.custom_label_changes = 
					merge_valid_options(map.custom_label_changes, 
															styles[based_on].custom_label_changes)
	end

	-- merge remaining options
	local merge = merge_valid_options(map, styles[based_on])
	for k,v in pairs(merge) do
		new_style[k] = v
	end 

	-- Special checks to avoid LaTeX crashes
	if not new_style.space_after_head 
		or new_style.space_after_head == '' then
			new_style.space_after_head = '0pt'
	end

	-- store the result
	styles[style] = new_style

end

---Setup:set_kind: create or set a kind based on an options map
-- Creates a new style or modify an existing one, based on options.
--@param kind string kind key
--@param map table, kind definition from user metadata
--@param new_kinds table (optional), new kinds to be defined
function Setup:set_kind(kind,map,new_kinds)
	local styles = self.styles -- points to the styles map
	local kinds = self.kinds -- points to the kinds map
	local map = map or {}
	local new_kind = {}

	-- if kind already defined, get original fields
	if kinds[kind] then
		new_kind = kinds[kind]
	end

	-- Ensure kind has a valid counter
	-- if shared counter, check that it exists or is about to be defined
	if map.counter then
		local counter = stringify(map.counter)
		if counter == 'self' or counter == 'none' then
			new_kind.counter = counter
		elseif counter == kind then -- using own name as counter
			new_kind.counter = 'self'
		elseif self:get_level_by_LaTeX_name(counter) then -- latex counter
			new_kind.counter = counter
		elseif self:get_LaTeX_name_by_level(counter) then -- level counter
			new_kind.counter = counter
		elseif kinds[counter] or new_kinds and new_kinds[counter] then
			new_kind.counter = counter
		else
			message('ERROR', 'Cannot understand counter setting `'..counter
											..'` to define statement kind '..kind..'.')
		end
	end
	-- if no counter, use the pre-existing counter if there's one
	-- otherwise use the first primary counter found in `kinds`
	-- or `options.count_within` or `self`	
	if not map.counter then
		if not new_kind.counter then
			for kind,definition in pairs(kinds) do
				if definition.counter == 'self'
					or self:get_level_by_LaTeX_name(definition.counter) 
					or self:get_LaTeX_name_by_level(definition.counter) then
						new_kind.counter = kind
						break
				end
			end
		end
		if not new_kind.counter then
			new_kind.counter = self.options.count_within or 'self'
		end
	end

	-- validate the kind's style
	-- if none (or bad) provided, use 'plain' or 'empty'
	if map.style then
		map.style = stringify(map.style)
	 	if styles[map.style] then
			new_kind.style = map.style
		else
			message('ERROR', 'Style `'.. map.style 
											..'` for statement kind `'..kind
											..'` is not defined.')
		end
	end
	if not map.style then 
		if styles['plain'] then
			new_kind.style = 'plain'
		elseif styles['empty'] then
			new_kind.style = 'empty'
		else -- use any style you can find!
			for style_key,_ in pairs(styles) do
				new_kind.style = style_key
				break
			end
		end
		if new_kind.style then
			message('INFO', 'Statement kind `'..kind..'`'
											..' has not been given a style.'
											..' Using `'..new_kind.style..'`.')
		else
			message('ERROR','Defaults misconfigured:'
													..'no `empty` style provided.')
			new_kind.style = 'empty' -- may still work e.g. in HTML
		end
	end

	-- validate and insert options
	local string_fields = { 
		'prefix', 
	}
	local inlines_fields = {
		'label'
	}
	local strings_list_fields = {
		'aliases',
	}
	local map_fields = {
		'custom_label_style'
	}
	for _,string_field in ipairs(string_fields) do
		if map[string_field] then
			new_kind[string_field] = stringify(map[string_field])
		end
	end
	for _,inlines_field in ipairs(inlines_fields) do
		if map[inlines_field] then
			if type(map[inlines_field]) == 'Inlines' then
				new_kind[inlines_field] = map[inlines_field]
			else
				new_kind[inlines_field] = pandoc.Inlines(pandoc.Str(
																		stringify(map[inlines_field])
																	))
			end
		end
	end
	for _,strings_list_field in ipairs(strings_list_fields) do
		if map[strings_list_field] then
			if type(map[strings_list_field]) == 'List' then
				new_kind[strings_list_field] = map[strings_list_field]
			elseif type(map[strings_list_field]) == 'string' 
					or type(map[strings_list_field]) == 'Inlines' then
				new_kind[strings_list_field] = pandoc.List:new(
																		{stringify(map[strings_list_field])}
																	)
			end
		end
	end
	for _,map_field in ipairs(map_fields) do
		if map[map_field] then
			new_kind[map_field] = map[map_field]
		end
	end

	-- store in kinds table
	kinds[kind] = new_kind

end

--- Setup:create_counters create level counters based on statement kinds
-- Creates
--	self.counters
--@param format (optional) desired format if other than FORMAT
--@return nil, creates the self.counters table
function Setup:create_counters(format)
	local format = format or FORMAT
	local deepest_level = 0 -- deepest level needed
	local reset_with_level = {} -- map kind = level

	-- make the reset_with_level map
	-- and determine the deepest level needed
	for kind_key,definition in pairs(self.kinds) do
		local level = tonumber(definition.counter) or 
									self:get_level_by_LaTeX_name(definition.counter)
		if level then
			if level >=1 and level <= 6 then
				reset_with_level[kind_key] = level
				if level > deepest_level then
					deepest_level = level
				end
			else
				message('WARNING','Kind '..kind_key..' was assigned level '..tostring(level)
													..', which is outside the range 1-6 of Pandoc levels.'
													..' Counters for these statement may not work as desired.')
			end
		end
	end

	-- create levels up to the level needed
	-- use Pandoc's number_offset if html output
	-- default format: '%s' for level 1, '%p.%s' for others
	for i=1, deepest_level do -- will not do anything if `deepest_level` is 0
		self.counters[i] = {
				count = FORMAT:match('html') and PANDOC_WRITER_OPTIONS.number_offset[i]
								or 0,
				reset = pandoc.List:new(),
				format = i == 1 and '%s'
											or '%p.%s',
		}
		for kind,level in pairs(reset_with_level) do
			if level == i then
				self.counters[i].reset:insert(kind)
			end
		end
	end

	-- insert each kind in the reset list of its counter


end

--- Setup:write_counter: format a counter as string
--@param level number, counter level
--@return string formatted counter
function Setup:write_counter(level)

	-- counter_format: function to be used in recursion
	-- The recursion list tracks the levels encountered in recursion
	-- to ensure the function doesn't get into an infinite loop.
	local function counter_format(lvl, recursion)
		local recursion = recursion or pandoc.List:new()
		local result = ''

		if not self.counters[lvl] then
			message('WARNING', 'No counter for lvl '..tostring(lvl)..'.')
			result = '??'
		else
			result = self.counters[lvl].format or '%s'
			-- remember that we're currently processing this lvl
			recursion:insert(lvl)
			-- replace %s by the value of this counter
			local self_count = self.counters[lvl].count or 0
			result = result:gsub('%%s', tostring(self_count))
			-- replace %p by the formatted previous lvl counter
			-- unless we're already processing that lvl in recursion
			if lvl > 1 and not recursion:find(lvl-1) then
				result = result:gsub('%%p',counter_format(lvl-1, recursion))
			end
			-- replace %1, %2, ... by the value of the corresponding counter
			-- unless we're already processing them in recursion
			for i = 1, 6 do
				if result:match('%%'..tostring(i)) and not recursion:find(i) then
					result = result:gsub('%%'..tostring(i), 
																counter_format(i, recursion))
				end
			end
		end

		return result

	end

	return counter_format(level)

end

---Setup:increment_counter: increment the counter of a level
-- Increments a level's counter and reset any statement
-- count that is counted within that level.
-- Reset the lower counters to 0 or their --number-offset value
-- (Mirroring Pandoc's `--number-offset` behaviour
-- The counters table tells us which statement counters to reset.
--@param level number, the level to be incremented
function Setup:increment_counter(level)
	if self.counters[level] then

		self.counters[level].count = self.counters[level].count + 1

		if self.counters[level].reset then
			for _,kind_key in ipairs(self.counters[level].reset) do
				self.kinds[kind_key].count = 0
			end
		end

		for i = level + 1, 6 do
			if self.counters[i] then
				self.counters[i].count = PANDOC_WRITER_OPTIONS.number_offset[i]
																	or 0
			end
		end

	end
end

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

-- # Statement class

--- Statement: class for statement objects.
Statement = {
	element = nil, -- original element to be turned into statement
	kind = nil, -- string, key of `kinds`
	identifier = nil, -- string, Pandoc identifier
	custom_label = nil, -- Inlines, user-provided label
	crossref_label = nil, -- Inlines, label used to crossreference the statement
	label = nil, -- Inlines, label to display in non-LaTeX format e.g. "Theorem 1.1"
	acronym = nil, -- Inlines, acronym
	info = nil, -- Inlines, user-provided info
	content = nil, -- Blocks, statement's content
	is_numbered = true, -- whether a statement is numbered
}
---Statement:is_statement Whether an element is a statement.
-- Simple wrapper for the Div_is_statement and 
-- DefinitionList_is_statement functions.
--@param elem pandoc element, should be Div or DefinitionList
--@param setup (optional) a Setup class object, to be used when
--			the function is called from the setup object
--@return list or nil, pandoc List of kinds matched
function Statement:is_statement(elem,setup)
	setup = setup or self.setup
	if elem.t then
		if elem.t == 'Div' then
			return self:Div_is_statement(elem,setup)
		elseif elem.t == 'DefinitionList' 
					and elem.content[1] then
			return self:DefListitem_is_statement(elem.content[1],setup)
		end
	end
end

---Statement:is_kind_key: whether a string is a kind key or an alias.
-- If yes, return the kind key.
--@param str string to be tested
--@param setup (optional) a Setup class object, to be used when
--			the function is called from the setup object
--@return kind_key string a key of the kinds table
function Statement:is_kind_key(str, setup)
	setup = setup or self.setup
	local kinds = setup.kinds -- points to the kinds table
	local options = setup.options -- points to the options table
	local aliases = setup.aliases -- pointed to the aliases table

	-- safety check
	if type(str) ~= 'string' then
		message('ERROR', 'Testing whether a non-string is a kind key.'
											.. 'This should not have happened.')
		return
	end

	if kinds[str] then
		return str
	else
		-- try lowercase match, 
		-- and aliases that are all lowercase
		str = str:lower()
		if kinds[str] then
			return str
		elseif aliases[str] then
			return aliases[str]
		end
	end

end

--- Statement:parse_heading_inlines: parse statement heading inlines
-- into custom label, acronym, info if present, and extract
-- them from those inlines. Return them in a table.
-- Expected format, where [...] means optional:
--		[**[[Acronym] Custom Label] [Info1].**] [Info2[.]] Content
--		[**[[Acronym] Custom Label] [Info1]**.] [Info2[.]] Content
-- Where:
--		- Acronym is Inlines delimited by matching parentheses, e.g. (NPE)
--		- Info1, Info2 are either Inlines delimited by matching 
--			parentheses, or a Cite element,
--		- only one of Info1 or Info2 is present. The latter is treated
--			as part of the content otherwise.
--		- single spaces before the heading or surrounding the dot
--			are tolerated.
--		- a single bracketed content is assumed to be acronym rather than info.
-- Updates:
--		self.custom_label Inlines or nil, content of the label if found
--		self.acronym Inlines or nil, acronym
--		self.content Blocks, remainder of the statement after extraction
--@return table { acronym = Inlines or nil,
--								custom_label = Inlines or nil,
--								info = Inlines or nil
--								remainder = Inlines
--								}
--				or nil if no modification made
function Statement:parse_heading_inlines(inlines)
	local acro_delimiters = self.setup.options.acronym_delimiters 
											or {'(',')'} -- acronym delimiters
	local info_delimiters = self.setup.options.info_delimiters 
											or {'(',')'} -- info delimiters
	local custom_label, acronym, info

	--- parse_Strong: try to parse a Strong element into acronym,
	-- label and info.
	-- @param elem pandoc Strong element
	-- @return info, Inlines or Cite information if found
	-- @return cust_lab, Inlines custom label if found
	-- @return acronym, Inlines, acronym if found
	function parse_Strong(elem)
		-- must clone to avoid changing the original element 
		-- in case parsing fails
		local result = elem.content:clone()
		local info, cust_lab, acro

		-- remove trailing space / dot
		result = self:trim_dot_space(result, 'reverse')

		-- Acronym is first content between balanced brackets
		-- encountered in forward order
		if #result > 0 then
			acro, result = self:extract_fbb(result, 'forward', acro_delimiters)
			self:trim_dot_space(result, 'forward')
		end

		-- Info is first Cite or content between balanced brackets 
		-- encountered in reverse order.
		if result[#result].t == 'Cite' then
			info = pandoc.Inlines(result[#result])
			result:remove(#result)
			result = self:trim_dot_space(result, 'reverse')
		else
			info, result = self:extract_fbb(result, 'reverse', info_delimiters)
			result = self:trim_dot_space(result, 'reverse')
		end
			
		-- Custom label is whatever remains
		if #result > 0 then
			cust_lab = result
		end

		-- If we have acro but not cust_label that's a failure
		if acro and not cust_lab then
			return nil, nil, nil
		else
			return info, cust_lab, acro
		end
	end

	-- FUNCTION BODY

	-- prevent modification of the source document by cloning
	if inlines and type(inlines) == 'Inlines' and #inlines > 0 then
		inlines = inlines:clone()
	else
		return
	end

	-- inlines start with Strong?
	-- if yes, try to parse and remove if successful
	if inlines[1].t == 'Strong' then
		info, custom_label, acronym = parse_Strong(inlines[1])
		if custom_label or info then
			inlines:remove(1)
			inlines = self:trim_dot_space(inlines, 'forward')
		end
	end

	-- if we don't have info yet, try to find it at the beginning
	-- of (what remains of) the Para's content.
	if not info then
		if inlines[1] and inlines[1].t == 'Cite' then
			info = pandoc.Inlines(inlines[1])
			inlines:remove(1)
			inlines = self:trim_dot_space(inlines, 'forward')
		else
			info, inlines = self:extract_fbb(inlines, 
																	'forward', info_delimiters)
			inlines = self:trim_dot_space(inlines, 'forward')
		end

	end

	-- return a table if we found anything
	if custom_label or info then
		return {
			acronym = acronym,
			custom_label = custom_label,
			info = info,
			remainder = #inlines>0 and inlines
									or nil
		}
	end

end

---Statement:parse_indentifier find and extract a \label{...}
-- or {#...} identifier from Inlines
function Statement:parse_identifier(inlines)
	local id -- string, identifier
	local result

	--pick_id: a filter to pick ids in RawInlines or Str
	local pick_id = {
		RawInline = function(elem)
			id = elem.text:match('^\\label{(%g+)}$')
			if id then return {} end
		end,
		Str = function(elem)
			id = elem.text:match('^{#(%g+)}$')
			if id then return {} end
		end,
	}

	if inlines and type(inlines) == 'Inlines' and #inlines > 0 then

		-- prevent modification of the source document by cloning
		-- and apply the filter
		result = inlines:clone():walk(pick_id)
		-- if something found, return the identifier and modified inlines
		if id then
			return id, result
		end

	end
end

---Statement:Div_is_statement Whether an Div element is a statement.
-- If yes, returns a list of kinds the element matches.
--@param elem (optional) pandoc Div element, defaults to self.element
--@param setup (optional) a Setup class object, to be used when
--			the function is called from the setup object
--@return List or nil, pandoc List of kinds the element matches
function Statement:Div_is_statement(elem,setup)
	setup = setup or self.setup
	elem = elem or self.element
	local options = setup.options -- pointer to the options table
	local kinds = setup.kinds -- pointer to the kinds table

	-- safety check
	if not elem.t or elem.t ~= 'Div' then
		message('ERROR', 	'Non-Div element passed to the Div_is_statement function,'
											..' this should not have happened.')
		return
	end

	-- collect the element's classes that match a statement kind
	-- check aliases if `options.aliases` is true
	local matches = pandoc.List:new()
	for _,class in ipairs(elem.classes) do
		-- nb, needs to pass the setup to is_kind_key 
		-- in case the statement isn't created yet
		local kind_key = self:is_kind_key(class, setup)
		-- if found, add provided it's not a duplicate
		if kind_key and not matches:find(kind_key) then
			matches:insert(kind_key)
		end
	end

	-- fail if no match, or if the options require every statement to
	-- have the `statement` kind and we don't have it. 
	-- if success, remove the statement kind if we have another kind as well.
	if #matches == 0 
		or (options.only_statement and not matches:find('statement')) then
			return nil
	else
		if #matches > 1 and matches:includes('statement') then
			local _, pos = matches:find('statement')
			matches:remove(pos)
		end
		return matches
	end

end

---Statement:parse_Div parse a Div element into a statement
-- Parses a pandoc Div element into a statement, setting its
-- kind, identifier, label, info, acronym, content. 
-- Creates new kinds and styles as needed.
-- Updates:
--		self.content
--		self.identifier
-- 		self.label
--		self.custom_label
--		self.kind
--		self.acronym
--		self.crossref_label
-- 		
--@param elem pandoc Div element (optional) element to be parsed
--											defaults to self.element
--@return bool true if successful, false if not
function Statement:parse_Div(elem)
	local setup = self.setup -- points to the setup table
	local options = setup.options -- points to the options table
	local kinds = setup.kinds -- points to the kinds table
	local aliases = setup.aliases -- points to the aliases table
	elem = elem or self.element

	-- safety check
	if not elem.t or elem.t ~= 'Div' then
		message('ERROR', 	'Non-Div element passed to the parse Div function,'
											..' this should not have happened.')
		return
	end

	-- find the element's base kind
	--	Div_is_statement() returns the kinds matched by self.element
	local kinds_matched = self:Div_is_statement()
	if not kinds_matched then 
		message('ERROR', 	'Div element passed to the parse Div function,'
											..' without Div_is_statement check,'
											..'this should not have happened.')
		return 
	end
	-- warn if there's still more than one kind
	if #kinds_matched > 1 then
		local str = ''
		for _,match in ipairs(kinds_matched) do
			str = str .. ' ' .. match
		end
		message('WARNING', 'A Div matched several statement kinds: '
			.. str .. '. Treated as kind '.. kinds_matched[1] ..'.')
	end
	self.kind = kinds_matched[1]

	-- remove the kinds matched from the Div's attributes
	for _,kind in ipairs(kinds_matched) do
		local _,position = self.element.classes:find(kind)
		self.element.classes:remove(position)
	end

	-- get the Div's user-specified id, if any
	if elem.identifier and elem.identifier ~= '' then
		self.identifier = elem.identifier
	end

	-- extract any label, acronym, info
	-- these are in the first paragraph, if any
	-- NOTE: side-effect, the original tree's element is modified
	if elem.content[1] and elem.content[1].t == 'Para' then
		local result = self:parse_heading_inlines(elem.content[1].content)
		if result then
			self.acronym = result.acronym
			self.custom_label = result.custom_label
			self.info = result.info
			-- if any remainder, place in the Para otherwise remove
			if result.remainder and #result.remainder > 0 then
				elem.content[1].content = result.remainder
			else
				elem.content:remove(1)
			end
		end
	end

	-- store the content
	self.content = elem.content

	return true

end

-- !input Statement.parse_Div_heading -- parse Div element as statement
---Statement:DefListitem_is_statement: whether a DefinitionList item 
-- is a statement. If yes, returns the kind it matches.
-- An item is a statement if its defined expression starts
-- with a Str element whose text matches a statement kind (or alias).
--@param elem (optional) item of a pandoc DefinitionList,
--							defaults to self.element[1]
--@param setup (optional) a Setup class object, to be used when
--			the function is called from the setup object
--@return string or nil element's kind (key of `setup.kinds`) or nil
function Statement:DefListitem_is_statement(item, setup)
	setup = setup or self.setup -- pointer to the setup table
	local kinds = setup.kinds -- pointer to the kinds table
	item = item or self.element 
									and self.element.t == 'DefinitionList' 
									and self.element.content[1]
	local expression -- Inlines expression defined, i.e. item[1]
	local kind -- kind key, if found
	--local new_item -- modified item

	expression = item[1]
	if expression[1].t and expression[1].t == 'Str' then

		-- ignore any dot at the end of the string
		local str = expression[1].text:match('(.+)%.$') or expression[1].text
		-- try a key match, return
	  return self:is_kind_key(str, setup)

	end

end

---Statement:parse_DefList parse a DefinitionList element into a statement
-- Parses a DefinitionList element into a statement, setting its
-- kind, identifier, label, info, acronym, content. 
-- Turns its Plain blocks into Para, for uniformity with fenced Divs.
-- Assumes the element contains only one DefinitionList item.
-- Creates new kinds and styles as needed.
-- Updates:
--		self.content
--		self.identifier
-- 		self.label
--		self.custom_label
--		self.kind
--		self.acronym
--		self.crossref_label
-- 		
--@param elem pandoc DefinitionList element (optional) element to be parsed
--											defaults to self.element
--@return bool true if successful, false if not
function Statement:parse_DefList(elem)
	local setup = self.setup -- points to the setup table
	local options = setup.options -- points to the options table
	local kinds = setup.kinds -- points to the kinds table
	local aliases = setup.aliases -- points to the aliases table
	elem = elem or self.element
	local item -- the first DefinitionList item
	local expression, definitions -- the item's expression and definitions
	local identifier -- string, user-provided identifier if found

	-- safety check
	if not elem.t or elem.t ~= 'DefinitionList' then
		message('ERROR', 	'Non-DefinitionList element passed to the parse_DefList function,'
											..' this should not have happened.')
		return
	end

	-- ignore empty DefinitionList
	if not elem.content[1] then
		return
	end

	self.kind, item = self:parse_DefList_kind(elem.content[1])

	-- return if failed to match
	if not self.kind then
		message('ERROR', 	'DefinitionList element passed to the parse DefinitionList function,'
											..' without DefListitem_is_statement check,'
											..'this should not have happened.')
		return 
	end

	-- item[1]: expression defined
	-- item[2]: list of Blocks, definitions
	expression = item[1]
	definitions = item[2]

	-- Turn top-level Plain in definitions into Para
	for _,definition in ipairs(definitions) do
		for i = 1, #definition do
			if definition[i].t and definition[i].t == 'Plain' then
				definition[i] = pandoc.Para(definition[i].content)
			end
		end
	end

	-- Process expression: extract any label, info, acronym
	-- extract id,
	-- insert the remainder in the first paragraph of 
	-- the definition.

	-- extract any label, info, acronym from expression
	local result = self:parse_heading_inlines(expression)
	if result then
		self.acronym = result.acronym
		self.custom_label = result.custom_label
		self.info = result.info
		expression = result.remainder
	end

	-- look for an id in the expression
	local identifier, new_expression = self:parse_identifier(expression)
	if identifier then
		self.identifier = identifier
		expression = new_expression
	end

	-- clean up
	expression = Statement:trim_dot_space(expression)
	expression = Statement:trim_dot_space(expression, 'reverse')

	-- if any remainder, insert in the first Para of the first definition
	-- or create a new Para if necessary
	if expression and #expression > 0 then
		definitions[1] = definitions[1] or pandoc.List:new()
		if definitions[1][1] and definitions[1][1].t == 'Para' then
			definitions[1][1].content = expression:extend(
																		definitions[1][1].content)
		else 
			definitions[1]:insert(1, pandoc.Para(expression))
		end
	end

	-- concatenate definitions as the statement's content
	self.content = pandoc.List:new() -- Blocks
	for _,definition in ipairs(definitions) do
		if #definition > 0 then
			self.content:extend(definition)
		end
	end

	return true

end

---Statement:parse_DefList_kind: extracts the kind from a DefList, if any
-- A DefinitionList item is a statement if its defined expression starts
-- with a Str element whose text matches a statement kind (or alias).
--@param item item of DefinitionList element
--@return string or nil element's kind (key of `setup.kinds`) or nil
--@return item the modified DefinitionList item
function Statement:parse_DefList_kind(item)
	setup = setup or self.setup -- pointer to the setup table
	local kinds = setup.kinds -- pointer to the kinds table
	item = item or self.element 
					and self.element.t == 'DefinitionList' 
					and self.element.content[1]
	local expression -- Inlines expression defined, i.e. item[1]
	local kind -- kind key, if found
	--local new_item -- modified item

	if item then

		expression = item[1]
		if expression[1].t and expression[1].t == 'Str' then

			-- check that it does match a kind
			-- ignore any dot at the end of the string
			local str = expression[1].text:match('(.+)%.$') or expression[1].text
			kind = self:is_kind_key(str, setup)

			-- if found, extract it
			-- warning, side-effect: this modifies the document's own blocks.
		  if kind then

		  	expression = item[1]
		  	-- remove the 'Str' that matched
		  	expression:remove(1)
		  	-- remove any leading space dot left
		  	expression = self:trim_dot_space(expression, 'forward')
		  	-- store
		  	item[1] = expression
		  	-- return positive result
		  	return kind, item

		  end

		end

	end

end

--- Statement:extract_fbb: extract the first content found between 
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
function Statement:extract_fbb(inlines, direction, delimiters)

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

---Statement:trim_dot_space: remove leading/trailing dot space in Inlines.
--@param inlines pandoc Inlines
--@param direction 'reverse' for trailing, otherwise leading
--@return result pandoc Inlines
function Statement:trim_dot_space(inlines, direction)
	local reverse = false
	if direction == 'reverse' then reverse = true end
	
	-- function to return first position in the desired direction
	function firstpos(list)
		return reverse and #list or 1
	end

	-- safety check
	if not inlines or #inlines == 0 then return inlines end

	-- remove sequences of spaces and dots
	local keep_looking = true
	while keep_looking do
		keep_looking = false
		if #inlines > 0 then
			if inlines[firstpos(inlines)].t == 'Space' then
				inlines:remove(firstpos(inlines))
				keep_looking = true
			elseif inlines[firstpos(inlines)].t == 'Str' then
				-- trim trailing dots and spaces from string text
				local str = inlines[firstpos(inlines)].text:match('(.*)[%.%s]+$')
				if str then
					if str == '' then
						inlines:remove(firstpos(inlines))
					else
						inlines[firstpos(inlines)].text = str
					end
					keep_looking = true
				end
			end
		end
	end

	return inlines
end

--- Statement:new_kind_from_label: create and set a new kind from a 
-- statement's custom label. 
-- Uses:
--		setup:set_style to create a style based on another
--		self.kind the statement's kind
--		self.custom_label the statement's custom label
-- Updates:
--		self.setup.kinds
--		self.setup.styles
--
--@return nil
function Statement:new_kind_from_label()
	local setup = self.setup -- pointing to the setup
	local styles = self.setup.styles -- pointer to the styles table
	local kinds = self.setup.kinds -- pointer to the kinds table	
	local kind = kind or self.kind -- key of the original statement style
	local style = kinds[kind].style
	local custom_label = self.custom_label
	local new_kind, new_style -- keys of the new statement kind 
														-- and (if needed) the new style

	-- create_key_from_label: turn inlines into a key that
	-- can safely be used as LaTeX envt name and html class.
	-- we go through utf8 chars and only keep ASCII alphanum ones
	-- we add 'statement_' in case the label matches a LaTeX command
	local function create_key_from_label(inlines)
		local result = 'sta_'
		for _,code in utf8.codes(stringify(inlines)) do
			if (code >= 48 and code <= 57) -- digits 
					or (code >= 65 and code <= 90) -- A-Z 
					or (code >= 97 and code <= 122) then
				result = result..utf8.char(code):lower()
			else
				result = result..'_'
			end
		end
		return result
	end

	-- Main function body

	if not custom_label then
		return
	end

	-- create a new kind key from label
	local label_str = create_key_from_label(custom_label)
	-- ensure it's a new key
	local n = 0
	new_kind = label_str
	while kinds[new_kind] do
		n = n + 1
		new_kind = label_str..'-'..tostring(n)
	end

	-- do we need a new style too?
	-- the style's custom_label_changes field holds
	-- changes needed when a custom label is used.
	-- we create a <style>_custom if not already done.
	if styles[style].custom_label_changes then

		if not styles[style..'_custom'] then

			-- create a modified map of the style
			local custom_style_map = {}
			for k,v in pairs(styles[style].custom_label_changes) do
				custom_style_map[k] = v
			end
			for k,v in pairs(styles[style]) do
				if not custom_style_map[k] then
					custom_style_map[k] = v
				end
			end
			setup:set_style(style..'_custom', custom_style_map)

		end

		style = style..'_custom'

	end

	-- set the new kind
	setup:set_kind(new_kind, {
			prefix = kinds[kind].prefix,
			style = style,
			label = custom_label,
			counter = 'none'
	})

	-- set this statement's kind to the new kind
	self.kind = new_kind

end

---Statement:new_kind_unnumbered create a new unnumbered kind
-- if needed, based on a statement's kind
-- Uses and updates:
--		self.kind, this statement's current kind
--		self.setup.kinds the kinds table
--		self.setup.styles the styles table
function Statement:new_kind_unnumbered()
	local kinds = self.setup.kinds -- pointer to the kinds table
	local styles = self.setup.styles -- pointer to the styles table	
	local kind = self.kind
	local kind_key, style_key

	-- do nothing if this statement's kind is already unumbered
	if kinds[kind] and kinds[kind].counter
			and kinds[kind].counter == 'none' then
		return
	end

	-- if there's already a `-unnumbered` variant for this kind
	-- switch the kind to this
	kind_key = kind..'-unnumbered'
	if kinds[kind_key] and kinds[kind_key].counter
			and kinds[kind_key].counter == 'none' then
		self.kind = kind_key
		return
	end

	-- otherwise create a new unnumbered variant
	kind_key = kind..'-unnumbered'
	style_key = kinds[kind].style -- use the original style

	-- ensure the kind key is new
	local n = 0
	while kinds[kind_key] do
		n = n + 1
		kind_key = kind..'-unnumbered-'..tostring(n)
	end

	-- create the new kind
	-- keep the original prefix and label; set its counter to 'none'
	self.setup.kinds[kind_key] = {}
	self.setup.kinds[kind_key].prefix = kinds[kind].prefix
	self.setup.kinds[kind_key].style = style_key
	self.setup.kinds[kind_key].label = kinds[kind].label -- Inlines
	self.setup.kinds[kind_key].counter = 'none'

	-- set this statement's kind to the new kind
	self.kind = kind_key

end

---Statement:set_fields: set a statement's fields based on parsed values
-- This function is called after parsing a Div or DefinitionList
-- Uses:
--		self.kind
-- 		self.identifier
--		self.custom_label
--		self.acronym
--		self.info
--		self.content
-- Updates and sets:
--		self.kind   (may create a new kind from custom label)
--		self.identifier 	(assigns automatic IDs)
--		self.is_numbered  (whether the statement is numbered)
--		self.kinds[self.kind].count the statement's count
-- 		self.label
--		self.custom_label
--		self.crossref_label
--@param elem pandoc Div element (optional) element to be parsed
--											defaults to self.element
--@return bool true if successful, false if not
function Statement:set_values()

	-- if custom label, create a new kind
	if self.custom_label then
		self:new_kind_from_label()
	end

	-- if unnumbered, we may need to create a new kind
	-- if numbered, increase the statement's count
	self:set_is_numbered() -- set self.is_numbered
	if not self.is_numbered then
		self:new_kind_unnumbered()
	else
		self:set_count() -- update the kind's counter
	end

	-- set label and crossref labels
	self:set_labels()

	-- set identifier
	self:set_identifier()

end

--- Statement:set_identifier: set a statement's id
-- and register it with the crossref manager.
-- Updates:
--		self.identifier
--		self.elem.attr.identifier
--@return nil
function Statement:set_identifier()
	local elem = self.element
	local crossref = self.setup.crossref -- points to the crossref manager
	local style = self.setup.kinds[self.kind].style
	local crossref_font = self.setup.styles[style].crossref_font

	---register: register id using a given mode
	-- store its kind, crossref_label, crossref_font
	-- store the new id in self.identifier and elem.attr.identifier 
	--@param id string the identifier to be registered
	--@param attr map, any attributes that were set by parsing the id
	--@param mode string mode to be used, 'new', 'redirect', 'strict'
	--@return id, the id generated
	function register(id, attr, mode)
		attr = attr or {}
		local final_id

		-- add attributes
		attr.type = 'Statement'
		attr.label = self.crossref_label
		attr.kind = self.kind
		attr.crossref_font = crossref_font

		-- register
		final_id = crossref:register_identifier(id, attr, mode)

		-- udpate the statement's `self.identifier` field
		self.identifier = final_id
		-- update the element's identifier 
		-- (in case writers return it to the document)
		if elem.attr then
			elem.attr.identifier = final_id
		end

		return final_id
	end

	-- MAIN FUNCTION BODY
	
	--		user-specified id?
	if self.identifier then
		local id, attr = crossref:parse_identifier(self.identifier)
		local final_id = register(id, attr, 'redirect')
		if final_id ~= id then
			message('WARNING', 	'The ID `'..id..'` you gave to a `'..self.kind..'` statement'
													..' turns out to be a duplicate. Either you used it twice,'
													..' or it matches an automatically-generated section ID,'
													..' or you tried to refer to the statement with '
													..' an empty Span `[]{#'..id..'}` rather than a Link' 
													..' `[](#'..id..') somewhere.'
													.." I've changed the ID to `"..final_id..' and made '
													..' all crossreferences to `'..id..'` point to it'
													..' instead. Some crossreferences may not be correct,'
													..' you should give this statement another ID.')
	end

	-- 		acronym?
	elseif self.acronym then
		local id = stringify(self.acronym):gsub('[^%w]','-')
		local final_id = register(id, {}, 'new')
		if final_id ~= id then
			message('WARNING', 'The acronym `'..id..'` you gave to a `'..self.kind..'` statement'
													..' could not be used as its ID because that ID already existed.'
													.." If you're not planning to crossrefer to this statement, "
													.." that's not a problem. But if you are the crossreferences "
													.." won't work as intended."
													.." Make sure you didn't try to refer to this statement with "
													..' an empty Span `[]{#'..id..'}` rather than a Link' 
													..' `[](#'..id..') somewhere, and otherwise give it a custom ID.'
													.." In the meanwhile I've given it ID "..final_id.." instead."
				)
		end

	--	custom label?
	elseif self.custom_label then
		local id = stringify(self.custom_label):lower():gsub('[^%w]','-')
		local final_id = register(id, {}, 'new')
		if final_id ~= id then
			message('WARNING', 'The custom label `'..id..'` you gave to a `'..self.kind..'` statement'
													..' could not be used as its ID because that ID already existed.'
													.." If you're not planning to crossrefer to this statement, "
													.." that's not a problem. But if you are the crossreferences "
													.." won't work as intended."
													.." Make sure you didn't try to refer to this statement with "
													..' an empty Span `[]{#'..id..'}` rather than a Link' 
													..' `[](#'..id..') somewhere, and otherwise give it a custom ID.'
													.." In the meanwhile I've given it ID "..final_id.." instead."
				)
		end

	end

end

--- Statement:set_is_numbered: determine whether a statement is numbered
-- Checks if the element has a 'unnumbered' attribute or 'none' counter.
-- Updates:
--	self.is_numbered Bool whether the statement is numbered
--@param elem the statement element Div or item in Definition list
--@return nil
function Statement:set_is_numbered(elem)
	kinds = self.setup.kinds -- pointer to the kinds table
	elem = elem or self.element

	-- is_counter: whether a counter is a level, LaTeX level or 'self'
	local function is_counter(counter) 
		return counter == 'self'
					or (type(counter) == 'number' and counter >= 1 and counter <= 6)
					or self.setup:get_level_by_LaTeX_name(counter)
		end

	-- custom label theorems aren't numbered
	if self.custom_label then

			self.is_numbered = false

	elseif elem.t == 'Div' and elem.classes:includes('unnumbered') then

			self.is_numbered = false

	elseif kinds[self.kind] and kinds[self.kind].counter then
		-- check if this is a counting counter
		local counter = kinds[self.kind].counter
		-- if shared counter, switch to that counter
		if kinds[counter] then
			counter = kinds[counter].counter
		end
		-- check this is a counting counter
		if is_counter(counter) then
			self.is_numbered = true
		else
			self.is_numbered = false
		end

	else -- 'none' or something unintelligible

		self.is_numbered = false
		
	end
end


--- Statement:set_labels: Set a statement's label and 
-- crossref label. The label is used in the statement
-- heading, the crossref label in references. 
-- Ex: label "Theorem 1.1", crossref_label "1.1"
-- Updates:
--		self.label
--		self.crossref_label
-- Crossref label priority:
--		- use self.crossref_label, if user set
-- 		- use self.acronym, otherwise
--		- use self.label (custom label), otherwise
--		- use formatted statement count
--		- '??'
--@return nil
function Statement:set_labels()
	local kinds = self.setup.kinds -- pointer to the kinds table
	local kind = self.kind -- the statement's kind
	local delimiter = self.setup.options.counter_delimiter
										or '.' -- separates section counter and statement counter
	local counters = self.setup.counters -- pointer to the counters table
	local number -- string formatted number, if numbered statement

	-- If numbered, create the `number` string
	if self.is_numbered then
		-- counter; if shared, use the source's counter
		local counter = kinds[kind].counter
		local kind_to_count = kind
		if kinds[counter] then
			kind_to_count = counter
			counter = kinds[counter].counter
		end
		-- format depending on counter == `self`, <level> or 'none'/unintelligible
		local level = self.setup:get_level_by_LaTeX_name(counter)
		local count = kinds[kind_to_count].count or 0
		if level then
			number = self.setup:write_counter(level)..delimiter..count
		elseif counter == 'self' then
			number = tostring(count)
		else
			number = '??'
		end
	end

	-- Label
	if self.custom_label then
		self.label = self.custom_label
	elseif kinds[kind].label then
		self.label = kinds[kind].label:clone()
		if number then
			self.label:extend({pandoc.Space(), pandoc.Str(number)})
		end
	end

	-- Crossref Label
	-- (future use) use self.crossref_label if set (open this to Div attributes?)
	if self.crossref_label then
	-- or use acronym
	elseif self.acronym then
		self.crossref_label = self.acronym
	-- or custom label
	elseif self.custom_label then
		self.crossref_label = self.custom_label
	-- or formatted statement count
	elseif number then
		self.crossref_label = pandoc.Inlines(pandoc.Str(number))
	-- or set it to '??'
	else
		self.crossref_label = pandoc.Inlines(pandoc.Str('??'))
	end

end

---Statement:set_count: increment a statement kind's counter
-- Increments the kind's count of this statement kind or
-- its shared counter's kind.
-- Note: set_is_numbered ensures that the kind's counter
-- is a counting one.
--@return nil
function Statement:set_count()
	local kinds = self.setup.kinds -- pointer to the kinds table
	local counter = kinds[self.kind].counter
	-- kind to count: shared counter's kind or self.kind
	local kind_to_count = kinds[counter] and counter
												or self.kind

	kinds[kind_to_count].count =	kinds[kind_to_count].count
																and kinds[kind_to_count].count + 1
																or 1
end

--- Statement:write: format the statement as an output string.
-- @param format string (optional) format desired if other than FORMAT
-- @return Blocks blocks to be inserted. 
function Statement:write(format)
	local format = format or FORMAT
	local blocks = pandoc.List:new()

	-- do we have before_first includes to include before any
	-- definition? if yes include them here and wipe it out
	if self.setup.includes.before_first then
		blocks:extend(self.setup.includes.before_first)
		self.setup.includes.before_first = nil
	end

	-- do we need to write the kind definition first?
	-- if local blocks are returned, insert them
	local write_kind_local_blocks = self:write_kind()
	if write_kind_local_blocks then
		blocks:extend(write_kind_local_blocks)
	end

	-- format the statement

	if format:match('latex') then

		blocks:extend(self:write_latex())

	elseif format:match('html') then

		blocks:extend(self:write_html())

	elseif format:match('jats') then

		blocks:extend(self:write_jats())

	else

		blocks:extend(self:write_native())

	end
	
	return blocks

end

--- Statement:write_kind: write the statement's style definition as output string.
-- If the statement's style is not yet defined, create blocks to define it
-- in the desired output format. These blocks are added to
-- `self.setup.includes.before_first` or returned to be added locally, 
-- depending on the `setup.options.define_in_header` setting.
-- @param kind string (optional) kind to be formatted, if not self.kind
-- @param format string (optional) format desired if other than FORMAT
-- @return blocks or {}, blocks to be added locally if any
function Statement:write_style(style, format)
	local format = format or FORMAT
	local length_format = Helpers.length_format
	local font_format = Helpers.font_format
	local styles = self.setup.styles -- points to the styles table
	local style = style or self.setup.kinds[self.kind].style
	local blocks = pandoc.List:new() -- blocks to be written

	-- check if the style is already written or not to be defined
	if styles[style].is_written 
			or styles[style]['do_not_define_in_'..format] then
		return {}
	else
		styles[style].is_written = true
	end

	-- format
	if format:match('latex') then

		-- special case: proof environement
		-- with amsthm this is already defined, we only set \proofname
		-- without we must provide the environement and \proofname
		if style == 'proof' then
			local LaTeX_command = ''
			if not self.setup.options.amsthm then
				 LaTeX_command = LaTeX_command ..
[[\makeatletter
\ifx\proof\undefined
\newenvironment{proof}[1][\protect\proofname]{\par
	\normalfont\topsep6\p@\@plus6\p@\relax
	\trivlist
	\itemindent\parindent
	\item[\hskip\labelsep\itshape #1.]\ignorespaces
}{%
	\endtrivlist\@endpefalse
}
\fi
\makeatother
]]
			end
			if self.setup.LOCALE[self.setup.options.language]['proof'] then
				LaTeX_command = LaTeX_command 
							.. '\\providecommand{\\proofname}{'
							.. self.setup.LOCALE[self.setup.options.language]['proof']
							.. '}'
			else
				LaTeX_command = LaTeX_command 
							.. '\\providecommand{\\proofname}{Proof}'
			end
			blocks:insert(pandoc.RawBlock('latex', LaTeX_command))

		-- \\theoremstyle requires amsthm
		-- normal style, use \\theoremstyle if amsthm
		elseif self.setup.options.amsthm then

			-- LaTeX command
			-- \\\newtheoremstyle{stylename}
			-- 		{length} space above
			-- 		{length} space below
			-- 		{command} body font
			-- 		{length} indent amount
			-- 		{command} theorem head font
			--		{string} punctuation after theorem head
			--		{length} space after theorem head
			--		{pattern} theorem heading pattern
			local style_def = styles[style]
			local space_above = length_format(style_def.margin_top) or '0pt'
			local space_below = length_format(style_def.margin_bottom) or '0pt'
			local margin_right = length_format(style_def.margin_right)
			local margin_left = length_format(style_def.margin_left)
			local body_font = font_format(style_def.body_font) or ''
			if margin_right then
				body_font = '\\addtolength{\\rightskip}{'..style_def.margin_left..'}'
										..body_font
			end
			if margin_left then
				body_font = '\\addtolength{\\leftskip}{'..style_def.margin_left..'}'
										..body_font
			end
			local indent = length_format(style_def.indent) or ''
			local head_font = font_format(style_def.head_font) or ''
			local punctuation = style_def.punctuation or ''
			-- NB, space_after_head can't be '' or LaTeX crashes. use ' ' or '0pt'
			local space_after_head = style_def.linebreak_after_head and '\\newline'
															or length_format(style_def.space_after_head) 
															or ' '
			local heading_pattern = style_def.heading_pattern or ''
			local LaTeX_command = '\\newtheoremstyle{'..style..'}'
										..'{'..space_above..'}'
										..'{'..space_below..'}'
										..'{'..body_font..'}'
										..'{'..indent..'}'
										..'{'..head_font..'}'
										..'{'..punctuation..'}'
										..'{'..space_after_head..'}'
										..'{'..heading_pattern..'}\n'
			blocks:insert(pandoc.RawBlock('latex',LaTeX_command))

		end
	
	elseif format:match('html') then

		-- CSS specification 
		-- @TODO: handle linebreak_after_head
		-- .statement.<style> {
		--			margin-top:
		--			margin-bottom:
		--			margin-left:
		--			margin-right:
		--			[font-style,-weight,-variant]: body font
		--			}	
		-- .statement.<style> .statement-label {
		--			[font-style,-weight,-variant]: head font
		-- 		}
		-- .statement.<style> .statement-info {
		--			[font-style,-weight,-variant]: normal
		--	}
		--@TODO: handle indent, 'text-ident' on the first paragraph only, before heading
		--@TODO: handle space after theorem head. Need to use space chars???
		local style_def = styles[style]
		local margin_top = length_format(style_def.margin_top)
		local margin_bottom = length_format(style_def.margin_bottom)
		local margin_right = length_format(style_def.margin_right)
		local margin_left = length_format(style_def.margin_left)
		local body_font = font_format(style_def.body_font)
		local head_font = font_format(style_def.head_font)
		-- make sure head and info aren't affected by body_font
		if body_font then
			head_font = head_font or ''
			head_font = 'font-style: normal; font-weight: normal;'
									..' font-variant: normal; '..head_font
		end
		local indent = length_format(style_def.indent) or ''
		-- local punctuation = style_def.punctuation HANDLED BY WRITE
		local linebreak_after_head, space_after_head
		if style_def.linebreak_after_head then
			linebreak_after_head = true
		else
			space_after_head = length_format(style_def.space_after_head) 
														or '0.333em'
		end
		--local heading_pattern = style_def.heading_pattern or ''

		local css_spec = ''

		if margin_top or margin_bottom or margin_left or margin_right
				or body_font then
			css_spec = css_spec..'.statement.'..style..' {\n'
			if margin_top then
				css_spec = css_spec..'\tmargin-top: '..margin_top..';\n'
			end
			if margin_bottom then
				css_spec = css_spec..'\tmargin-bottom: '..margin_bottom..';\n'
			end
			if margin_left then
				css_spec = css_spec..'\tmargin-left: '..margin_left..';\n'
			end
			if margin_right then
				css_spec = css_spec..'\tmargin-right: '..margin_right..';\n'
			end
			if body_font then
				css_spec = css_spec..'\t'..body_font..'\n'
			end
			css_spec = css_spec..'}\n'
		end
		if head_font then
			css_spec = css_spec..'.statement.'..style..' .statement-label {\n'
			css_spec = css_spec..'\t'..head_font..'\n'
			css_spec = css_spec..'}\n'
		end
		if indent ~= '' then
			css_spec = css_spec..'.statement.'..style..' p:first-child {\n'
			css_spec = css_spec..'\t text-indent: '..indent..';\n'
			css_spec = css_spec..'}\n'
		end
		-- linebreak after heading or space after heading
		-- linebreak after heading: use '\a' and white-space: pre
		-- space after heading: use word-spacing
		if linebreak_after_head then
			css_spec = css_spec..'.statement.'..style..' .statement-spah:after {\n'
			css_spec = css_spec.."\tcontent: '\\a';\n"
			css_spec = css_spec..'\twhite-space: pre;\n'
			css_spec = css_spec..'}\n'
		elseif space_after_head then
			css_spec = css_spec..'.statement.'..style..' .statement-spah {\n'
			css_spec = css_spec..'\tword-spacing: '..space_after_head..';\n'
			css_spec = css_spec..'}\n'
		end

		-- info style: always clean (as in AMS theorems)
		css_spec = css_spec..'.statement.'..style..' .statement-info {\n'
		css_spec = css_spec..'\t'..'font-style: normal; font-weight: normal;'
									..' font-variant: normal;\n'
		css_spec = css_spec..'}\n'




		-- wrap all in <style> tags
		css_spec = '<style>\n'..css_spec..'</style>\n'

		-- insert
		blocks:insert(pandoc.RawBlock('html',css_spec))

	else -- any other format, no way to define statement kinds

	end

	-- place the blocks in header_includes or return them
	if #blocks == 0 then
		return {}
	elseif self.setup.options.define_in_header then
		if not self.setup.includes.header then
			self.setup.includes.header = pandoc.List:new()
		end
		self.setup.includes.header:extend(blocks)
		return {}
	else
		return blocks
	end

end

--- Statement:write_kind: write the statement's kind definition as output string.
-- If the statement's kind is not yet defined, create blocks to define it
-- in the desired output format. These blocks are added to
-- `self.setup.includes.header` or returned to be added locally, 
-- depending on the `setup.options.define_in_header` setting.
-- @param kind string (optional) kind to be formatted, if not kind
-- @param format string (optional) format desired if other than FORMAT
-- @return blocks or {}, blocks to be added locally if any
function Statement:write_kind(kind, format)
	local format = format or FORMAT
	local kind = kind or self.kind
	local counter = self.setup.kinds[kind].counter or 'none'
	local shared_counter, counter_within
	local blocks = pandoc.List:new() -- blocks to be written

	-- check if the kind is already written
	if self.setup.kinds[kind].is_written then
		return {}
	else
		self.setup.kinds[kind].is_written = true
	end

	-- identify counter_within and shared_counter
	if counter ~= 'none' and counter ~= 'self' then
		if self.setup.kinds[counter] then
			shared_counter = counter
		elseif self.setup:get_level_by_LaTeX_name(counter) then
			counter_within = counter
		elseif self.setup:get_LaTeX_name_by_level(counter) then
			counter_within = self.setup:get_LaTeX_name_by_level(counter)
		else -- unintelligible, default to 'self'
			message('WARNING', 'unintelligible counter for kind'
				..kind.. '. Defaulting to `self`.')
			counter = 'self'
		end
	end
	-- if shared counter, ensure its kind is defined before
	if shared_counter then
		blocks:extend(self:write_kind(shared_counter))
	end

	-- write the style definition if needed
	blocks:extend(self:write_style(self.setup.kinds[kind].style))

	-- format
	if format:match('latex') then
	
		local label = self.setup.kinds[kind].label 
						or pandoc.Inlines(pandoc.Str(''))

		-- in LaTeX we need to add the acronym in the label's definition
		if self.acronym then

			local acro_inlines = pandoc.List:new()
			acro_inlines:insert(pandoc.Str('('))
			acro_inlines:extend(self.acronym)
			acro_inlines:insert(pandoc.Str(')'))
			acro_inlines:insert(1, pandoc.Space())
			label = label:__concat(acro_inlines)

		end

		-- 'proof' statements are not defined
		if kind == 'proof' then
			-- nothing to be done

		else

			-- amsthm provides `newtheorem*` for unnumbered kinds
			local latex_cmd = self.setup.options.amsthm and counter == 'none' 
				and '\\newtheorem*' or '\\newtheorem'

			-- LaTeX command:
			-- \theoremstyle{style} (amsthm only)
			-- \newtheorem{kind}{label}
			-- \newtheorem{kind}[shared_counter]{label}
			-- \newtheorem{kind}{label}[counter_within]

			local inlines = pandoc.List:new()
			if self.setup.options.amsthm then
				inlines:insert(
					pandoc.RawInline('latex','\\theoremstyle{'
							.. self.setup.kinds[kind].style .. '}\n')
					)
			end
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

		end

	elseif format:match('html') then

	else -- any other format, no way to define statement kinds

	end

	-- place the blocks in header_includes or return them
	if self.setup.options.define_in_header then
		if not self.setup.includes.header then
			self.setup.includes.header = pandoc.List:new()
		end
		self.setup.includes.header:extend(blocks)
		return {}
	else
		return blocks
	end

end

--- Statement:write_label write the statement's full label
-- If numbered, use the kind label and statement numbering.
-- If custom label and acronym, use them. Otherwise no label.
-- Uses
--	self.is_numbered to tell whether the statement is numbered
--	self.setup.options.swap_numbers to swap numbers
-- 	self.custom_label, if any
-- 	self.crossref_label if numbered, this contains the numbering
-- 	self.setup.kinds[self.kind].label the kind's label, if any
--@return inlines statement label inlines
function Statement:write_label()
	kinds = self.setup.kinds -- pointer to the kinds table
	bb, eb = '(', ')' 
	inlines = pandoc.List:new()
	
	if self.custom_label then

		inlines:extend(self.custom_label)
		if self.acronym then
			inlines:insert(pandoc.Space())
			inlines:insert(pandoc.Str(bb))
			inlines:extend(self.acronym)			
			inlines:insert(pandoc.Str(eb))
		end

	else

		-- add kind label
		if kinds[self.kind] and kinds[self.kind].label then
			inlines:extend(kinds[self.kind].label)
		end

		-- if numbered, add number from self.crossref_label
		-- before or after depending on `swamp_numbers`
		if self.is_numbered and self.crossref_label then

			if self.setup.options.swap_numbers then
				if #inlines > 0 then
					inlines:insert(1, pandoc.Space())
				end
				inlines = self.crossref_label:__concat(inlines) 
			else
				if #inlines > 0 then
					inlines:insert(pandoc.Space())
				end
				inlines:extend(self.crossref_label)
			end

		end

	end

	return inlines

end

---Statement.write_latex: write a statement in LaTeX
-- \begin{kind}[info inlines] 
--		[Link(identifier)] content blocks
--	\end{kind}
--@return Blocks
function Statement:write_latex()
	local blocks = pandoc.List:new()
	local id_span -- a Span element to give the statement an identifier
	local style_def = self.setup.styles[self.setup.kinds[self.kind].style]

	-- we start with Plain block `\begin{...}[info]\hypertarget'
	local inlines = pandoc.List:new()
	inlines:insert(pandoc.RawInline('latex', 
						'\\begin{' .. self.kind .. '}'))
	-- if info, insert in brackets
	if self.info then
		inlines:insert(pandoc.RawInline('latex', '['))
		inlines:extend(self.info)
		inlines:insert(pandoc.RawInline('latex', ']'))
	end
	-- if the element has an identifier, insert an empty identifier Span 
	if self.identifier then
		inlines:insert(pandoc.Span({},pandoc.Attr(self.identifier)))
	end
	-- if the blocks start with a list and has a label, 
	-- amsthm needs to be told to start a newline
	-- if the style has a linebreak already, needs a negative baselineskip too
	if self.content[1] and self.content[1].t
		  and (self.label or self.custom_label)
			and (self.content[1].t == 'BulletList' or self.content[1].t == 'OrderedList'
				or self.content[1].t == 'DefinitionList') then
		inlines:insert(pandoc.RawInline('latex', '\\leavevmode'))
		if style_def.linebreak_after_head then
			inlines:insert(pandoc.RawInline('latex', '\\vspace{-\\baselineskip}'))
		end
	end
	-- insert \begin{...}[...] etc. as Plain block
	blocks:insert(pandoc.Plain(inlines))

	-- main content
	blocks:extend(self.content)

	-- close
	blocks:insert(pandoc.RawBlock('latex',
						'\\end{' .. self.kind .. '}'))

	return blocks

end


---Statement.write_latex: write a statement in html
--@return Blocks
-- HTML formatting
-- we create a Div
--	<div class='statement <kind> <style>'>
-- 	<p class='statement-first-paragraph'>
--		<span class='statement-head'>
--			<span class='statement-label'> label inlines </span>
--		  <span class='statement-info'>( info inlines )</span>
--			<span class='statement-spah'> </span>
--		first paragraph content, if any
--	</p>
--  content blocks
-- </div>
function Statement:write_html()
	local styles = self.setup.styles -- pointer to the styles table
	local style = self.setup.kinds[self.kind].style -- this statement's style
	local label_inlines, label_span, info_span 
	local heading_inlines, heading_span
	local attributes
	local blocks = pandoc.List:new()

	-- create label span; could be custom-label or kind label
	label_inlines = self:write_label() 
	if #label_inlines > 0 then
		label_span = pandoc.Span(label_inlines, 
											{class = 'statement-label'})
	end
	-- create info span
	if self.info then 
		self.info:insert(1, pandoc.Str('('))
		self.info:insert(pandoc.Str(')'))
		info_span = pandoc.Span(self.info, 
										{class = 'statement-info'})
	end
	-- put heading together
	if label_span or info_span then
		heading_inlines = pandoc.List:new()
		if label_span then
			heading_inlines:insert(label_span)
		end
		if label_span and info_span then
			heading_inlines:insert(pandoc.Space())
		end
		if info_span then
			heading_inlines:insert(info_span)
		end
		-- insert punctuation defined in style
		if styles[style].punctuation then
			heading_inlines:insert(pandoc.Str(
				styles[style].punctuation
				))
		end
		heading_span = pandoc.Span(heading_inlines,
									{class = 'statement-heading'})
	end

	-- if heading, insert it in the first paragraph if any
	-- otherwise make it its own paragraph
	if heading_span then
		if self.content[1] and self.content[1].t 
				and self.content[1].t == 'Para' then
			self.content[1].content:insert(1, heading_span)
			-- add space after heading
			self.content[1].content:insert(2, pandoc.Span(
										{pandoc.Space()}, {class='statement-spah'}
				))
		else
			self.content:insert(1, pandoc.Para({heading_span}))
		end
	end

	-- prepare Div attributes
	-- keep the original element's attributes if any
	attributes = self.element.attr or pandoc.Attr()
	if self.identifier then
			attributes.identifier = self.identifier
	end
	-- add the `statement`, kind, style and unnumbered classes
	-- same name for kind and style shouldn't be a problem
	attributes.classes:insert('statement')
	attributes.classes:insert(self.kind)
	attributes.classes:insert(style)
	if not self.is_numbered 
			and not attributes.classes:includes('unnumbered') then
		attributes.classes:insert('unnumbered')
	end

	-- create the statement Div and insert it
	blocks:insert(pandoc.Div(self.content, attributes))

	return blocks

end

---Statement.write_latex: write a statement in LaTeX
-- Pandoc's JATS writer turns Plain blocks in to <p>...</p>
-- for this reason we must write <label> and <title> inlines
-- to text before we insert them.
-- <statement>
--		<label> Kind label number or Custom label </label>
--		<title> info </title>
--		content blocks
-- </statement
--@return Blocks
function Statement:write_jats()
	doc_meta = self.setup.meta -- pointer to the doc's Meta
														 -- needed by pandoc.write
	local blocks = pandoc.List:new()

	--write_to_jats: use pandoc to convert inlines to jats output
	--passing writer options that affect inlines formatting in JATS
	--@BUG even with the doc's meta, citeproc doesn't convert citations
	function write_to_jats(inlines)
		local result, doc
		local options = pandoc.WriterOptions({
				cite_method = PANDOC_WRITER_OPTIONS.cite_method,
				columns = PANDOC_WRITER_OPTIONS.columns,
				email_obfuscation = PANDOC_WRITER_OPTIONS.email_obfuscation,
				extensions = PANDOC_WRITER_OPTIONS.extensions,
				highlight_style = PANDOC_WRITER_OPTIONS.highlight_style,
				identifier_prefix = PANDOC_WRITER_OPTIONS.identifier_prefix,
				listings = PANDOC_WRITER_OPTIONS.listings,
				prefer_ascii = PANDOC_WRITER_OPTIONS.prefer_ascii,
				reference_doc = PANDOC_WRITER_OPTIONS.reference_doc,
				reference_links = PANDOC_WRITER_OPTIONS.reference_links,
				reference_location = PANDOC_WRITER_OPTIONS.reference_location,
				tab_stop = PANDOC_WRITER_OPTIONS.tab_stop,
				wrap_text = PANDOC_WRITER_OPTIONS.wrap_text,
		})
		doc = pandoc.Pandoc(pandoc.Plain(inlines), doc_meta)
		result = pandoc.write(doc, 'jats', options)
		return result:match('^<p>(.*)</p>$') or result or ''

	end

	blocks:insert(pandoc.RawBlock('jats', '<statement>'))

	label_inlines = self:write_label() 
	if #label_inlines > 0 then
		local label_str = '<label>'..write_to_jats(label_inlines) 
											..'</label>'
		blocks:insert(pandoc.RawBlock('jats',label_str))
	end

	if self.info then
		local info_str = 	'<title>'..write_to_jats(self.info)
											..'</title>'
		blocks:insert(pandoc.RawBlock('jats',info_str))
	end

	blocks:extend(self.content)

	blocks:insert(pandoc.RawBlock('jats', '</statement>'))

	return blocks

end


---Statement.write_latex: write a statement in Pandoc native
-- We wrap the statement in a Div
--@return Blocks
function Statement:write_native()
	local font_format_native = Helpers.font_format_native
	-- pick the style definition for punctuation, linebreak after head...
	local style_def = self.setup.styles[self.setup.kinds[self.kind].style]
	-- convert font definitions into formatting functions
	local label_format = font_format_native(style_def.head_font)
	local body_format = font_format_native(style_def.body_font)
	local label, heading

	-- create label span; could be custom-label or kind label
	label = self:write_label() 
	if #label > 0 then
		label_span = pandoc.Span(label, 
											{class = 'statement-label'})
	end

	-- prepare the statement heading inlines
	local heading = pandoc.List:new()
	-- label?
	label = self:write_label()
	if #label > 0 then
		label = label_format(label)
		label = pandoc.Span(label, {class = 'statement-label'})
		heading:insert(label)
	end

	-- info?
	if self.info then
		if #heading > 0 then
			heading:insert(pandoc.Space())
		end
		heading:insert(pandoc.Str('('))
		heading:extend(self.info)
		heading:insert(pandoc.Str(')'))
	end

	-- punctuation
		if #heading > 0 and style_def.punctuation then
			heading:insert(pandoc.Str(style_def.punctuation))
		end

	-- style body
	-- must be done before we insert the heading to ensure
	-- that body_format isn't applied to the heading.
--	print(pandoc.write(pandoc.Pandoc(self.content)))
	self.content = body_format(self.content)
--	print(pandoc.write(pandoc.Pandoc(self.content)))

	-- insert heading
	-- combine statement heading with the first paragraph if any
	-- take care of linebreak after head
	if #heading > 0 then
		if self.content[1] and self.content[1].t == 'Para' then
			if style_def.linebreak_after_head then
				heading:insert(pandoc.LineBreak())
			else
				heading:insert(pandoc.Space())
			end
			heading:extend(self.content[1].content)
			self.content[1] = pandoc.Para(heading)
		else
			self.content:insert(1, pandoc.Para(heading))
		end
	end

	-- if the element has an identifier, insert an empty identifier Span 
	if self.identifier then
		id_span = pandoc.Span({},pandoc.Attr(self.identifier))
		if self.content[1] 
				and (self.content[1].t == 'Para' 
						or self.content[1].t == 'Plain') then
			self.content[1].content:insert(1, id_span)
		else
			self.content:insert(pandoc.Plain(id_span))
		end
	end

	-- place all the content blocks in Div
	return pandoc.Blocks(pandoc.Div(self.content))

end

--- create a statement object from a pandoc element.
-- @param elem pandoc Div or DefinitionList
-- @param setup Setup class object, the document's statements setup
-- @return statement object or nil if elem isn't a statement
function Statement:new(elem, setup)

	-- create an object of Statement class
	local o = {}
	self.__index = self 
	setmetatable(o, self)

	o.setup = setup -- points to the setup, needed by the class's methods
	o.element = elem -- points to the original element

	if o.element.t then

		if o.element.t == 'Div' and o:Div_is_statement() then
			o:parse_Div()
			o:set_values()
			return o

		elseif o.element.t == 'DefinitionList' 
						and o.element.content[1]
						and o:DefListitem_is_statement(o.element.content[1]) then
			o:parse_DefList()
			o:set_values()
			return o

		end
	end

end

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
---Crossref:collect_identifiers: Collect identifiers of 
-- non-statements in the document.
-- Updates:
--		self.identifiers
--@param blocks pandoc Blocks, a list of Block elements
--@return nil
function Crossref:collect_identifiers()
	local setup = self.setup
	local blocks = self.doc.blocks
	local types_with_identifier = { 'CodeBlock', 'Div', 'Header', 
						'Table', 'Code', 'Image', 'Link', 'Span',	}
	local filter = {} -- filter to be applied to blocks

	-- get_filter: generate a filter (elem -> elem) that registers
	-- non-duplicate IDs with type `type`.
	local function get_filter(type) 
		return function(elem)
			if elem.identifier and elem.identifier ~= '' then
				-- parse the identifier
				local id, attr = Crossref:parse_identifier(elem.identifier)
				-- register the type
				attr.type = type
				-- register or warn
				success = self:register_identifier(id, attr, 'strict')
				if not success then 
					message('WARNING', 'Duplicate identifier: '..id..'.')
				end
			end

			end
	end

	-- Div: register only if not a statement
	filter.Div = function (elem)
		if elem.identifier and elem.identifier ~= ''
				and not Statement:Div_is_statement(elem, setup) then
					get_filter('Div')(elem)
			end
	end

	-- Generic function for remaining types
	for _,type in ipairs(types_with_identifier) do
		-- make sure we don't erase a filter already defined
		filter[type] = filter[type] or get_filter(type)
	end

	-- run the filter through blocks
	blocks:walk(filter)

end




---Crossref:parse_identifier: Parse an element's
-- identifier and return a map for the identifiers table.
-- @TODO in the future we'll process any flags included
-- in the identifier like `g:` for global identifiers.
--@param str string the Pandoc element identifier
--@return id string the identifier proper
--@return attr map of identifier attributes or nil 
function Crossref:parse_identifier(str)
	local id = str
	local attr = {}

	--@TODO: extract any flags in str, set attributes

	return id, attr
end




---Crossref:register_identifier: register a new identifier.
-- Different modes are provided
-- 		- 'strict': register only if not already existing
--		- 'redirect': if already present, register under a new
--							id and redirect the original to the new
--		- 'new': register, using a new name if needed
-- The 'redirect' and 'new' modes are always successful.
--@param id string the desired identifier
--@param attr table map of attributes
--@param mode (optional) string, mode (defaults to 'new')
--@return id string the identifier registered or nil
function Crossref:register_identifier(id, attr, mode)
	local identifiers = self.identifiers -- points to the identifiers table
	local id = id or '' -- in non-strict mode, empty id is ok
	local attr = attr or {}
	local mode = mode or 'new'

	-- all identifiers must have a type
	if not attr.type then
		attr.type = 'Unknown'
	end

	if mode == 'strict' and id ~= '' then
		if not identifiers[id] then
			identifiers[id] = attr
			return id
		end
	elseif mode == 'new' or mode == 'redirect' then
		-- ensure we have a new id
		local final_id = id
		local n = 0
		while final_id == '' or identifiers[final_id] do
			n = n + 1
			final_id = id..'-'..tostring(n)
		end
		-- register
		identifiers[final_id] = attr
		-- in redirect mode, redirect old id to new one
		if mode == 'redirect' then
			if identifiers[id] then
				identifiers[id].redirect = final_id
			end
		end
		-- return the final id
		return final_id
	end
end




---Crossref:process: processes crossreferences in
-- a Pandoc Link or Cite, if present.
-- See `Crossref.lua` for the definition `references` lists.
function Crossref:process(elem)
	if elem and elem.t then
		
		local references

		if elem.t == 'Link' then
			references = self:parse_Link(elem)
		elseif elem.t == 'Cite' then
			references = self:parse_Cite(elem)
		end

		if references then
			return self:write(references)
		end
		
	end
end

---Crossref:parse_target: Parse a crossreference
-- target into flags (if any) and identifier.
--@param str string the crossreference target
--@return id string the identifier proper
--@return flags pandoc List of flags, might be empty
function Crossref:parse_target(str)
	local flag_patterns = {'pre', 'Pre', 'pres', 'Pres', 'g'} -- Lua patterns
	local separator = ':' -- could open to customization in the future
	local flags = pandoc.List:new()
	local id

	---extract_flag: extract one flag from the identifier
	--@param: str, string from which the flag is to be extracted
	--@param: flag, string, flag found
	--@param: remainder, string remainder of the string
	local function extract_flag(str)
		local i,j = str:find('^%w+'..separator)
		-- proceed only if non-empty remainder found
		if j and j < #str then
			local flag = str:sub(i,j - #separator)
			local remainder = str:sub(j+1, #str)
			-- return only if it's an official flag
			for _,pattern in ipairs(flag_patterns) do
				if flag:match(pattern) then
					return flag, remainder
				end
			end
		end
	end

	-- Main function body
	while str do
		local flag, remainder = extract_flag(str)
		if flag then
			flags:insert(flag)
			str = remainder
		else
			id = str
			str = nil
		end
	end

	return id, flags

end

---Crossref:parse_Link: tries to parse a Link element  
-- as a crossreference. 
-- See `Crossref.lua` for a definition of reference items.
-- Uses:
--	self.identifiers
--@param: elem, pandoc Link element
--@return: table, list of (one) reference item or nil
function Crossref:parse_Link(link)
	local identifiers = self.identifiers
	local id, flags

	---parse_link_content: parses link content into
	-- prefix and suffix or custom text.
	-- The first <>, if any, says where the automatic text
	-- goes. Non-empty text without <> is a custom text.
	-- Examples:
	-- '' -> prefix = nil, suffix = nil, text = nil
	-- 'this statement' ->  text = 'this statement', prefix,suffix = nil,nil
	-- 'as in <>' -> prefix 'as in ', suffix,text = nil,nil
	-- 'as in (<>)' -> prefix 'as in (', suffix = ')', text = nil
	-- 'see (<>) above' -> prefix 'see (', suffix = ') above', text = nil
	-- Uses:
	--	self.identifires
	--@param: inlines, text of the link
	--@return: table, list of (one) reference item
	local function parse_link_content(inlines)
		local text, prefix, suffix

		if #inlines > 0 then
			text = pandoc.List:new()
			-- by default, insert elements in the custom text
			-- but if we find <>, put what we have in prefix
			-- and the rest in suffix.
			for i = 1, #inlines do
				if inlines[i].t == 'Str'
						and inlines[i].text:match('<>') then
					-- put what we have so far in prefix, 
					-- the rest in suffix
					prefix = text
					text = nil
					suffix = pandoc.List:new()
					for j = i+1, #inlines do
						suffix:insert(inlines[j])
					end
					-- split the string if needed
					s,e = inlines[i].text:find('<>')
					if s > 1 then 
						prefix:insert(pandoc.Str(inlines[i].text:sub(1,s-1)))
					end
					if e < #inlines[i].text then
						suffix:insert(1, pandoc.Str(inlines[i].text:sub(e+1,-1)))
					end
					break

				else

					text:insert(inlines[i])

				end
			end
		end

		return text, prefix, suffix
	end

	-- MAIN FUNCTION BODY

	-- Check whether the link is crossref and set id
	local is_crossref = false
	if link.target:sub(1,1) == '#' then
		id, flags = self:parse_target(link.target:sub(2,-1))
		if identifiers[id] then
			-- redirect if needed
			id = identifiers[id].redirect or id
			-- check whether the target is a statement
			if identifiers[id].type == 'Statement' then
				is_crossref = true
			end
		end
	end

	-- parse a crossreference if found
	if is_crossref then
		local ref = {}
		ref.id = id
		ref.flags = flags
		ref.mode = 'InText'
		ref.text, ref.prefix, ref.suffix =	parse_link_content(link.content)
		ref.title = link.title ~= '' and link.title or nil

		return { ref }
	end
end

---Crossref:parse_Cite: tries to parse a Cite element
-- as a list of crossreferences.
-- Mixes of crossreferences and biblio (or others) aren't allowed.
-- See `Crossref.lua` for a definition of reference items.
-- Uses:
-- 	self.identifiers
--@param: elem, pandoc Cite element
--@return: table, list of reference items, or nil
function Crossref:parse_Cite(cite)
	local identifiers = self.identifiers

	-- Check whether citations include crossref and/or biblio refs
	local has_crossref, has_biblio_ref

  for _,citation in ipairs(cite.citations) do
  	local id, flags = self:parse_target(citation.id)
  	if identifiers[id] then 
  		-- apply redirect if needed
  		id = identifiers[id].redirect or id
  		-- record if we found a crossreference citation or another type
  		if identifiers[id].type == 'Statement' then
          has_crossref = true
      else
          has_biblio_ref = true
      end  		
  	else
  		has_biblio_ref = true
  	end
  end

  -- Return if it has biblio refs, with a warning if there was a mix.
  if has_biblio_ref then
  	if has_crossref then
	    message('WARNING', 'A citation mixes bibliographic references'
	        ..' with custom label references: '..stringify(cite.content))
	  end
    return
	end

	-- Otherwise build the references list
	references = pandoc.List:new()

	for _,citation in ipairs(cite.citations) do
		local ref = {}
  	ref.id, ref.flags = self:parse_target(citation.id)
  	-- apply redirect if needed
  	ref.id = identifiers[ref.id].redirect or ref.id
  	-- mode: `Normal` or `InText`
  	ref.mode = 	citation.mode == 'AuthorInText' and 'InText'
  							or citation.mode == 'NormalCitation' and 'Normal'
  							or nil
  	-- prefix and suffix
  	-- for uniformity with Links, space added
  	if #citation.prefix > 0 then
  		ref.prefix = citation.prefix:clone()
  		ref.prefix:insert(pandoc.Space())
  	end
  	if #citation.suffix > 0 then
  		ref.suffix = citation.suffix:clone()
  		ref.suffix:insert(1, pandoc.Space())
  	end

  	references:insert(ref)

	end

	return references

end

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

---Crossref.aggregate_references: turn successive 
-- numbered references of the same kind into a list.
-- E.g. "Theorem 1;Theorem 1.2" -> "Theorem 1.1, 1.2"
-- "1.1; 1.2; 1.3" -> "1.2--1.3"
-- Whenever we find such a sequence we replace it by
-- the last item with:
--		- the first item's prefix
--		- some additional fields to specify the sequence
--@param references a list of reference items
function Crossref:aggregate_references(references)
	local identifiers = self.identifiers -- points to the identifier table
	local kinds = self.setup.kinds -- points to the kinds table
	local new_references = pandoc.List:new()

	---counters_are_shared: checks whether two items
	-- are counted together.
	local function counters_are_shared(item1,item2)
		local kind1 = identifiers[item1.id].kind
		local kind2 = identifiers[item2.id].kind
		if kind1 == kind2
				or kinds[kind1].counter == kind2
				or kinds[kind2].counter == kind1 then
			return true
		else
			return false
		end
	end

	---labels_are_consecutive: checks that one item's number
	-- precedes another. 
	-- We require the last number to be consecutive, e.g.:
	-- 2.9, 2.10 : ok
	-- 2.9, 3.1 : not ok
	--@param item1 the earlier reference list item
	--@param item2 the later reference list item
	local function labels_are_consecutive(item1,item2)
		local label1 = stringify(identifiers[item1.id].label)
		local label2 = stringify(identifiers[item2.id].label)
		local count1 = tonumber(label1:match('%d+$'))
		local count2 = tonumber(label2:match('%d+$'))
		return count1 and count2 and count2 == count1 + 1 
	end

	---auto_prefixes_are_compatible: if citations have
	-- auto prefixes, check that they are compatible.
	-- if the two items have auto prefix flag, they 
	-- need to be of the same kind.
	--@param item1, item2, reference list items
	local function auto_prefixes_are_compatible(item1, item2)
		local mode1 = item1.agg_pre_mode or self:get_pre_mode(item)
		local mode2 = item2.agg_pre_mode or self:get_pre_mode(item)
		return mode1 == 'none' and mode2 == 'none'
					 or identifiers[item1.id].kind == identifiers[item2.id].kind
	end

	-- Aggregate multiple references. Requirements:
	-- same counter
	-- not if the second has a prefix, unless it's the same
	-- not if either has custom text to replace its label
	-- consecutive numbers
	-- compatible auto prefixes
	-- 
	-- Strategy. When we concatenate an item, we give it the previous
	-- item's id (carried ofer since the first) and add two fields:
	-- `agg_last_id`: id of current item of the sequence
	-- `agg_first_id`: id of first item in the sequence
	-- `agg_count`: how many merges have occurred
	-- `agg_pre_mode`: string auto prefix flag or 'none'
	-- When the loop is over, we use these to create new labels for the
	-- aggregated items.
	local prev_item
	for i = 1, #references do
		item = references[i]
		-- do we aggregate this with the previous one?
		if prev_item
				and counters_are_shared(prev_item,item)
				and (not prev_item.suffix or #prev_item.suffix == 0)
				and not (item.text or prev_item.text)
				and (not item.prefix 
							or stringify(item.prefix) == stringify(prev_item.prefix))
				and labels_are_consecutive(prev_item,item)
				and auto_prefixes_are_compatible(prev_item, item) then

			-- first item's id: use the previous item's id,
			-- unless it's already carrying a first item's id
			item.agg_first_id = prev_item.agg_first_id 
													or prev_item.id
			-- auto prefix activated: use the previous item's
			-- auto prefix flag, unless it's already carrying that
			-- flag from another status
			item.agg_pre_mode = prev_item.agg_pre_mode 
													or self:get_pre_mode(prev_item)

			-- add one merge to the count
			item.agg_count = prev_item.agg_count and prev_item.agg_count + 1
												or 1

			-- carry over from the first item:
			-- prefix
			-- flags
			item.prefix = prev_item.prefix
			item.flags = prev_item.flags

		-- not aggregating: if we had a previous item in waiting we store it 
		elseif prev_item then
				
			new_references:insert(prev_item)
		
		end

		-- if that was the last item, we store it, otherwise we pass it to
		-- the next loop iteration.
		if i == #references then 
			new_references:insert(item)
		else
			prev_item = item
		end

	end

	return new_references
end


---Crossref.get_pre_mode: what auto prefix an item uses
	--@return string auto prefix flag or 'none'
function Crossref:get_pre_mode(item)
	local flag_pattern = '^[pP]res?$'

	for _,flag in ipairs(item.flags) do
		if flag:match(flag_pattern) then
			return flag
		end
	end
	return 'none'
end

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

-- # Walker class

--- Walker: class to hold methods that walk through the document
Walker = {}
--- Walker:walk: walk through a list of blocks, processing statements
--@param blocks (optional) pandoc Blocks to be processed
--								defaults to self.blocks
function Walker:walk(blocks)
	local blocks = blocks or self.blocks
	-- recursion setup
	-- NB, won't look for statements in table cells
	-- element types with elem.content of Blocks type
	local content_is_blocks = pandoc.List:new(
															{'BlockQuote', 'Div', 'Note'})
	-- element types with elem.content a list of Blocks type
	local content_is_list_of_blocks = pandoc.List:new(
							{'BulletList', 'DefinitionList', 'OrderedList'})
	local result = pandoc.List:new()
	local is_modified = false -- whether anything is changed in this doc

	-- go through the blocks in order
	--		- find headings and update counters
	--		- find statements and process them
	for _,block in ipairs(blocks) do

		-- headers: increment counters if they exist
		-- ignore 'unnumbered' headers: <https://pandoc.org/MANUAL.html#extension-header_attributes>
		if self.setup.counters and block.t == 'Header' 
			and not block.classes:includes('unnumbered') then

				self.setup:increment_counter(block.level)
				result:insert(block)

		-- Divs: check if they are statements
		elseif block.t == 'Div' then

			-- try to create a statement
			sta = Statement:new(block, self.setup)

			-- replace the block with the formatted statement, if any
			if sta then
				result:extend(sta:write())
				is_modified = true

			-- if none, process the Div's contents
			else

				local sub_blocks = self:walk(block.content)
				if sub_blocks then
					block.content = sub_blocks
					is_modified = true
					result:insert(block)
				else
					result:insert(block)
				end

			end

		-- ends Div block processing

		-- DefinitionLists: scan for statements
		-- The element is a list, each item is a pair (inlines, 
		-- list of blocks). We need to check the list item per item,
		-- split it if it contains statements, and process the
		-- contents of non-statement items recursively.
		elseif self.setup.options.definition_lists 
						and block.t == 'DefinitionList' then

			-- `previous_items`: store non-statement items one by one until
			-- we encounter a statement 
			local previous_items = pandoc.List:new() -- to store previous items
--			local block_modified = false -- any changes in this block?

			for _,item in ipairs(block.content) do

				-- if we succeed in creating a statement, flush out
				-- any previous items in a DefinitionList and insert
				-- the statement.
				local successful_insert = false 
				-- if item is supposed to be a statement, try parsing and insert.
				-- note that Statement:new needs a single-item DefinitionList,
				-- so we create one and pass it.
				if Statement:DefListitem_is_statement(item, self.setup) then

					-- try to parse
					sta = Statement:new(pandoc.DefinitionList({item}), self.setup)
					if sta then
						-- if previous items, flush them out in a new DefinitionList
						if #previous_items > 0 then
							result:insert(pandoc.DefinitionList(previous_items))
							previous_items = pandoc.List:new()
						end
						result:extend(sta:write())
						is_modified = true
						successful_insert = true
					end
				end

				-- if not a statement or failed to parse, treat as 
				-- standard DefinitionList item: process the contents
				-- recursively and insert in previous items.
				if not successful_insert then 

					-- recursively process the item's contents (list of Blocks)
					-- recall a DefinitionList item is a pair
					-- item[1] Inlines expression defined
					-- item[2] List of Blocks (list of lists of block elements)
					local new_content = pandoc.List:new()
					for _,blocks in ipairs(item[2]) do
						local sub_blocks = self:walk(blocks)
						if sub_blocks then
							is_modified = true
							new_content:insert(sub_blocks)
						else
							new_content:insert(blocks)
						end
					end
					-- if we've modified anything in the recursion, insert
					-- the new content
					if is_modified then
						item[2] = new_content
					end

					-- store the item to be included in a future DefinitionList
					previous_items:insert(item)

				end

			end -- end of the item loop

			-- if any previous_items left, insert as DefinitionList

			if #previous_items > 0 then
				result:insert(pandoc.DefinitionList(previous_items))
				previous_items = pandoc.List:new()
			end

		-- ends DefinitionList block processing

		-- element with blocks content: process recursively
		elseif content_is_blocks:includes(block.t) then

			local sub_blocks = self:walk(block.content)
			if sub_blocks then
				block.content = sub_blocks
				is_modified = true
				result:insert(block)
			else
				result:insert(block)
			end

		-- element with list of blocks content: process recursively
		elseif content_is_list_of_blocks:includes(block.t) then

			-- rebuild the list item by item, processing each
			local content = pandoc.List:new()
			for _,item in ipairs(block.content) do
				local sub_blocks = self:walk(item)
				if sub_blocks then
					is_modified = true
					content:insert(sub_blocks)
				else
					content:insert(item)
				end
			end
			if is_modified then
				block.content = content
				result:insert(block)
			else
				result:insert(block)
			end

		else -- any other element, just insert the block

			result:insert(block)

		end

	end

	return is_modified and pandoc.Blocks(result) or nil

end

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

---Walker.statements_in_lists: filter to handle statements within
-- lists in LaTeX.
-- In LaTeX a statement at the first line of a list item creates an
-- unwanted empty line. We wrap it in a LaTeX minipage to avoid this.
-- Uses
--		self.setup (passed to Statement:Div_is_statement)
--		self.setup.options.LaTeX_in_list_afterskip
-- @TODO This is hack, probably prevents page breaks within the statement
-- @TODO The skip below the statement is rigid, it should pick the
-- skip that statement kind
function Walker:statements_in_lists()
	filter = {}

	-- wrap: wraps the first element of a list of blocks in a minipage.
  -- store the `\parindent` value before, as minipage resets it to zero.
  -- We will set \docparindent before the list to pick it up.
  -- with minipage commands
  local function wrap(blocks)
    blocks:insert(1, pandoc.RawBlock('latex',
      '\\begin{minipage}[t]{\\textwidth-\\itemindent-\\labelwidth}'
      ..'\\parindent\\docparindent'
      ))
    blocks:insert(3, pandoc.RawBlock('latex',
      '\\end{minipage}'
      .. '\\vskip ' .. self.setup.options.LaTeX_in_list_afterskip
      ))
    -- add a right skip declaration within the statement Div
    blocks[2].content:insert(1, pandoc.RawBlock('latex',
      '\\addtolength{\\rightskip}{'
      .. self.setup.options.LaTeX_in_list_rightskip .. '}'
      )
    )

    return blocks
  end

  -- process: processes a BulletList or OrderedList element
  -- return nil if nothing done
  function process(elem)
  	if FORMAT:match('latex') or FORMAT:match('native')
    		or FORMAT:match('json') then
 				
			local list_updated = false
	    -- go through list items, check if they start with a statement
      for i = 1, #elem.content do
        if elem.content[i][1] then
          if elem.content[i][1].t and elem.content[i][1].t == 'Div'
                and Statement:Div_is_statement(elem.content[i][1],self.setup) then
            elem.content[i] = wrap(elem.content[i])
            list_updated = true
          elseif elem.content[i][1].t and elem.content[i][1].t == 'DefinitionList' then
            --@TODO handle DefinitionLists here 
          end
        end
      end

      -- if list has been updated, we need to add a line at the beginning
      -- to store the document's `\parindent` value
      if list_updated == true then
      	return pandoc.Blocks({
          pandoc.RawBlock('latex',
            '\\edef\\docparindent{\\the\\parindent}\n'),
          elem      		
      	})
      end

    end
  end

  -- return the filter
  return {BulletList = process,
  	OrderedList = process}

end

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

-- # Main function

function main(doc) 

	-- JATS writer requires pandoc.write
	-- font formatting in generic output requires 2.17 to work well
	-- not sure which is the lowest compatible version otherwise, 
	-- 2.14 is definitely enough, 2.12 should be good
	if FORMAT:match('jats') then
		PANDOC_VERSION:must_be_at_least '2.17'
	else 
		PANDOC_VERSION:must_be_at_least '2.12'
	end		

	-- create a setup object that holds the filter settings
	local setup = Setup:new(doc.meta)

	-- create a new document walker based on the setting
	local walker = Walker:new(setup, doc)

	-- Protect statements in lists in LaTeX 
	-- by applying the `statement_in_lists` filter
	-- See this function for details.
	walker.blocks = pandoc.Blocks(walker.blocks):walk(walker:statements_in_lists())

	-- walk the document; returns nil if no modification
	local blocks = walker:walk()

	-- process crossreferences if statements were created
	if blocks then
		blocks = blocks:walk(walker:crossreferences())
	end

	-- if the doc has been modified, update its meta and return it
	if blocks then
		doc.blocks = blocks
		doc.meta = setup:update_meta(doc.meta)
		return doc
	end
end

--- Return main as a Pandoc element filter
return {
	{
			Pandoc = main
	},
}