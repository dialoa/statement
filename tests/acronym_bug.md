---
title: Recursions and lists in the statement filter
author: Julien Dutant
numbersections: true # LaTeX only, in HTML use -N or --number-sections
statement:
  defaults: 
  amsthm:
  aliases: 
  acronyms:
  swap-numbers: false
  define-in-header: yes
  supply-header: yes
  only-statement: false
---

:::::: statement
__(NP) Named principle__. This is a named principle with an acronym.
::::::

Theorem **(PP) Named** (info)
: test.

::: {.statement #oth}
Test
:::

[](#NP)

<!--
Crossreference bugs: [](#NP) and [test](#NPP) and [test <>](#NP).
-->