---
layout: page
title: Manual
permalink: /manual/
nav_order: 3 # for just-the-docs
---

**DOCUMENTATION IN PROGRESS**

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

* The `calc` package is needed to handle statements placed
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
