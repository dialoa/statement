---
title: "Statement: a Lua filter for statement support in Pandoc's markdown"
author: "Julien Dutant, Thomas Hodgson"
---


**WARNING: WORK IN PROGRESS**. The filter works with minimal
functionality, but we are currently working on it and its features
may change in the near future. You're welcome to contribute to the
design of the filter - its abstract object model, syntax, output.
See the "Designing the filter" section below.

A Lua filter for Pandoc to handle "statement" text elements, esp. in
LaTeX, HTML and XML. 

A statement is a "Theorem, Lemma, Proof, Postulate, Hypothesis,
Proposition, Corollary, or other formal statement, identified as such
with a label and usually made typographically distinct from the
surrounding text" (according to the 
[JATS XML specification](https://jats.nlm.nih.gov/articleauthoring/tag-library/1.3/element/statement.html), 
the standard XML tag suite for scientific publishing).
Examples are mathematical theorems, proofs, exercises, but also 
principles or arguments in a philosophy paper, prompts in a 
psychology paper, etc. 

This Lua filter for Pandoc aims to provide:

* a markdown syntax for statements.
* a markdown syntax for cross-referencing statements.
* providing American Mathematical Society statements (theorems,
  axioms, etc.), with suitable output in LaTeX.
* suitable JATS XML outputs.
* control of what kinds of statements a document has and how they look.

Introduction
============

Usage
=====

Copy the filter in a destination accessible to Pandoc. Tell Pandoc to
use it on document with:

```bash
pandoc -s -L path/to/statement.lua source.md -o destination.pdf
```

Markdown syntax
---------------

In markdown statements are written:

```markdown
::: axiom
[@Jones] 
:::
```

Metadata options
----------------

```yaml
statement-filter:
  only-statement: false
  no-aliases: false
  latex-inlist-skip:
  latex-inlist-rightskip:
  defaults: basic # advanced, none
  new-styles:
    fancy:
      space-above:
      space-below:
      indent:
      left-skip:
      right-skip:
      body-font:
      head-font:
      head-punctuation:
      info-delimiters:
      space-after-head:
      head-pattern:
  parent-counter: 1 # or chapter, section, ...
  kinds:
    theorem:
      prefix: thm
      count-with: theorem # what do if empty? allow ref by prefixes?
      style: specify here?

  styling:
    plain:    [Theorem]
    plain-unnumbered: [Lemma, Proposition, Corollary]
    definition:   [Definition,Conjecture,Example,Postulate,Problem]
    definition-unnumbered:    []
    remark:   [Case]
    remark-unnumbered:    [Remark,Note]
    proof:    [proof]
```

* `only-statement`: only Divs explicitly marked with the `statement` class
  are processed.
* `no-aliases`. By default statement kinds are identified by label `axiom`,
  `theorem` and their aliases `axm`, `thm`. Set this to true to only allow...


Resources
=========

Related filters
---------------

An overview of packages providing overlapping functionalities that we can
learn from:

