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

# Mathematical theorems

::: {.statement .example .unnumbered}

(a) The set of all prime divisors of $324$.
(b) The set of all numbers divisible by 0.
(c) The set of all continuous real-valued functions on the interval $[0,1]$.
(d) The set of all ellipses with major axis $5$ and eccentricity $3$.
(e) The set of all sets whose elements are natural numbers less than 20.

:::

::: {.fact .unnumbered}

[@reference] another example

:::

::: my-div

Recursion test. he two following statements are within list items within a Div element.

1. :::::: statement
   $X \subseteq Y$ if and only if every element of $X$ is an element of $Y$. 
   ::::::
2. :::::: statement
   __(NP) Named principle__. This is a named principle with an acronym.
   ::::::

:::

Crossreference test. See ([](#NP)) or ([](#named-principle))! And citation
syntax [@NP] or [@named-principle].
