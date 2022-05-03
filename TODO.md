* clarify code: Helpers. Walkers.counters..., Definitions
* handle reference prefixes like pandoc-crossref
			put with a generic 'pre', 'Pre' prefix
			`[@thm:id]`` theorem 1, `[@Thm:id]` Theorem 1
			`[-@thm:id]` 1
			`@thm:id` handled like `[@thm:id]`.
* provide plural locales
* parse-only mode? Find statements and write crossrefs, but do not 
			write statements themselves. Collection filter: needs to turn Cites into Links
			in order to isolate. Needs to find all statements to sort out
			the Cites into crossref vs biblio.
* provide head-pattern, '<label> <num>. **<info>**', relying on Pandoc's rawinline parsing
* provide \ref \label crossreferences in LaTeX?
* handle pandoc-amsthm style Div attributes?
* handle the Case environment?

* proof environment in non-LaTeX outputs
			in LaTeX AMS the proof envt doesn't define a new th kind and style
			as a proofname command to be redefined as "Proof", "Démonstration" etc.
			has an optional argument to be used as label:
			\begin{proof}[label]
			\end{proof}
			In other formats, we should mirror LaTeX: use the info as label