* [pandoc-xnos](https://github.com/tomduck/pandoc-xnos). Python, contains
  several filters including:
  * [pandoc-theoremnos](https://github.com/tomduck/pandoc-theoremnos) for
  theorem statemnts and
  * [pandoc-eqnos](https://github.com/tomduck/pandoc-eqnos) for
  equations
* [pandoc-crossref](https://github.com/lierdakil/pandoc-crossref).
  Haskell, equations statements only.
* [pandoc-amsthm](https://github.com/ickc/pandoc-amsthm). Python,
  AMS theorem statements. Appears to crash with
  Pandoc's latest version ("ImportError: No module named pandocfilters").
* [pandoc-ling](https://github.com/cysouw/pandoc-ling). Lua, linguistic
  examples.
* [pandoc-theorem](https://github.com/sliminality/pandoc-theorem).
  Haskell, AMS theorem statements, LaTeX output only.
* [pandoc-numbering](https://github.com/chdemko/pandoc-numbering). Python,
  numbering arbitrary objects including equations, exercises, output
  markdown; see [documentation](https://pandoc-numbering.readthedocs.io/).

See also the discussion of Pandoc's issue
  [#1608](https://github.com/jgm/pandoc/issues/1608) on support for LaTeX theorem environments. In the end the LaTeX reader has been modified
  to read some theorem environment and output them in formatted markeup
  in markdown (see below). But this markup isn't turned back
  into theorems when going in the other direction.

Some comments:

* None provides `<statement>` markup in XML JATS ouptut (as far as we can tell).
* Several of these filters are also (or mostly) geared toward lists of images,
  figures, tables etc (pandoc-crossref, pandoc-xnos).
* Not all of the filters support cross-referencing (e.g. pandoc-amsthm
doesn't).
* Some filters take over the
  [defintition list](https://pandoc.org/MANUAL.html#definition-lists)
  syntax. This has a markdown feel but may break some things that people
  do or expect:

  - [pandoc-theorem](https://github.com/sliminality/pandoc-theorem)

    ```markdown
    Lemma (Pumping Lemming). \label{pumping}

    :   Text of the lemma...
    ```

  - [pandoc-numbering](https://github.com/chdemko/pandoc-numbering)
    introduces a wholly new syntax but it also overlaps with definition lists:

    ```markdown
    Exercise (This is the first exercise) #

    Exercise #
    :   Text for the second exercise
    ```

* Others use `div` syntax, either [native divs (`<div>`)](https://pandoc.org/MANUAL.html#extension-native_divs) or [fenced divs (`:::`)](https://pandoc.org/MANUAL.html#divs-and-spans):

  - [pandoc-amsthm](https://github.com/ickc/pandoc-amsthm)

    ```markdown
    <div class="proof">
    A Proof.
    </div>
    ```

  - Pandoc's own LaTeX reader converts theorem environments to markdown
    like this:

    ```markdown
    ::: {.thm}
    **Theorem 1**. *Here is a theorem*
    :::

    ::: {.lem}
    **Lemma 1**. *Here is a lemma.*
    :::
    ```

    (The bold and italics here are mimicing the default appearance of
    theorems in LaTeX. They are not in the original LaTeX code that
    simply has `\begin{thm}Here is a theorem.\end{thm}`)

* [pandoc-amsthm](https://github.com/ickc/pandoc-amsthm) provides a YAML syntax
(and parser) for declaring custom theorem types:

  ```yaml
  amsthm:
    plain:    [Theorem]
    plain-unnumbered: [Lemma, Proposition, Corollary]
    definition:   [Definition,Conjecture,Example,Postulate,Problem]
    definition-unnumbered:    []
    remark:   [Case]
    remark-unnumbered:    [Remark,Note]
    proof:    [proof]
    parentcounter:    [chapter]
  ```

* [pandoc-amsthm](https://github.com/ickc/pandoc-amsthm) uses CSS
  counters for numbering in HTML output. This means that the filter
  isn't needed: the class markup and CSS style are enough. Can that cover
  all uses cases though (custom theorems)?

* There referencing styles proposed are as follows:

  *  `@eqn:identifier` in
  [pandoc-crossref](https://github.com/lierdakil/pandoc-crossref)
  * `@eq:identifier` or `{@eq:identifier}`, `+@eq:id`, `*@eq:id`
   `*@eq:id` and `{#eq:id tag="B.1"}` and analogously for theorems
  [pandoc-eqnos](https://github.com/tomduck/pandoc-eqnos),
  * LaTeX style `\ref{}` (I assume) in [pandoc-theorem](https://github.com/sliminality/pandoc-theorem),
  * reference links `[text](#identifier "caption")` and citation links
  `@identifier` in [pandoc-numbering](https://github.com/chdemko/pandoc-numbering).

* In [pandoc-numbering](https://github.com/chdemko/pandoc-numbering) there
  is a [pattern syntax](https://pandoc-numbering.readthedocs.io/en/latest/referencing.html) to include automatically generated expressions in
  the caption (description, section number, ...).

Usage and options
==================

Usage
----

Copy `statement.lua` in the folder of your markdown file or in your `PATH`.

```
pandoc -s --lua-filter=statement.lua sample.md -o output.html
pandoc -s -L statement.lua sample.md -o output.pdf
```

Options
-------

Filter's options are set through a `statement` field in the document's metadata. These can be written in the document or
specified in a defaults file. Example of YAML block:

```
statement:
  supply-header: no
```

Here is a description of the options with their defaults.

`supply-header` (yes)
: standalone output includes code to format statements. Set to "no" if
your template formats statements blocks.

Design of the filter
====================

## Use cases

* Standard AMS classes: Theorem, Axiom, Lemma, Proof, Remark, Problem, ...
* Statement of a principle, scientific law, hypothesis, etc. With or without label.
* Presentation of an argument (premises, horizontal line, conclusion)

See examples in the syntax sections below.

## Object model

This section gives an abstract specification of the properties that we plan the filter to work with. We use YAML-style syntax with comments.

*Conventions*. For leaf entries (those that are not themselves list
or set of entries) the value given is the default one. For non-leaf
we sometimes specify the default with "(default: ...)" in the comments.
If a leaf entry is optional we specify it as `nil (<type>)` where
`<type>` gives its type if set, e.g. `nil (string)`. The types `inlines`
and `blocks` are pandoc's list of (metadata) inlines and blocks,
respectively. INTERNAL indicates that a property is not meant to be
directly read or set by the user; READ-ONLY if a property is meant to
be read but not written by the user; if not specified the property is
meant to be reabable and writable by the user. No property is
*required* to be set by the user; the filter will provide
defaults wherever required.

### Document-level properties

All document-level properties are within a `statement-filter` property.
(Avoids conflicts with other filters when placed in the metadata.
We could provide aliases if that's easier.) Of course the user wouldn't have
to set all of these, and some of them shouldn't be manipulated by the
user at all. It may also not be necessary for the filter to set those
in the document's metadata itself as opposed to a local `options` variable.

```yaml
statement-filter:
  reset-counters-with-headings-level: 0   # 0 counters never reset, 1 reset at each heading 1, etc.
  keep-default-kinds: true    # whether the standard AMS kinds are provided; if false, the user has full control over which kinds exist besides `statement`
  supply-header:  true    # if true, we provide header-includes material to format the statement blocks
  crossref-prefixes: true # if true, we process cross-references with prefixes other that `@sta:`, such as `@thm:`, `@axm:`, `@lem:` etc.
                #
  header: nil (blocks)      # READ-ONLY Stores the material we want to put
                          # in header-includes.
                          # This is a workaround to allow users to pick it in a custom pandoc templates
                          #if they need to use the command line option --include-in-header
  kinds: # (default: the standard AMS kinds) list to which the user can add
    theorem:
      - label: "Theorem"
      - counter: "theorem"   # if user doesn't specify an existing kind, give a warning and treat as unnumbered
      - prefix: thm  # ref to theorem with `@thm:`
    lemma:
      - label: "Lemma"
      - counter: "theorem" # shares the theorem counter
      - prefix: lem
    proof:
      - label: "Proof"
      - counter: ""      # unnumbered
    # ... same for the other AMS standard kinds
    argument:
      - label: ""
      - counter: ""
      - convert-h-rules: true   # any hrule found in the statement will be converted in a half-textwidth rule in the output
    mystatement:
      - label: nil
      - counter: nil
      - convert-h-rules: false
      - prefix: nil
```

### Statement-level properties

These are properties associated with an individual `statement` Div.

```yaml
  kind: nil (string) # one of the statement-filter.kinds. if nil, the statement
    # is of the default kind `statement` (unnumbered, no label).
    # if the user specifies a kind that is not in statement-filter.kinds,
    # we throw a warning and assume this to be nil.
  id: nil (string)
  content: blocks # the content of the statement
  title: nil (inlines) # the title of the statement, e.g. `Pythagoras's theorem`
  label: nil (inlines) # INTERNAL the full formatted label of the statement, e.g. `**Theorem 2.1**`. May be based on a user-provided label.
  info: nil (inlines) # info on the statement, e.g. `[@Pythagoras600BC]`
  number: nil (string) # INTERNAL number of statement, e.g. "1.2"
  reference-text: '***' (inlines) # INTERNAL formatted text to be used when cross-referencing the statement. If the user doesn't specify a label or numbering they get a link with `***` and a warning.
```

### Citation-level properties

These are the properties associated with individual references to statements.
This will be read from pandoc Cite objects and converted into native pandoc
Span inlines with the following properties
(compare [pandoc Ciations](https://pandoc.org/lua-filters.html#type-citation)):

```yaml
classes:
- statement-crossreference # to allow e.g. CSS styling
- ... # user's other classes
citations: # list of (statement-)citation objects
  - key: string # the user-provided key, e.g. thm:pythagoras. If there is no
            # statement with that id, throw a warning and format the
            # reference-text as key?
  - prefix: nil (inlines)
  - suffix: nil (inlines)
  - reference_text: '<key>?' (inlines) # INTERNAL copied from the statement object pointed to by the key, otherwise "<key>?"
```

## Desiderata for a markdown syntax

* readable, 'markdown-y'
* graceful breakdown (in unsupported formats, without the filter)
* customizable: can be used to generate `<statement>` tags, but also
  `AMS theorem` with customisable prefixes and counters.
* support some of the existing syntaxes (see above):
  - definition-style
  - the output for Pandoc's latex reader
  - the more general syntax of pandoc-numbering?
* switches for various syntaxes. In particular, think hard
  about whether to allow syntax that breaks things (e.g.
  definition syntax) or be conservative (default prevents
  breaking existing syntax)

Cases to be covered. (Formatted here as quotations.)

##### Statement with no label or title

Vignette, principle, .... Intended to be printed as one or more indented block.

> Everything is.

##### Usual mathematical classes: label, title

The usual mathematical classes.

> **Theorem 1**. The sum...

> **Theorem 1**. (Pythagoras's Theorem) The sum ...

The title may include additional information instead:

> **Theorem 1**. (Doe, 2012) The sum ...

##### Labelled single theorems in AMS-thm

AMSthm (the AMS-supported LaTeX package to handle theorems) recommends
using labels for special named variant of one of the common types:

> **Klein's lemma**. (Klein, 2012) The sum ...

##### Labelled principes in philosophy

Philosophers often have satements labelled with a name, an acronym,
or both. With a variety of placements:

> *The Principle of Sufficient Reason.* Everything must have a reason or cause.

> *The Principle of Sufficient Reason (PSR).* Everything must have a reason or cause.

> *(PSR)* Everything must have a reason or cause.

> Everything must have a reason or cause. (*PSR*)

How to systematize?

* We could treat those like special named variants of theorems in math. By
  default the label would be strong (bold), which is ugly and will not fit
  every journal. We would have to provide hooks / style options to change those.
* If we provide options to adjust formatting, is it necessary to present
  statement-level overrides? E.g. a philosophy article that cites a
  math name theorem (bold label) but otherwise has labelled principles
  that only call for simple emphasis.
* Title in JATS seems intended for things like "Pythogora's theorem"
  rather than "Doe, 2012". If we use it for that purpose, though,
  what do we do when such information is provided?
    * One option: let the user typeset it - by entering a citation at the
      beginning of the theorem, for instance. What would be wrong with that? (a) that we couldn't give this the desired LaTeX output?

## simple Div syntaxes

Does not break anything, at least in principle. Close to the output
of Pandoc's LaTeX reader.

### Statement without label or title

Vignette, principle, .... Intended to be printed as an indented block.

```markdown
::: statement
Everything is.
:::

::: {.statement}
Everything is.
:::
```

Question: can we add a id, and if yes, refer to it?

### Statement with a title or label?

(Cf. above on the question whether these should be titles or labels.)

```markdown
::: {.statement label="Totality"}
Everything is.
:::

::: {.statement label="A *fine* story"}
He lived and died.
:::

::: statement
**Totality**. Everything is.
:::
```

Should allow both `**Totality**.` and `**Totality.**`.

### Statement with label and acronym

```markdown
::: statement
**Totality (T)**. Everything is.
:::

::: {.statement label="Totality" #totality}
**(T)**. Everything is.
:::

As said in (@sta:totality), ...
```

The reference `@sta:totality` (or whatever reference style we adopt) should
then be replaced with `**T**`.

### Theorem, axioms and other mathematical statements

```
::: {.statement .theorem}
Two plus two equals four.
:::

::: {.statement .proposition .unnumbered}
Two plus two equals four.
:::

```

Perhaps also:

```
::: statement
**Theorem**. Two plus two equals four.
:::

::: {.statement .unnumbered}
**Lemma**. Two plus two equals four.
:::

```


### Argument

Arguments are sometimes presented as statements with a line separating
premises and conclusion. In statements, we reinterpret the horizontal
line as a conclusion line:

```
:::
Everything is something.

Whatever is something, exists.

---
Everything exists.
:::

```

It is typeset at half the main text width. Better looks: make it just as
wide as the largest premise or conclusion in the argument; but that's
hard to achieve in HTML and in LaTeX.

## Other syntaxes

Definition lists style?

## Crossreference syntax

- `@sta:identifier`.
- other?

Note: any `@...`-style syntax requires the filter to be applied before
Pandoc's own citation processing engine`citeproc` and `pandoc-citeproc`.

Default statement kinds
=======================

Suggestion, with crossreference prefixes
and counters:

* Statement. Prefix: sta. Counter: none.
* Theorem. Prefix: thm. Counter: thm.
* Corollary. Prefix: cor. Counter: thm.
* Lemma. Prefix: lem. Counter: thm.
* Proposition. Prefix: prp. Counter: thm.
* Conjecture. Prefix: con. Counter: thm.
* Fact. Prefix: fac. Counter: thm.
* Definition. Prefix: def. Counter: thm.
* Example. Prefix: exa. Counter: thm.
* Problem. Prefix: prb. Counter: thm.
* Exercise. Prefix: exe. Counter: thm.
* Solution. Prefix: sol. Counter: thm.
* Remark. Prefix: rem. Counter: thm.
* Claim. Prefix: cla. Counter: thm.
* Proof. Prefix: prf. Counter: none.

With an "extended-kinds" option (or by default?) we could
also provide  the eleven extended kinds of LyX's AMS Extended
module. Also perhaps Postulate (pos).

[LyX](https://www.lyx.org/) provides the following defaults for
mathematical statements.

__With simple LaTeX__

Theorem, Corollary, Lemma, Proposition, Conjecture, Fact,
Definition, Example, Problem, Exercise, Solution and Remark,
Claim are all numbered together. Proof is unnumbered. Case is
a numbered list type with its own local numbering allowing three
levels of sub-lists. The first six (Theorem, Corollary, Lemma,
Proposition, Conjecture, Fact) are in `plain` style: bold
roman label, italic text, extra space above and below.
The next (Definition, Example, Problem, Exercise, Solution) are
 in `definition` style: bold label, roman text, extra space above
and below. Two (Remark, Claim) are in `remark` style: italic
label, no extra space. Case, Proof have their own style, similar
to `remark`.

```latex
\theoremstyle{plain}
\newtheorem{thm}{\protect\theoremname}
\theoremstyle{plain}
\newtheorem{cor}[thm]{\protect\corollaryname}
\theoremstyle{plain}
\newtheorem{lem}[thm]{\protect\lemmaname}
\theoremstyle{plain}
\newtheorem{prop}[thm]{\protect\propositionname}
\theoremstyle{plain}
\newtheorem{conjecture}[thm]{\protect\conjecturename}
\theoremstyle{plain}
\newtheorem{fact}[thm]{\protect\factname}
\theoremstyle{definition}
\newtheorem{defn}[thm]{\protect\definitionname}
\theoremstyle{definition}
\newtheorem{example}[thm]{\protect\examplename}
\theoremstyle{definition}
\newtheorem{problem}[thm]{\protect\problemname}
\theoremstyle{definition}
\newtheorem{xca}[thm]{\protect\exercisename}
\theoremstyle{definition}
\newtheorem{sol}[thm]{\protect\solutionname}
\theoremstyle{remark}
\newtheorem{rem}[thm]{\protect\remarkname}
\theoremstyle{remark}
\newtheorem{claim}[thm]{\protect\claimname}
\newlist{casenv}{enumerate}{4}
\setlist[casenv]{leftmargin=*,align=left,widest={iiii}}
\setlist[casenv,1]{label={{\itshape\ \casename} \arabic*.},ref=\arabic*}
\setlist[casenv,2]{label={{\itshape\ \casename} \roman*.},ref=\roman*}
\setlist[casenv,3]{label={{\itshape\ \casename\ \alph*.}},ref=\alph*}
\setlist[casenv,4]{label={{\itshape\ \casename} \arabic*.},ref=\arabic*}
\makeatletter
\ifx\proof\undefined
\newenvironment{proof}[1][\protect\proofname]{\par
  \normalfont\topsep6\p@\@plus6\p@\relax
  \trivlist
  \itemindent\parindent
  \item[\hskip\labelsep\scshape #1]\ignorespaces
}{%
  \endtrivlist\@endpefalse
}
\providecommand{\proofname}{Proof}
\fi
\makeatother

\usepackage{babel}
\providecommand{\casename}{Case}
\providecommand{\claimname}{Claim}
\providecommand{\conjecturename}{Conjecture}
\providecommand{\corollaryname}{Corollary}
\providecommand{\definitionname}{Definition}
\providecommand{\examplename}{Example}
\providecommand{\exercisename}{Exercise}
\providecommand{\factname}{Fact}
\providecommand{\lemmaname}{Lemma}
\providecommand{\problemname}{Problem}
\providecommand{\propositionname}{Proposition}
\providecommand{\remarkname}{Remark}
\providecommand{\solutionname}{Solution}
\providecommand{\theoremname}{Theorem}
```

__With the AMS theorem module (`amsthm` package)__

Same as above, except that all environments also have an
unnumbered variant, except Case and Proof. Proof is not
defined: it is already provided by the package (and its
label is localized by `babel` or `amsthm`).

```latex
\theoremstyle{plain}
\newtheorem{thm}{\protect\theoremname}
\theoremstyle{plain}
\newtheorem*{thm*}{\protect\theoremname}
\theoremstyle{plain}
\newtheorem{cor}[thm]{\protect\corollaryname}
\theoremstyle{plain}
\newtheorem*{cor*}{\protect\corollaryname}
\theoremstyle{plain}
\newtheorem{lem}[thm]{\protect\lemmaname}
\theoremstyle{plain}
\newtheorem*{lem*}{\protect\lemmaname}
\theoremstyle{plain}
\newtheorem{prop}[thm]{\protect\propositionname}
\theoremstyle{plain}
\newtheorem*{prop*}{\protect\propositionname}
\theoremstyle{plain}
\newtheorem{conjecture}[thm]{\protect\conjecturename}
\theoremstyle{plain}
\newtheorem*{conjecture*}{\protect\conjecturename}
\theoremstyle{plain}
\newtheorem{fact}[thm]{\protect\factname}
\theoremstyle{plain}
\newtheorem*{fact*}{\protect\factname}
\theoremstyle{definition}
\newtheorem{defn}[thm]{\protect\definitionname}
\theoremstyle{definition}
\newtheorem*{defn*}{\protect\definitionname}
\theoremstyle{definition}
\newtheorem{example}[thm]{\protect\examplename}
\theoremstyle{definition}
\newtheorem*{example*}{\protect\examplename}
\theoremstyle{definition}
\newtheorem{problem}[thm]{\protect\problemname}
\theoremstyle{definition}
\newtheorem*{problem*}{\protect\problemname}
\theoremstyle{definition}
\newtheorem{xca}[thm]{\protect\exercisename}
\theoremstyle{definition}
\newtheorem*{xca*}{\protect\exercisename}
\theoremstyle{definition}
\newtheorem{sol}[thm]{\protect\solutionname}
\theoremstyle{definition}
\newtheorem*{sol*}{\protect\solutionname}
\theoremstyle{remark}
\newtheorem{rem}[thm]{\protect\remarkname}
\theoremstyle{remark}
\newtheorem*{rem*}{\protect\remarkname}
\theoremstyle{remark}
\newtheorem{claim}[thm]{\protect\claimname}
\theoremstyle{remark}
\newtheorem*{claim*}{\protect\claimname}
\newlist{casenv}{enumerate}{4}
\setlist[casenv]{leftmargin=*,align=left,widest={iiii}}
\setlist[casenv,1]{label={{\itshape\ \casename} \arabic*.},ref=\arabic*}
\setlist[casenv,2]{label={{\itshape\ \casename} \roman*.},ref=\roman*}
\setlist[casenv,3]{label={{\itshape\ \casename\ \alph*.}},ref=\alph*}
\setlist[casenv,4]{label={{\itshape\ \casename} \arabic*.},ref=\arabic*}

\providecommand{\casename}{Case}
\providecommand{\claimname}{Claim}
\providecommand{\conjecturename}{Conjecture}
\providecommand{\corollaryname}{Corollary}
\providecommand{\definitionname}{Definition}
\providecommand{\examplename}{Example}
\providecommand{\exercisename}{Exercise}
\providecommand{\factname}{Fact}
\providecommand{\lemmaname}{Lemma}
\providecommand{\problemname}{Problem}
\providecommand{\propositionname}{Proposition}
\providecommand{\remarkname}{Remark}
\providecommand{\solutionname}{Solution}
\providecommand{\theoremname}{Theorem}
```

__With the module AMS extended__

The LyX module "AMS extended" provides elevent additional
statement kinds: Criterion, Algorithm, Axiom, Assumption,
Question (in the `plain` style), Condition (in the `definition`
style), Note, Notation, Summary, Acknowledgement, Conclusion (in
the `remark` style). All numbered with Theorem, and all with
an unnumbered version. The preamble is as with the AMS module
with the following additions:

```latex
\theoremstyle{plain}
\newtheorem{criterion}[thm]{\protect\criterionname}
\theoremstyle{plain}
\newtheorem*{criterion*}{\protect\criterionname}
\theoremstyle{plain}
\newtheorem{lyxalgorithm}[thm]{\protect\algorithmname}
\theoremstyle{plain}
\newtheorem*{lyxalgorithm*}{\protect\algorithmname}
\theoremstyle{plain}
\newtheorem{ax}[thm]{\protect\axiomname}
\theoremstyle{plain}
\newtheorem*{ax*}{\protect\axiomname}
\theoremstyle{definition}
\newtheorem{condition}[thm]{\protect\conditionname}
\theoremstyle{definition}
\newtheorem*{condition*}{\protect\conditionname}
\theoremstyle{remark}
\newtheorem{note}[thm]{\protect\notename}
\theoremstyle{remark}
\newtheorem*{note*}{\protect\notename}
\theoremstyle{remark}
\newtheorem{notation}[thm]{\protect\notationname}
\theoremstyle{remark}
\newtheorem*{notation*}{\protect\notationname}
\theoremstyle{remark}
\newtheorem{summary}[thm]{\protect\summaryname}
\theoremstyle{remark}
\newtheorem*{summary*}{\protect\summaryname}
\theoremstyle{remark}
\newtheorem{acknowledgement}[thm]{\protect\acknowledgementname}
\theoremstyle{remark}
\newtheorem*{acknowledgement*}{\protect\acknowledgementname}
\theoremstyle{remark}
\newtheorem{conclusion}[thm]{\protect\conclusionname}
\theoremstyle{remark}
\newtheorem*{conclusion*}{\protect\conclusionname}
\theoremstyle{plain}
\newtheorem{assumption}[thm]{\protect\assumptionname}
\theoremstyle{plain}
\newtheorem*{assumption*}{\protect\assumptionname}
\theoremstyle{plain}
\newtheorem{question}[thm]{\protect\questionname}
\theoremstyle{plain}
\newtheorem*{question*}{\protect\questionname}

\providecommand{\acknowledgementname}{Acknowledgement}
\providecommand{\algorithmname}{Algorithm}
\providecommand{\assumptionname}{Assumption}
\providecommand{\axiomname}{Axiom}
\providecommand{\conclusionname}{Conclusion}
\providecommand{\conditionname}{Condition}
\providecommand{\criterionname}{Criterion}
\providecommand{\notationname}{Notation}
\providecommand{\notename}{Note}
\providecommand{\questionname}{Question}
\providecommand{\summaryname}{Summary}
```


Target outputs
==============

XML JATS
--------

An example from the [XML JATS reference for the `<statement>`
element](https://jats.nlm.nih.gov/publishing/tag-library/1.2/element/statement.html):

```jats
<p>The following hypothesis is posited:
  <statement>
    <label>Hypothesis 1</label>
      <p>Buyer preferences for companies are influenced
      by factors extrinsic to the firm attributable to, and
      determined by, country-of-origin effects.</p>
  </statement>
</p>
```

An example from an [American Mathematical Society (AMS) sample
JATS article](https://github.com/AmerMathSoc/AMS-Lens/blob/master/data/arxiv-0312227/arxiv-0312227.xml):

```jats
 <statement content-type="theorem" style="thmplain"
  specific-use="resource" id="ltxid2">
    <label>Assumption 1.1</label>
    <p content-type="noindent">
      <inline-formula content-type="math/tex">...</inline-formula>.
    </p>
</statement>
```

The latter shows:
  * that the `id` tag should be supported. Proposal: set it to the statement's markdown key, but leave it out otherwise?
  * that any numbering is preprocessed and included in the label with a prefix.

The element may contain [a `title` tag](https://jats.nlm.nih.gov/publishing/tag-library/1.2/element/statement.html). We assume this should be used for the statement's name, if any:

```jats
<statement id="sta:gaia">
  <label>Hypothesis 1.1</label>
  <title>The Gaia hypothesis</title>
  <p>All organisms  and  their  inorganic  surroundings on  Earth  are  closely  integrated  to  form  a single  and  self-regulating  complex  system.</p>
</statement>
```

To cross-reference, we should mark up the statement with [a `<target>` tag](https://jats.nlm.nih.gov/publishing/tag-library/1.2/element/target.html).

When (as happens in philosophy) a statement is labelled with an acronym of its
title, we could insert that in the label (worth checking how eLife Lens would print that):

```jats
<statement id="sta:pp">
  <label>PP</label>
  <title>The Principal Principle</title>
  <p>A rational agent's credence in $p$ conditional on the chance of $p$ being $x$ is $x$.</p>
</statement>
```

LaTeX
-----

The components of AMS theorems are:

* Heading, which includes:
  - Prefix. Example `Axiom`, `Theorem`, `Klein's Lemma`, or empty.
  - Number. Automatically generated, per type or group of types and chapter as needed.
  - Additional Info. Example: `Klein \cite{bibkey}` or `Pythagoras' Theorem`.
* Content.

The default typesetting is as follows, with indentation:

__Prefix Number__. (Additional Info). *Content*

*More content*

For standard maths theorem, we can map Prefix + Number to JATS's `<label>` and Additional Info ... to JATS's `<title>`? Alternatively, our syntax differentiates a title from random additional info, and we print the title as Prefix if there's no prefix, after additional info if there's a prefix?

For statements without a math type (prefix) but only a name and possibly an abbreviation, we need to decide whether the name / abbreviation are printed as "prefix" or "additional info" or neither.

LaTeX environment tags are `\begin{<kind>}` and `end{<kind>}` where `<kind>` specifies the kind of theorem, e.g. "thm". For a single special named
theorem, the package doc recommends defining a single kind with its
own name. The environment commands are:

* default, `\begin{<kind>}...\end{<kind>}`, typesets the content with prefix
and number as specificed by the theorem kind definition (see below)
* with additional information, `\begin{<kind>}[Klein \cite{bibkey}]`, `\begin{<kind>}[Pythagoras's theorem]`
* without number `\begin{<kind>*}`.

The theorem kinds are defined as follows.

* `\newtheorem{thm}{Theorem}`: `thm` will be the environment name, `Theorem` the prefix. The statements will be numbered.
* `\newtheorem*{exa}{Example}`: not numbered. Can be used for a single theorem: `\newtheorem*{klein}{Klein's Lemma}`, whose name is then going to be typed as prefix and not additional information.
* `\newtheorem{lem}{Lemma}[thm]` kind with 'parent counter': will be numbered continuously with `thm` entries.

  `\newtheorem{prop}{Proposition}[section]`. The 'parent counter' can be a LaTeX sectioning level, in that case the statements are numbered X.1, X.2 where X is the number of the current division of that level.

* `\setcounter{thm}{0}` set a counter to an arbitrary value.
* Cross refernce to theorems? `\label` and `\ref` I think.

How to handle the cross-reference of statements using abbreviations? e.g. print
out (PP) when cross-refering to a principle whose name is abbreviated PP?

HTML
----

Close to XML, perhaps with some classes to allow for styling.

Proposals:

```html
<div class="statement" id="sta:mystatement">
  <span class="statement-heading">
    <span class="statement-prefix">Theorem</span> <span class="statement-number">3</span>.
    </span>
    <p>Text of the statement...</p>
</div>
```

Or something with "label" and "title" matching the XML?

Contributing
============

Feedback on the proposed syntax and projected behaviour welcome. Feel free
to use issues, PRs or to contact us directly.

The [source documentation](https://jdutant.github.io/statement/) is available
on Github and at `docs/index.html`.

The source documentation is generated from the source with
[Ldoc](https://stevedonovan.github.io/ldoc/manual/doc.md.html) (available through[Luarocks](https://luarocks.org/), run `luarocks install ldoc` or
`sudo luarocks install ldoc`). Once you have Ldoc install, you can regenerate
the documentation by running this in the repository base directory:

```bash
ldoc --all ./
```
