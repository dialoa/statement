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
