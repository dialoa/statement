--[[-- # Statement - a Lua filter for statements in Pandoc's markdown

This Lua filter provides support for statements (principles,
arguments, vignettes, theorems, exercises etc.) in Pandoc's markdown.

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@author Thomas Hodgson <hello@twshodgson.net>
@copyright 2021-2022 Julien Dutant, Thomas Hodgson
@license MIT - see LICENSE file for details.
@release 0.3

@TODO unnumbered class
@TODO handle cross-references. in LaTeX \ref prints out number or section number if unnumbered
@TODO LaTeX hack for statements in list
@TODO html output, read Pandoc's number-offset option

proof environement in LaTeX AMS:
- does not define a new theorem kind and style
- has a \proofname command to be redefined
- has an optional argument for label
\begin{proof}[label]
\end{proof}
how do we handle it in html, jats? best would be not to create 
a new class every time, so mirror LaTeX. 

]]

-- # Global variables
stringify = pandoc.utils.stringify

-- # Filter components
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

--- Setup.labels_by_id: stored labels per statement id
Setup.labels_by_id = {
	-- identifier = Inlines
}

-- Setup.includes: code to be included in header or before first statement
Setup.includes = {
	header = nil,
	before_first = nil,
}
--- Setup.DEFAULTS: default sets of kinds and styles
-- See amsthm documentation <https://www.ctan.org/pkg/amsthm>
-- the 'none' definitions are always included but they can be 
-- overridden by others default sets or the user.
Setup.DEFAULTS = {}
Setup.DEFAULTS.KINDS = {
	none = {
		statement = {prefix = 'sta', style = 'empty', counter='none',
									custom_label_style = {
											label_punctuation = '.',
									}},
	},
	basic = {
		theorem = { prefix = 'thm', style = 'plain', counter = 'section' },
		lemma = { prefix = 'lem', style = 'plain', counter = 'theorem' },
		corollary = { prefix = 'cor', style = 'plain', counter = 'subsubsection' },
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
		proof = {prefix = 'claim', style = 'proof', counter = 'none'},
	},
	advanced = {
		theorem = { prefix = 'thm', style = 'plain', counter = 'section' },
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
		proof = {prefix = 'claim', style = 'proof', counter = 'none'},
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
			indent = '0pt',
			head_font = 'smallcaps',
			label_punctuation = '',
			space_after_head = ' ',
			heading_pattern = nil,			
		},
	},
	basic = {
		plain = { do_not_define_in_latex = true },
		definition = { do_not_define_in_latex = true },
		remark = { do_not_define_in_latex = true },
		proof = { do_not_define_in_latex = false }, -- let Statement.write_style take care of it
	},
	advanced = {
		plain = { do_not_define_in_latex = true },
		definition = { do_not_define_in_latex = true },
		remark = { do_not_define_in_latex = true },
		proof = { do_not_define_in_latex = false }, -- let Statement.write_style take care of it
	},
}

