---
layout: page
title: Quick tour
permalink: /quick-tour/
nav_order: 2 # for just-the-docs
---

* TOC
{:toc}

## Markdown + Pandoc + Statement

A markdown file is just a plain text file with some human-readable
markup like \*this\* for *italics*. Markdown basics can be [learned 
in 60 seconds][md60s]. Markdown files are created with a text editor
and saved with the `md`, `mkd` or `markdown` extensions. 

(Note: MacOS's TextEdit doesn't work as a text editor, it doesn't save
files as plain text. Search for MacOS text editors online. On Windows
you can use Notepad, on Linux gedit, though you may want to switch to
more powerful editors for sustained projects.)

[Pandoc] is a command line tool that converts to and from a wide range
of document formats. We'll use it to convert a markdown source to
various output formats, including PDF (via LaTeX), html (webpage) and
MS Word `docx`. It uses an [extended markdown syntax][PM-md] that is
useful to write academic texts.

**Statement** is a filter that Pandoc can insert in its conversion. It
extends the markdown syntax further to handle theorems and other
statements. 

[md60s]: https://commonmark.org/help/
[Pandoc]: https://pandoc.org
[PM-md]: https://pandoc.org/MANUAL.html#pandocs-markdown

## Write statements: two syntaxes

Start with the simple document below. It begins with an optional
*preamble* between `---` and `---` lines that allows us to specify
some document properties, here its title and author. Later we will use
the document preamble to specify its language and to customize our
statements.

```markdown
---
title: My statements
author: Jane E. Doe
---

Theorem. 
: For all numbers $a$ and $b$ we have: $|a + b| \leq |a| + |b|$.

Definition.
: A function is a rule which assigns, to each of certain real numbers,
  some other real number.
```

This illustates the **Definition List syntax** for statements. The
syntax is normally used for [definition lists][PM-deflists] but the
filter repurposes it for writing theorems. (You can still use
definition lists, provided that the expression defined isn't
'theorem', 'lemma' or some other statement kind.) The first line is
the theorem label, followed one or more paragraphs starting with `:`.

You can also enter theorems as follows:

```markdown
::: thm
For all numbers $a$ and $b$ we have: $|a + b| \leq |a| + |b|$.
:::

::: def
A function is a rule which assigns, to each of certain real numbers,
some other real number.
:::
```

This illustrates the **fenced Div syntax** for statements. [Fenced
Divs][PM-divs] are all-purposes divisions in Pandoc. They are normally
invisible in output, but they can be given attributes (here, the `thm`
and `def` classes, respectively) that allow filters to format them.

[PM-deflists]: https://pandoc.org/MANUAL.html#definition-lists
[PM-divs]: https://pandoc.org/MANUAL.html#extension-fenced_divs

I've used full labels in definition lists (`Theorem`, `Definition`)
and short aliases in fenced Divs (`thm`, `def`) but I could have done
the opposite, or used the kind names `theorem` and `definition`:

```markdown
thm
: For all numbers $a$ and $b$ we have: $|a + b| \leq |a| + |b|$.

definition
: A function is a rule which assigns...

::: theorem
For all numbers $a$ and $b$ we have...
:::

::: Definition
A function is a rule which assigns...
:::
```

These will all generate the same output.

## WORK IN PROGRESS

### Generate outputs

Installation

1. Make sure [Pandoc] is installed.
2. Get the `statement.lua` file from the [repository's releases
   page][releases]. For a simple test, place it in the same folder as
   your markdown source file. For a more permanent solution you could
   place it in [Pandoc's user data directory][PM-userdata] (you can
   see what it is by running `pandoc -v`). You can also use an
   arbitrary location and pass it to Pandoc via the command line.

