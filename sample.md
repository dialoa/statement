---
title: A sample document for the statement filter
lang: fr
numbersections: true
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

::: {.statement .example}

(a) The set of all prime divisors of $324$.
(b) The set of all numbers divisible by 0.
(c) The set of all continuous real-valued functions on the interval $[0,1]$.
(d) The set of all ellipses with major axis $5$ and eccentricity $3$.
(e) The set of all sets whose elements are natural numbers less than 20.

:::

::: exa

[@reference] another example

:::

::: statement
$X \subseteq Y$ if and only if every element of $X$ is an element of $Y$. 
:::

::: statement
__Named principle (NP)__. This is a named principle with an acronym.
:::

# More

::: {.axiom #ax:existence}
__The Axiom of Existence__. There exists a set which has no elements.
:::
### subsec

::: {.axiom #sta:extensionality}
If every element of $X$ is an element of $Y$ and every element
of $Y$ an element of $X$ then $X=Y$. 
:::

::: {.lemma .lem}
There exists only one set with no elements.
:::
### subsec

::: definition
The (unique) set with no elements is called the empty set and 
denoted $\varnothing$.
:::

::: proof
Immediate from (axiom) and (axiom).
:::

### subsec

::: cor
A corollary.
:::

::: axiom
__Named principle__. This checks that two statements with the same custom
label get different environments.
:::