--- Setup.LOCALE: localize statement labels
Setup.LOCALE = {
		de = {
			theorem = 'Theorem',
			corollary = 'Korollar',
			lemma = 'Lemma',
			proposition = 'Satz',
			conjecture = 'Vermutung',
			fact = 'Fakt',
			definition = 'Definition',
			example = 'Beispiel',
			problem = 'Problem',
			exercise = 'Aufgabe',
			solution = 'Lösung',
			remark = 'Bemerkung',
			claim = 'Behauptung',
			proof = 'Beweis',
			axiom = 'Axiom',
			criterion = 'Kriterium',
			algorithm = 'Algorithmus',
			condition = 'Bedingung',
			note = 'Notiz',
			notation = 'Notation',
			summary = 'Zusammenfassung',
			conclusion = 'Schlussfolgerung',
			assumption = 'Annahame',
			hypothesis = 'Annahame',
			question = 'Frage',
		},
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
			axiom = 'Axiom',
			criterion = 'Criterion',
			algorithm = 'Algorithm',
			condition = 'Condition',
			note = 'Note',
			notation = 'Notation',
			summary = 'Summary',
			conclusion = 'Conclusion',
			assumption = 'Assumption',
			hypothesis = 'Hypothesis',
			question = 'Question',
		},
		es = {
			theorem = 'Teorema',
			corollary = 'Corolario',
			lemma = 'Lema',
			proposition = 'Proposición',
			conjecture = 'Conjectura',
			fact = 'Hecho',
			definition = 'Definición',
			example = 'Ejemplo',
			problem = 'Problema',
			exercise = 'Ejercicio',
			solution = 'Solución',
			remark = 'Observación',
			claim = 'Afirmación',
			proof = 'Demonstración',
			axiom = 'Axioma',
			criterion = 'Criterio',
			algorithm = 'Algoritmo',
			condition = 'Condición',
			note = 'Nota',
			notation = 'Notación',
			summary = 'Resumen',
			conclusion = 'Conclusión',
			assumption = 'Suposición',
			hypothesis = 'Hipótesis',
			question = 'Frage',
		},
		fr = {
			theorem = 'Théorème',
			corollary = 'Corollaire',
			lemma = 'Lemme',
			proposition = 'Proposition',
			conjecture = 'Conjecture',
			fact = 'Note',
			definition = 'Définition',
			example = 'Example',
			problem = 'Problème',
			exercise = 'Exercice',
			solution = 'Solution',
			remark = 'Remarque',
			claim = 'Affirmation',
			proof = 'Démonstration',
			axiom = 'Axiome',
			criterion = 'Critère',
			algorithm = 'Algorithme',
			condition = 'Condition',
			note = 'Note',
			notation = 'Notation',
			summary = 'Résumé',
			conclusion = 'Conclusion',
			assumption = 'Supposition',
			hypothesis = 'Hypothèse',
			question = 'Question',
		},
		it = {
			theorem = 'Teorema',
			corollary = 'Corollario',
			lemma = 'Lemma',
			proposition = 'Proposizione',
			conjecture = 'Congettura',
			fact = 'Fatto',
			definition = 'Definizione',
			example = 'Esempio',
			problem = 'Problema',
			exercise = 'Esercizio',
			solution = 'Soluzione',
			remark = 'Osservazione',
			claim = 'Asserzione',
			proof = 'Dimostrazione',
			axiom = 'Assioma',
			criterion = 'Criterio',
			algorithm = 'Algoritmo',
			condition = 'Condizione',
			note = 'Nota',
			notation = 'Notazione',
			summary = 'Summario',
			conclusion = 'Conclusione',
			assumption = 'Assunzione',
			hypothesis = 'Ipotesi',
			question = 'Quesito',
		}
}

--- Setup:read_options: read user options into the Setup.options table
--@param meta pandoc Meta object, document's metadata
--@return nil sets the Setup.options table
function Setup:read_options(meta) 

	-- language. Set language if we have a self.LOCALE value for it
	if meta.lang then
		-- change the language only if we have a self.LOCALE value for it
		-- try the first two letters too
		local lang_str = stringify(meta.lang)
		if self.LOCALE[lang_str] then
			self.options.language = lang_str
		elseif self.LOCALE[lang_str:sub(1,2)] then
			self.options.language = lang_str:sub(1,2)
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
	self.LaTeX_section_level = self:get_LaTeX_section_level(meta)

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
		}
		for key,option in pairs(boolean_options) do
			if type(meta.statement[option]) == 'boolean' then
				self.options[key] = meta.statement[option]
			end
		end

	end


end