Create a markdown source file (see [below](#markdown-syntax)) and
save it, say as `source.md`. Open a terminal and navigate to its
folder. Apply the Statement filter to it by running Pandoc with
the `-L` (alias `--lua-filter`) flag:

```bash
pandoc source.md -L statement.lua -o output.pdf
```

This converts your source into a PDF file, `output.pdf` file. Change
the extension to get other output formats.

If `statement` is not in the present folder nor in Pandoc's user data
dir you need to specify its absolute or relative path on the command
line:

```bash
pandoc source.md -L /path/to/statement.lua -o output.pdf
```

A few tips:

* add `-s` (alias `--standalone`) to produce a self-contained document.
  This is implied in PDF, MS Word/OpenOffice outputs but not in html.
* add `-N` (alias `--number-sections`) to number the sections of
  your document.
* by and large the order in which you specify parameters doesn't
   matter:

   ```bash
   pandoc -L statement.lua  -s -N -o page.html source.md
   ```

   Though if you're applying several filters, they are applied in the
   order in which they appear on the command line. 

See the [Pandoc manual][PM] for more detail on command line options,
in particular the [lua filter][PM-luafilter] and [user data
dir][PM-userdata] options.

[PM]: https://pandoc.org/MANUAL.html
[releases]: https://github.com/jdutant/statement/releases/tag/latest
[PM-userdata]: https://pandoc.org/MANUAL.html#option--data-dir
[PM-luafilter]: https://pandoc.org/MANUAL.html#option--lua-filter

### Localization

If you specify a document's language in the preamble. 


### Crossreferencing

### Aliases

Each statement kind has:

* An internal name: `theorem`, `lemma`, `definition`, `proof`, 
  `statement`
* An label that appears in output ()
a label that appears in output (and possibly some
aliases.




However, when we only want to specify one class, we can write it 
without `.` and curly brackets:

```markdown
::: theorem
For all numbers $a$ and $b$ we have: $|a + b| \leq |a| + |b|$.
:::
```

### More on fenced Divs

A [fenced Div][PM-divs] starts with an opening fence of three or more
consecutive colons (`:::`) and ends with a closing fence of at least
three colons. It should separated from previous or subsequent text by
a blank line. 

The opening fence can carry attributes, which are normally specified
between curly brackets and can be *classes* (starting with `.`), 
an *identifier* (starting with `#`) and key-value pairs (`key=value`):

```markdown
::: { .theorem #mythm source="Spivak 1967" }
For all numbers $a$ and $b$ we have: $|a + b| \leq |a| + |b|$.
:::
```

Attributes aren't visible in output, but they may be used by filters
(among other things). Statement uses *classes* to specify a statement
kind and *identifier* to refer to a specific statement. (An identifier
is supposed to be unique; classes can be shared by several Divs.)

When there's just one class specified, we can do without the `.` and
curly brackets. Thus the following two fences are equivalent:

```markdown
::: { .theorem }

::: theorem
```

A fenced Div with class `thm`, `theorem` or `Theorem` will be treated
as a theorem; `lem`, `lemma` or `Lemma` as a lemma, etc. 


## A note on LaTeX

In case you've been wondering: in our first theorem, the bits between
`$` signs are mathematical formulas. They aren't markdown but LaTeX
codes: `\leq` is LaTeX code for the lower-or-equal symbol (≤). Even
the `$a$` and `$b$` are LaTeX formulas: not only they will be output
as italics *a* and *b*, but in PDF output their typesetting will be
subtly different (different font and spacing than an italic *a*), and
in 'semantic' documents they will be marked up as equations (html,
JATS XML).

You could write an [entire document in LaTeX][LaTeX-intro]. But LaTeX
is harder to learn and much less readable than markdown. Here is a bit
of text with emphasis (italics) and strong emphasis (bold), a footnote
and a citation, in LaTeX:

```latex
My \textit{first} \textbf{point}.\footnote{See \cite{smith2022}.}
```

And in markdown:

```markdown
My *first* **point**.^[See @smith2022]
```

LaTeX is also too detailed. It is typesetting language designed for
fine-grain control of PDF outputs. While Pandoc can usually do a good
job at converting a LaTeX files to other formats, LaTeX document too
easily end up with a clutter of design code that doesn't easily 
translate in other formats. 

Statements are a case in point: theorems can be written in LaTeX
(notably with the AMS theorem package) but Pandoc doesn't fully
convert them.

Markdown is a better authoring syntax. For most projects, it has you
just what you need to write your document, leaving detailed design
issues to later stages. Pandoc readily converts it to main output
formats without loss. 

To write math formulas in markdown, though, you'll need to know the
bit of LaTeX needed to encode them. The [Latex Wikibook][LaTeX-wb] has
a [good overview of maths in LaTeX][LaTeX-wb-maths], and plenty of
tutorials online. 

If that's dauting, you could start by using [LyX], a MS Word-like
visual editor to produce LaTeX that allows you to enter formulas by
clicking on symbols or typing their LaTeX code. It displays a symbol's
LaTeX code if you hover over it, so you can easily find symbols and
the correspoinding LaTeX code. You'll quickly get used to directly
type the codes in instead. 

[LaTeX-wb]: https://en.wikibooks.org/wiki/LaTeX
[LaTeX-wb-maths]: https://en.wikibooks.org/wiki/LaTeX/Mathematics
[LyX]: https://lyx.org
