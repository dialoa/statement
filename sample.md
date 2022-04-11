---
title: A sample document for the statement filter
lang: fr
numbersections: true
statement:
  defaults: 
  amsthm: no
  aliases: 
  acronyms:
  swap-numbers: false
  define-in-header: no
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

# More

::: {.axiom #ax:existence}
__The Axiom of Existence__. There exists a set which has no elements.
:::

::: {.axiom #sta:extensionality}
If every element of $X$ is an element of $Y$ and every element
of $Y$ an element of $X$ then $X=Y$. 
:::

::: {.lemma .lem}
There exists only one set with no elements.
:::

::: definition
The (unique) set with no elements is called the empty set and 
denoted $\varnothing$.
:::

::: proof
Immediate from (axiom) and (axiom).
:::


::: theorem
A theorem.
:::