--- Create kinds and styles
-- Populates Setup.kinds and Setup.styles with
-- default and user-defined kinds and styles
--@param meta pandoc Meta object, document's metadata
--@return nil sets the Setup.kinds, Setup.styles, Setup.aliases tables
function Setup:create_kinds_and_styles(meta)
	local default_keys = pandoc.List:new() -- list of DEFAULTS.KINDS keys
	local chosen_defaults = 'basic' -- 'basic' unless user says otherwise
	local language = self.options.language

	-- make a list of defaults we have (overkill but future-proof)
	-- check that there's a DEFAULTS.STYLES key too
	default_keys = pandoc.List:new()
	for key,_ in pairs(self.DEFAULTS.KINDS) do
		if self.DEFAULTS.STYLES[key] then
			default_keys:insert(key)
		else
			message('WARNING', 'DEFAULTS file misconfigured: no `'
				..default_key..'` STYLES.')
		end
	end

	-- user-selected defaults?
	if not meta.statement and meta.statement.defaults
		and default_keys:find(stringify(meta.statement.defaults)) then
			chosen_defaults = stringify(meta.statement.defaults)
	end

	-- add the 'none' defaults no matter what
	for kind,definition in pairs(self.DEFAULTS.KINDS.none) do
		self.kinds[kind] = definition
	end
	for style,definition in pairs(self.DEFAULTS.STYLES.none) do
		self.styles[style] = definition
	end

	-- add the chosen defaults
	if chosen_defaults ~= 'none' then
		for kind,definition in pairs(self.DEFAULTS.KINDS[chosen_defaults]) do
			self.kinds[kind] = definition
		end
		for style,definition in pairs(self.DEFAULTS.STYLES[chosen_defaults]) do
			self.styles[style] = definition
		end
	end

	-- @TODO read kinds and styles definitions from `meta` here

	-- ensure all labels are Inlines
	-- localize statement labels that aren't yet defined
	for kind_key, kind in pairs(self.kinds) do
		if kind.label then
			kind.label = pandoc.Inlines(kind.label)
		elseif not kind.label and self.LOCALE[language][kind_key] then
			kind.label = pandoc.Inlines(self.LOCALE[language][kind_key])
		end
	end


	-- populate the aliases map (option 'aliases')
	if self.options.aliases then

		for kind_key,kind in pairs(self.kinds) do
			-- use the kind's prefix as alias, if any
			if kind.prefix then 
				self.aliases[kind.prefix] = kind_key
			end
			-- us the kind's label (converted to plain text), if any
			if kind.label then
				local alias = pandoc.write(pandoc.Pandoc({kind.label}), 'plain')
				alias = alias:gsub('\n','')
				self.aliases[alias] = kind_key
			end
		end

	end

end

--- Setup:create_counters create level counters based on statement kinds
--@return nil, modifies the self.counters table
--@TODO html output, read Pandoc's number-offset option
function Setup:create_counters()
	-- default counter output: %s for counter value, 
	-- %p for its parent's formatted output
	local default_format = function (level)
		return level == 1 and '%s' or '%p.%s'
	end

	-- only create counters from 1 to level required by some kind
	for kind_key,definition in pairs(self.kinds) do
		local level = tonumber(definition.counter) or 
									self:get_level_by_LaTeX_name(definition.counter)
		if level then
			if level >= 1 and level <= 6 then

				-- create counters up to level if needed
				for i = 1, level do
					if not self.counters[i] then
							self.counters[i] = {
																		count = 0,
																		reset = pandoc.List:new(),
																		format = default_format(i),
																	}
					end
				end
				self.counters[level].reset:insert(kind_key)

			else

				message('WARNING','Kind '..kind_key..' was assigned level '..tostring(level)
													..', which is outside the range 1-6 of Pandoc levels.'
													..' Counters for these statement will probably not work as desired.')

			end

		end

	end

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


