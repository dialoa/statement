---
layout: home
nav_order: 1 # for just-the-docs
---

__Statement__ is a Pandoc lua filter to handle theorems and other kinds
of statements in markdown.

Write theorems and other labelled, numbered or plain statements in
markdown. Convert them to multiple output formats using [Pandoc].

Get started with a [quick tour][tour] or read the [manual].

* toc
{:toc}

## Illustration

Save the following as `source.md`:

```
Theorem. (from Spivak 1967) {#fthc}
: Let $f$ be integrable on $[a,b]$, and define $F$ on $[a,b]$ by

    $$F(x) = \int_a^x f.$$

    If $f$ is continuous at $c$ in $[a,b]$ then $F$ is differentiable
    at $c$, and

    $$F'(c) = f(c).$$

    (If $c = a$ or $b$, then $F'(c)$ is understood to mean the right-
    or left-hand derivative of $F$.)

@Pre:fthc is known as the fundamental theorem of calculus.
```

and run `pandoc -L statement.lua source.md -o output.pdf` to get the
PDF:

![Example output](img/thm-spivak.png 'Example of statement PDF output')

Change `output.pdf` for other output formats:

![Example html and MS Word output](img/thm-spivak-html-docx.png
'Example of statement PDF output')

## Features

Multiplaform, free and open source. No dependency other than Pandoc 
and a LaTeX distribution for PDF output.

* 20+ predefined statement kinds in AMS style (theorem, proof,
  definition, corollary, lemma, ...). 
* Define new statement kinds and/or redefine the defaults.
* Unnumbered and custom label statements are specified on the fly, no
  need to define them.
* Optionally count theorems within section, chapter etc. 
* Localization in 30+ languages: Théorème, Věta, Θεώρημα, Теорема. No
  need to mix English code in your text.
* Indented statement style suitable for principles, vignettes, alerts,
  tips and other block content that is not a quote. 
* Cross-reference statements with two syntaxes: citation (simple) or
  link (detailed control). Can be mixed within a single document. 
* Automatic cross-references prefixes ('Theorem 1'). Optional; 
  with and without can be mixed in a single document. 
* Consecutive cross-references are collated ('1.1-1.3').
* Two markdown syntaxes for statement: definition list (lean) or fenced div
  (explicit). Can be mixed within a single document.
* Customize statement styles: fonts, spacing, punctuation, numbers
  before label, linebreak after label. 
  * Full support in LaTeX/PDF output (using `amsthm` and `hyperref`) 
    and html output (using CSS). 
  * Partial support in all other output formats (using native Pandoc
    elements: definition lists, empahsis, ...).
* Semantically correct JATS XML output using the `<statement>` tag.
* Handles some LaTeX quirks, e.g. lists in a theorem. 
* Process documents created for previous theorem filters:
  [pandoc-amsthm] and [pandoc-theorems]. (partial support)
* Compatible with equation numbering filters: [pandoc-crossref],
  [pandoc-eqnos]
* Disable definition list and citation syntax if needed.
* Disable `amsthm` package commands in LaTeX if needed.


## Limitations

* LaTeX outputs: uses hyperlinks rather than LaTeX's native `\label`
  and `\ref` commands. Support for using them planned. Support for
  `cleveref` could be considered too.
* Docx output: relies on generic Pandoc markdown styling. Support for
  `docx` styles should be added.
* JATS XML output: cannot include citations in a statement's info. 
  (Due to a limitation of Pandoc; workaround planned.)
* Styling: no full control of the statement heading format (unlike
  AMSthm package's head specification in LaTeX).
* Cross-references prefixes: only singular ("Theorem"). Support for 
  providing plurals and shortened ones ("Thm.") planned.
* Localisation: only singulars, plural forms should be added. 
* [pandoc-amsthm] compatibility: does not read the label / info
  attributes of fenced divs.
* Read from LaTeX. Pandoc reads theorems in a LaTeX document but 
  directly convets them to text. In the future the filter should include
  a reader that recognizes Pandoc-generated statements and parses them
  as statements. 

## Credits

Developed by the Dialectica Open Access team as part of Markdown-based 
workflow for the production of high-quality academic journals.

Open source, [MIT License][MIT]. See [project
repository][project_repo] for details.

Copyright 2022 [Julien Dutant][jdutant], [Thomas Hodgson][twsh].

## Acknowledgments

This filter is inspired by:

* The [JATS specification][JATS]'s `<statement>` tag for the idea.
* Slim "Sarah" Slim's [pandoc-theorems] for its definition list
  syntax.
* Kolen Chung's [pandoc-amsthm] by its statement syntax and
  metadata definitions.
* Nikolay Yakimov's [pandoc-crossref] for its citation syntax.
* John MacFarlane, Albert Krewinkel and other Pandoc Lua filter
  contributors (in [Pandoc's Lua filter manual][PandocLua] and
  the [lua filters repository][LuaFilters])

Thanks to:

* [Pandoc] and its [Lua filters extension][PandocLua] (John MacFarlane,
  Albert Krewinkel and contributors).
* [LyX contributors][LyX] for common theorems and their translations.

[jdutant]: https://github.com/jdutant/
[twsh]: https://github.com/twsh
[project_repo]: https://github.com/jdutant/statement
[tour]: quick-tour
[manual]: manual
[Pandoc]: https://pandoc.org
[PandocLua]: https://pandoc.org/lua-filters.html
[LuaFilters]: https://github.com/pandoc/lua-filters
[MIT]: https://opensource.org/licenses/MIT
[LyX]: https://www.lyx.org
[JATS]: https://jats.nlm.nih.gov/publishing/
[AMSthm]: https://ctan.org/pkg/amsthm
[pandoc-amsthm]: https://github.com/ickc/pandoc-amsthm
[pandoc-theorems]: https://github.com/sliminality/pandoc-theorem
[pandoc-crossref]: https://github.com/lierdakil/pandoc-crossref
[pandoc-eqnos]: https://github.com/tomduck/pandoc-eqnos
