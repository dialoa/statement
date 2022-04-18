---
title: Statement filter for Pandoc
author: Julien Dutant
date: April 2022
---

* TOC
{:toc}

Statement is a versatile [Pandoc](https://pandoc.org/) filter to 
write theorems and other numbered or labelled statements 
in markdown and output them in a range of output formats, 
notably LaTeX, HTML and JATS XML.

* 20+ default theorem kinds, with labels in 30+ languages 
    (credit: [LyX team](https://www.lyx.org/)).
* Customization via metadata block: new theorem/statement kinds,
    output style, label translations.
* Crossreferencing numbered and unnumbered theorems.
* Special `statement` kind for indented block statements, with
  or without unique label.
* LaTeX theorems provided by the `amsthm` package.
* Lua filter: [Pandoc](https://pandoc.org/) is the only 
    executable needed.

# Basic usage

__Installation__. Make sure [Pandoc](https://pandoc.org/) 
is installed.^[If in doubt, open a terminal and type `pandoc -v`.] 
Download `statement.lua` and save it in a location that 
Pandoc can access, e.g. the same folder as your source file. 
Open a terminal, navigate to the location of your 
markdown source file (e.g. `source.md`) and enter:

```bash
pandoc -L statement.lua source.md -o output.pdf
```

See [Pandoc's manual](https://pandoc.org/MANUAL.html) for 
more output functions.

Here is a simple source file. Save it as `source.md` and try:

```markdown
---
title: My theorems
author: Jane E. Doe
---

::: theorem
(Pythagoras) The sum of angles in a triangle is equal to 
two right angles.
:::

::: {.theorem #quadratic}
The solutions of a quadratric equation $ax^2 + bx + c$ 
are given by: 
$$x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$
:::

::: corollary
A quadratic equation $ax^2 + bx + c$ has two real solutions 
if and only if $b^2 - 4ac > 0$.
:::

::: proof
Obvious from @quadratic.
:::
```

This will generate the following in your PDF:

![Example output](demo/example1.png 'Example of statement output in PDF')

## Advanced usage

(TO BE CONTINUED)

* 23 default theorem kinds: `algorithm`, `assumption`,
  `axiom`, `claim`, `conclusion`, `condition`, `conjecture`,
  `corollary`, `criterion`, `definition`, `example`, `exercise`,
  `fact`, `lemma`, `note`, `problem`, `proof`, `proposition`,
  `question`, `remark`, `solution`, `summary`,
  `theorem`.
* Default labels in 35 languages
  (thanks to the [LyX team](https://www.lyx.org/)):
  `ar`, `bg`, `ca`, `cs`, `da`, `de`, `el`,
  `en`, `es`, `eu`, `fi`, `fr`, `gl`, `he`, `hr`, `hu`, `ia`, `id`,
  `it`, `ja`, `ko`, `nb`, `nl`, `nn`, `pl`, `pt_br`, `pt_pt`, `ro`,
  `ru`, `sk`, `sl`, `sr`, `sv`, `tr`, `uk`, `zh_cn`, `zh_tw`. 