--- Setup:length_format: parse a length in the desired format
--@TODO what if a space is provided (space after head)
-- @param len Inlines or string to be interpreted
-- @param format (optional) desired format if other than FORMAT
-- @return string specifying the length in the desired format or ''
function Setup:length_format(str, format)
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
	-- add `\` to LATEX_LENGTHS keys (can't be done directly)
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

--- Setup:length_format: parse font features into the desired format
--@TODO what if a space is provided (space after head)
-- @param len Inlines or string to be interpreted
-- @param format (optional) desired format if other than FORMAT
-- @return string specifying font features in the desired format or ''
function Setup:font_format(str, format)
	local format = format or FORMAT
	local result = ''
	if type(str) ~= 'string' then
		str = stringify(str)
	end

	-- within this function, format is 'css' when css features are needed
	if format:match('html') then
		format = 'css'
	end

	-- FEATURES and their conversion
	local FEATURES = {
		upright = {
			latex = '\\upshape',
			css = 'font-style: italic;',
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
			css = 'font-weight: bold;'
		},
	}
	-- provide 'small-caps' alias
	-- nb, we use the table key as a matching pattern, so `-` is escaped
	FEATURES['small%-caps'] = FEATURES.smallcaps

	for feature,definition in pairs(FEATURES) do
		if str:match(feature) and definition[format] then
			result = result..definition[format]
		end
	end

	return result

end

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

-- # Statement class

--- Statement: class for statement objects.
-- @field kind string the statement's kind (key of the `kinds` table)
-- @field id string the statement's id
-- @field cust_label Inlines the statement custom's label, if any
-- @field info Inlines the statement's info
Statement = {
	kind = nil, -- string, key of `kinds`
	id = nil, -- string, Pandoc id
	custom_label = nil, -- Inlines, user-provided label
	crossref_label = nil, -- Inlines, label used to crossreference the statement
	label = nil, -- Inlines, formatted label to display
	acronym = nil, -- Inlines, acronym
	info = nil, -- Inlines, user-provided info
	content = nil, -- Blocks, statement's content
	is_numbered = true, -- whether a statement is numbered
}
--- create a statement object from a pandoc element.
-- @param elem pandoc Div or list item (= table list of 2 elements)
-- @param setup Setup class object, the document's statements setup
-- @return statement object or nil if elem isn't a statement
function Statement:new(elem, setup)

	local kind = Statement:find_kind(elem, setup)
	if kind then

		-- create an object of Statement class
		local o = {}
		self.__index = self 
		setmetatable(o, self)

		-- populate the object
		o.setup = setup -- filter setup
		o.kind = kind -- element kind
		o.content = elem.content -- element content
		o:extract_label() -- extract label, acronym
		-- if custom label, create a new kind
		if o.custom_label then
			o:new_kind_from_label()
		end
		o:extract_info() -- extract info
		o:set_identifier(elem) -- set identifier based on elem.identifier or acroynym
		o:set_is_numbered(elem) -- set self.is_numbered
		if o.is_numbered then
			o:increment_count() -- update the kind's counter
		end
		o:set_crossref_label() -- set crossref label

		-- return
		return o
	
	else
		return nil
	end

end
--- Statement:find_kind: find whether an element is a statement and of what kind
--@param elem pandoc Div or item in a pandoc DefinitionList
--@param setup Setup class object, filter setup
--@return string or nil the key of `kinds` if found, nil otherwise
function Statement:find_kind(elem, setup)
	local kinds = setup.kinds -- points to the kinds table
	local options = setup.options -- points to the options table
	local aliases = setup.aliases -- points to the aliases table

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

		-- return the first match, a key of `kinds`
		return matches[1]

	elseif type(elem) == 'table' then

			message('WARNING', 'A non-Div element passed as potential statement. '
				.. 'Not supported yet. Element content: '..stringify(elem))

		-- process DefinitionList items here
		-- they are table with two elements:
		-- [1] Inlines, the definiens
		-- [2] Blocks, the definiendum

	else

		return nil -- not a statement kind

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

--- extract_label: extract label and acronym from a statement Div.
-- A label is a Strong element at the beginning of the Div, ending or 
-- followed by a dot. An acronym is between brackets, within the label
-- at the end of the label. If the label only contains an acronym,
-- it is used as label, brackets preserved.
-- if `acronym_mode` is set to false we do not search for acronyms.
-- Updates:
--		self.custom_label Inlines or nil, content of the label if found
--		self.acronym Inlines or nil, acronym
--		self.content Blocks, remainder of the statement after extraction
--@return nil 
function Statement:extract_label()
	local delimiters = {'(',')'} -- acronym delimiters
	local first_block, lab, acro = nil, nil, nil
	local has_label = false

	-- first block must be a Para that starts with a Strong element
	if self.content[1] and self.content[1].t == 'Para'
			and self.content[1].content and self.content[1].content[1]
			and self.content[1].content[1].t == 'Strong' then
		first_block = self.content[1]:clone() -- Para element
		lab = first_block.content[1].content -- content of the Strong element
		first_block.content:remove(1) -- take the Strong elem out
	else
		return
	end

	-- the label must end by or be followed by a dot
	-- if a dot is found, take it out.
	-- ends by a dot?
	if lab[#lab] 
		and lab[#lab].t == 'Str'
		and lab[#lab].text:match('%.$') then
			-- remove the dot
			if lab[#lab].text:len() > 1 then
				lab[#lab].text =
					lab[#lab].text:sub(1,-2)
				has_label = true
			else -- special case: Str was just a dot
				lab:remove(#lab)
				-- remove trailing Space if needed
				if lab[#lab]
					and lab[#lab].t == 'Space' then
						lab:remove(#lab)
				end
				-- do not validate if empty
				if #lab > 0 then
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
	if self.setup.options.acronyms then
		local bracketed, remainder = self:extract_fbb(lab, 'reverse')
		if bracketed and #remainder > 0 then
			acro = bracketed
			lab = remainder
		end
	end

	-- remove trailing Space on the label if needed
	if #lab > 0 and lab[#lab].t == 'Space' then
		lab:remove(#lab)
	end

	-- remove leading Space on the first block if needed
	if first_block.content[1] 
		and first_block.content[1].t == 'Space' then
			first_block.content:remove(1)
	end

	-- store label, acronym modified content if label found
	if has_label then
		self.content[1] = first_block
		self.acronym = acro
		self.custom_label = lab
	end

end

--- Statement:new_kind_from_label: create and set a new kind from a 
-- statement's custom label. 
-- updates the self.setup.kinds table with a new kind
function Statement:new_kind_from_label()
	local kind = kind or self.kind
	local kind_key, style_key

	-- create_key_from_label: turn inlines into a key that
	-- can safely be used as LaTeX envt name and html class
	local function create_key_from_label(inlines)
		local result = stringify(inlines):gsub('[^%w]','_'):lower()
		if result == '' then result = '_' end
		return result
	end

	-- Main function body

	if not self.custom_label then
		return
	end

	local label_str = create_key_from_label(self.custom_label)
	kind_key = label_str
	style_key = self.setup.kinds[kind].style -- original style

	-- do we need a new style too?
	if self.setup.kinds[kind].custom_label_style then
		local new_style = {}
		-- copy the fields from the original statement style
		-- except 'is_defined'
		for k,v in pairs(self.setup.styles[style_key]) do
			if k ~= 'is_defined' then
				new_style[k] = v
			end
		end
		-- insert the custom_label_style modifications
		for k,v in pairs(self.setup.kinds[kind].custom_label_style) do
			new_style[k] = v
		end
		-- ensure we use a new style key
		style_key = label_str
		local n = 1
		while self.setup.styles[style_key] do
			style_key = label_str..'-'..tostring(n)
		end
		-- store the new style
		self.setup.styles[style_key] = new_style
	end

	-- ensure we use a new kind key
	local n = 1
	while self.setup.kinds[kind_key] do
		kind_key = label_str..'-'..tostring(n)
		n = n + 1
	end

	-- create the new kind
	-- keep the original prefix; new style if needed
	-- set its new label to custom_label; set its counter to 'none'
	self.setup.kinds[kind_key] = {}
	self.setup.kinds[kind_key].prefix = self.setup.kinds[kind].prefix
	self.setup.kinds[kind_key].style = style_key
	self.setup.kinds[kind_key].label = self.custom_label -- Inlines
	self.setup.kinds[kind_key].counter = 'none'

	-- set this statement's kind to the new kind
	self.kind = kind_key

end

--- Statement:extract_info: extra specified info from the statement's content.
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
				self:extract_fbb(first_block.content)
		end

		-- if info found, save it and save the modified block
		if inf then
			self.info = inf
			self.content[1] = first_block
		end

	end

end

--- Statement:set_identifier: set an element's id
-- store it with the crossref label in setup.labels_by_id
function Statement:set_identifier(elem)
	local id

	if elem.identifier and elem.identifier ~= '' then
		id = elem.identifier
	elseif self.acronym then
		id = stringify(self.acronym):gsub('[^%w]','-')
	end

	if id and id ~= '' then
		if self.setup.labels_by_id[id] then
			message('WARNING', 'Two statements with the same identifier: '..id..'.'
								..' The second is ignored.')
		else
					self.id = id
					self.setup.labels_by_id[id] = 'CROSSREF'
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

	-- is_counter: whether a counter is a level, LaTeX level or 'self'
	local function is_counter(counter) 
		return counter == 'self'
					or (type(counter) == 'number' and counter >= 1 and counter <= 6)
					or self.setup:get_level_by_LaTeX_name(counter)
		end

	if elem.t == 'Div' and elem.classes:includes('unnumbered') then

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


---Statement:increment_count: increment a statement kind's counter
-- Increments the kind's count of this statement kind or
-- its shared counter's kind.
function Statement:increment_count()
	kinds = self.setup.kinds -- pointer to the kinds table
	kind_key = self.kind
	-- shared counter?
	if kinds[kind_key].counter and kinds[kinds[kind_key].counter] then
		kind_key = kinds[kind_key].counter
	end
	kinds[kind_key].count = kinds[kind_key].count 
													and kinds[kind_key].count + 1
													or 1

end

--- Statement:set_crossref_label
-- Set a statement's crossref label, i.e. the text that will be
-- used in crossreferences to the statement.
-- priority:
--		- use self.crossref_label, if user set
-- 		- use self.acronym, otherwise
--		- use self.label (custom label), otherwise
--		- use formatted statement count
--		- '??'
--@return nil sets self.crossref_label, pandoc Inlines
function Statement:set_crossref_label()
	local delimiter = '.' -- separates section counter and statement counter
	local kinds = self.setup.kinds -- pointer to the kinds table
	local counters = self.setup.counters -- pointer to the counters table

	-- use self.crossref_label if set
	if self.crossref_label then
	-- or use acronym
	elseif self.acronym then
		self.crossref_label = self.acronym
	-- or custom label
	elseif self.custom_label then
		self.crossref_label = self.custom_label
	-- or formatted statement count
	elseif self.is_numbered then
		-- if shared counter, switch kind to the shared counter's kind
		local kind = self.kind
		local counter = kinds[self.kind].counter
		if kinds[counter] then
			kind = counter
			counter = kinds[counter].counter
		end
		-- format result depending of 'self', <level> or 'none'/unintelligible
		if counter =='self' then
			local count = kinds[kind].count or 0
			self.crossref_label = pandoc.Inlines(pandoc.Str(tostring(count)))
		elseif type(counter) == 'number' 
			or self.setup:get_level_by_LaTeX_name(counter) then
			if type(counter) ~= 'number' then
				counter = self.setup:get_level_by_LaTeX_name(counter)
			end
			local count = kinds[kind].count or 0
			local prefix = self.setup:write_counter(counter)
			local str = prefix..delimiter..tostring(count)
			self.crossref_label = pandoc.Inlines(pandoc.Str(str))
		else
			self.crossref_label = pandoc.Inlines(pandoc.Str('??'))
		end
	else
		self.crossref_label = pandoc.Inlines(pandoc.Str('??'))
	end

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
	local style = style or self.setup.kinds[self.kind].style
	local blocks = pandoc.List:new() -- blocks to be written

	-- check if the style is already defined or not to be defined
	if self.setup.styles[style].is_defined 
			or self.setup.styles[style]['do_not_define_in_'..format] then
		return {}
	else
		self.setup.styles[style].is_defined = true
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
			local style_def = self.setup.styles[style]
			local space_above = style_def.margin_top or '0pt'
			local space_below = style_def.margin_bottom or '0pt'
			local body_font = self.setup:font_format(style_def.body_font)
			if style_def.margin_right then
				body_font = '\\addtolength{\\rightskip}{'..style_def.margin_left..'}'
										..body_font
			end
			if style_def.margin_left then
				body_font = '\\addtolength{\\leftskip}{'..style_def.margin_left..'}'
										..body_font
			end
			local indent = style_def.indent or ''
			local head_font = self.setup:font_format(style_def.head_font)
			local label_punctuation = style_def.label_punctuation or ''
			-- NB, space_after_head can't be '' or LaTeX crashes. use ' ' or '0pt'
			local space_after_head = style_def.space_after_head or ' ' 
			local heading_pattern = style_def.heading_pattern or ''
			local LaTeX_command = '\\newtheoremstyle{'..style..'}'
										..'{'..space_above..'}'
										..'{'..space_below..'}'
										..'{'..body_font..'}'
										..'{'..indent..'}'
										..'{'..head_font..'}'
										..'{'..label_punctuation..'}'
										..'{'..space_after_head..'}'
										..'{'..heading_pattern..'}\n'
			blocks:insert(pandoc.RawBlock('latex',LaTeX_command))

		end
	
	elseif format:match('html') then

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
-- If the statement's kind is not yet define, create blocks to define it
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

	-- check if the kind is already defined
	if self.setup.kinds[kind].is_defined then
		return {}
	else
		self.setup.kinds[kind].is_defined = true
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
	
	if self.is_numbered then

		-- add kind label
		if kinds[self.kind] and kinds[self.kind].label then
			inlines:extend(kinds[self.kind].label)
		end
		-- insert numbering from self.crossref_label
		if self.crossref_label then
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

	elseif self.custom_label then

		inlines:extend(self.custom_label)
		if self.acronym then
			inlines:insert(pandoc.Space())
			inlines:insert(pandoc.Str(bb))
			inlines:extend(self.acronym)			
			inlines:insert(pandoc.Str(eb))
		end

	end

	return inlines

end

--- Statement:write: format the statement as an output string.
-- @param format string (optional) format desired if other than FORMAT
-- @return Blocks blocks to be inserted. 
function Statement:write(format)
	local blocks = pandoc.List:new()
	local format = format or FORMAT
	local kinds = self.setup.kinds -- pointer to the kinds table
	local label_inlines -- statement's label
	local label_delimiter = '.'

	-- do we have before_first includes to include before any
	-- definition? if yes include them here and wipe it out
	if self.setup.includes.before_first then
		blocks:extend(self.setup.includes.before_first)
		self.setup.includes.before_first = nil
	end

	-- write the kind definition if needed
	-- if local blocks are returned, insert them
	local write_kind_local_blocks = self:write_kind()
	if write_kind_local_blocks then
		blocks:extend(write_kind_local_blocks)
	end

	label_inlines = self:write_label() or pandoc.List:new()

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
		-- label?
		if #label_inlines > 0 then
			label_inlines:insert(pandoc.Str(label_delimiter))
			-- @TODO format according to statement kind
			heading:insert(pandoc.Strong(label_inlines))
		end

		-- info?
		if self.info then 
			heading:insert(pandoc.Space())
			heading:insert(pandoc.Str('('))
			heading:extend(self.info)
			heading:insert(pandoc.Str(')'))
		end

		-- insert heading
		-- combine statement heading with the first paragraph if any
		if #heading > 0 then
			if self.content[1] and self.content[1].t == 'Para' then
				heading:insert(pandoc.Space())
				heading:extend(self.content[1].content)
				self.content[1] = pandoc.Para(heading)
			else
				self.content:insert(1, pandoc.Para(heading))
			end
		end

		-- place all the content blocks in blockquote
		blocks:insert(pandoc.BlockQuote(self.content))

	end

	return blocks

end


-- # Main functions
--- walk_doc: processes the document.
-- @param doc Pandoc document
-- @param setup a Setup class object, the document's statement setup
-- @return Pandoc document if modified or nil
local function walk_doc(doc,setup)

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

			-- headers: increment counters if they exist
			if setup.counters and block.t == 'Header' then

					setup:increment_counter(block.level)
					result:insert(block)

			elseif block.t == 'Div' then

				-- try to create a statement
				sta = Statement:new(block, setup)

				-- replace the block with the formatted statement, if any
				if sta then
					result:extend(sta:write())
					is_modified = true
				else
					result:insert(block)
				end

			else -- if not a statement, we simply add the block

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

function main(doc) 

	-- create a setup object that holds the filter settings
	local setup = Setup:new(doc.meta)

	-- walk the document; sets `doc` to nil if no modification
	doc = walk_doc(doc,setup)

	-- if the doc has been modified, update its meta and return it
	if doc then
		doc.meta = setup:update_meta(doc.meta)
		return doc
	end
end

--- Return main as a Pandoc object filter
return {
	{
			Pandoc = main
	},
}