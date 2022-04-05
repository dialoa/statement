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
