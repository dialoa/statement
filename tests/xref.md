---
title: Cross-references with the statement filter
author: Julien Dutant
numbersections: true # LaTeX only, in HTML use -N or --number-sections
linkcolor: blue
link-citations: true
statement:
    count-within: section
abstract: Demonstrates cross-references with
    the statement filter. Filler text is used to
    make sure the links point to the theorem
    rather than a section heading. Theorems
    are counted within section to demonstrate
    numbered crosslabels.
references:
- type: article-journal
  id: thatone
  author:
  - family: Dummy
    given: D.
  issued:
    date-parts:
    - - 1900
      - 1
      - 1
  title: 'Dummy reference'
  container-title: Journal
  volume: 1
  issue: 1
  page: 1-10
- type: article-journal
  id: theother
  author:
  - family: Otherdummy
    given: A.N.
  issued:
    date-parts:
    - - 1900
      - 1
      - 1
  title: 'Dummy reference'
  container-title: Journal
  volume: 1
  issue: 1
  page: 1-10
---

# Section

::: {.theorem #mytheorem}
A theorem to be cross-referenced. 
:::

Formatting tests:

* @mytheorem
* @my-old-theorem
* `[]{#mytheorem}`, [](#mytheorem)
* `[Theorem <>]{#mytheorem}`, [Theorem <>](#mytheorem)

::: {#non-statement}

tests

:::

::: theorem
**My old theorem**. Another one
:::


# References
