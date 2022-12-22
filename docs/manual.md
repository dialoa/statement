---
layout: page
title: Manual
permalink: /manual/
nav_order: 3 # for just-the-docs
---

**DOCUMENTATION IN PROGRESS**

{% raw %}

## Pre-defined statement kinds

`algorithm`, `assumption`, `axiom`, `claim`, `conclusion`,
`condition`, `conjecture`, `corollary`, `criterion`, `definition`,
`example`, `exercise`, `fact`, `lemma`, `note`, `problem`, `proof`,
`proposition`, `question`, `remark`, `solution`, `summary`, `theorem`.

## Supported locales

`ar`, `bg`, `ca`, `cs`, `da`, `de`, `el`, `en`, `es`, `eu`, `fi`,
`fr`, `gl`, `he`, `hr`, `hu`, `ia`, `id`, `it`, `ja`, `ko`, `nb`,
`nl`, `nn`, `pl`, `pt_br`, `pt_pt`, `ro`, `ru`, `sk`, `sl`, `sr`,
`sv`, `tr`, `uk`, `zh_cn`, `zh_tw`. 

## Troubleshooting

### attempt to compare nil with number

```
warning  (node filter): error: ...e/2022/texmf-dist/tex/generic/babel/babel-bid
i-basic.lua:155: attempt to compare nil with number
```

This bug can be produced by a statement with a custom label containing
an __uppercase letter followed by a dash__, such as:

```
::: statement
__L-a__. This statement might generate an error!
:::
```

__Fix 1__. Put the dash in a `\textrm{...}` command:

 ```
::: statement
__L\textrm{-}a__. This will not generate an error.
:::
```

This still comes out as a simple dash in formats other than LaTeX.

__Fix 2__. Surround the dash with spaces

```
::: statement
__L - a__. This will not generate an error.
:::
```

A longer dash probably looks better:

```
::: statement
__L -- a__. This will not generate an error.
:::
```

If that's not satisfying, and you don't want to change the 
statement label, you will have to change your font or 
your pdf engine.

__Details__. This is not a statement filter bug, but a bug within
LaTeX (as of nov 2022). It arises when using the `lualatex` pdf
engine and certain fonts (e.g. Libertinus and STIX Two Text 
generate it, Times New Roman, Helvetica Neue, Avenir don't). 

The bug is a conflict between the `amsthm` and `babel` (specifically, I
suspect, its `luababel` component) packages. It can be generated in LaTeX
itself, e.g:


 ~~~ {.latex}

 \documentclass{article}
\usepackage{amsthm}
\usepackage{fontspec}
\setmainfont{Libertinus Serif}
% The error appears with bidi=basic, not bidi=default
\usepackage[bidi=basic]{babel}

\begin{document}

\newtheorem*{statement}{A-b} % generates an error
% \newtheorem*{statement}{{A}-b} % generates an error
% \newtheorem*{statement}{A{-}b} % generates an error too
\newtheorem*{statement}{a-b} % does not generate an error (only upper case letters)

\end{document}

~~~

### `calc` needed

The `calc` package is needed to handle statements placed
within list (`itemize`/`enumerate` environements). The default Pandoc
template for LaTeX loads it, but if you use a custom template instead
its preamble should contain `\usepackage{calc}`.


[Pandoc]: https://pandoc.org
[PM]: https://pandoc.org/MANUAL.html
[releases]: https://github.com/jdutant/statement/releases/tag/latest
[PM-userdata]: https://pandoc.org/MANUAL.html#option--data-dir
[PM-luafilter]: https://pandoc.org/MANUAL.html#option--lua-filter


[manual]: manual
[PandocLua]: https://pandoc.org/lua-filters.html

{% endraw %}