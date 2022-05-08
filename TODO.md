* bug: statement in lists hide the heading. Perhaps use a
  statement-span? the trick is that the minipage wrapping must be
  done before statement processing, but leave the header visible to
  the statement parser
* clarify code: take trim_dot_space in Helpers
* parse-only mode? Find statements and write crossrefs, but do not
  write statements themselves. Collection filter: needs to amend
  Cites that refer to statements; for that it needs all the statement
  IDs, sort out the Cites into crossref vs biblio.
* provide styling of crossref label, esp. smallcaps for statement
* provide head-pattern, '<label> <num>. **<info>**', relying on
  Pandoc's rawinline parsing
* provide \ref \label crossreferences in LaTeX?
* handle pandoc-amsthm style Div attributes?
* handle the Case environment?
* use DefinitionLists for generic output?
* proof environment in non-LaTeX outputs in LaTeX AMS the proof envt
  doesn't define a new th kind and style as a proofname command to be
  redefined as "Proof", "Démonstration" etc. has an optional argument
  to be used as label: \begin{proof}[label] \end{proof} In other
  formats, we should mirror LaTeX: use the info as label
