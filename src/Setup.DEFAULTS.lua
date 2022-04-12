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