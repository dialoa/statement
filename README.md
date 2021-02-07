---
title: "Statement - a Lua filter for statement support in Pandoc's markdown"
author: "Julien Dutant, Thomas Hodgson"
---

Introduction
============

Presentation
------------

Statements are text blocks that are not quotations. They typically
stand out from the surrounding text and are sometimes labelled and
numbered. Examples are vignettes used in a psychology experiments,
principles in a philosophy paper, arguments, mathematical theorems,
proofs, exercises, and so on. In JATS XML (the XML tag suite used
for scientific and academic papers) there is a `<statement>` element
to mark them up.

This project aims to develop:
* A markdown syntax for statements.
* A [Pandoc](http://pandoc.org) filter using that syntax to generate `LaTeX` and `PDF`, `html`, `JATS XML`.

The features we ultimately aim to provide include:
1. labelling statements,
2. cross-referencing statements, including with their label,
3. providing AMS-style statements (theorems, axioms, proofs, exercises, ...), and customizing them
4. ways to input statements in docx.

But this is a work in progress and we focus on the first two features first. Feedback on the proposed syntax and the code is welcome.

Related filters
---------------

An overview of packages providing overlapping functionalities that we can
learn from:

* [pandoc-xnos](https://github.com/tomduck/pandoc-xnos). Python, contains
  several filters including:
    - [pandoc-theoremnos](https://github.com/tomduck/pandoc-theoremnos) for
    theorem statemnts and
    - [pandoc-eqnos](https://github.com/tomduck/pandoc-eqnos) for
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


Some comments.

* To our knowledge none of these provide `<statement>` markup in XML JATS
ouptuts.
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
    introduces a whole new syntax but still hijacks some elements of definition lists:

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

  - the output of Pandoc's LaTeX reader when given theorem commands:

    ```
    ::: {.thm}
    **Theorem 1**. *Here is a theorem*
    :::

    ::: {.lem}
    **Lemma 1**. *Here is a lemma.*
    :::
    ```

    The above is the result of running `pandoc -f latex -t markdown` on:

    ```latex
    \usepackage{amsthm}
    \newtheorem{thm}{Theorem}
    \newtheorem{lem}{Lemma}
    \begin{thm}Here is a theorem
    \end{thm}
    \begin{lem}Here is a lemma.
    \end{lem}
    ```

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

* The referencing style is `@eqn:identifier` in
  [pandoc-crossref](https://github.com/lierdakil/pandoc-crossref),
  `@eq:identifier` or `{@eq:identifier}`, `+@eq:id`, `*@eq:id`
   `*@eq:id` and `{#eq:id tag="B.1"}` and similarly for theorems
  [pandoc-eqnos](https://github.com/tomduck/pandoc-eqnos), LaTeX style `\ref{}` (I assume) in [pandoc-theorem](https://github.com/sliminality/pandoc-theorem), and reference links `[text](#identifier "caption")` and citation links
  `@identifier` in [pandoc-numbering](https://github.com/chdemko/pandoc-numbering).

  In [pandoc-numbering](https://github.com/chdemko/pandoc-numbering) there
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
  header: no
```

Here is a description of the options with their defaults.

`header` (yes)
: standalone output includes code to format statements. Set to "no" if
your template formats statements blocks.

Proposed syntax
=====

## Desiderata

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

## simple Div syntax

Does not break anything, at least in principle. Close to the output
of Pandoc's LaTeX reader.

### Statement without a label

Vignette, principle,

```markdown
::: statement
Everything is.
:::

::: {.statement}
Everything is.
:::
```

Question: can we add a id, and if yes, refer to it?

### Statement with a label

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
then be replaced with `**T**`.`

### Theorem, axioms and other mathematical statements

```
::: {.statement .theorem}
Two plus two equals four.
:::

::: {.statement .proposition .unnumbered}
Two plus two equals four.
:::

```

### Argument

In statements, the horizontal line is reinterpreted as an conclusion line
(separating premises and conclusion)

```
:::
Everything is something.

Whatever is something, exists.

---
Everything exists.
:::

```

## Other syntaxes

Definition lists style?

## Reference syntax

- `@sta:identifier`.
- other?

Note: any `@...`-style syntax requires the filter to be applied before
Pandoc's own citation processing engine`citeproc` and `pandoc-citeproc`.

Target outputs
==============

XML JATS
--------

An example from the [XML JATS reference for the `<statement>`
element[https://jats.nlm.nih.gov/publishing/tag-library/1.2/element/statement.html):

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

LaTeX environment tags are `\begin{xxx}` and `end{xxx}` where `xxx` specifies the kind of theorem. A kind can be specified for a single theorem if we want its name in bold. The environment options are:

* default, `\begin{thm}`, with prefix and number
* with additional information, `\begin{thm}[Klein \cite{bibkey}]`, `\begin{thm}[Pythagoras's theorem]`

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
</statement>
```

Or something with "label" and "title" matching the XML?

Contributing
============

Feedback on the proposed syntax and projected behaviour welcome. Feel free
to use PRs or contact us.

[Source code documentation](doc/index.html) in `doc/`.

Source documentation generated with
[Ldoc](https://stevedonovan.github.io/ldoc/manual/doc.md.html) (available through[Luarocks](https://luarocks.org/) as `ldoc`).
To update the documentation run this in this directory:

```bash
ldoc --all ./
```
