---
title: Label and info syntax tests
author: Julien Dutant
numbersections: true # LaTeX only, in HTML use -N or --number-sections
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

::: thm

* Starts with
* A list

This statement has no label or info.
:::

::: thm
1. Starts with
2. a list

(some info) This statement has only info.
:::

::: thm
(some info). This statement has only info, dot is allowed too.
:::

::: thm
@thatone [@theother] This statement has a couple of citations as info.
In JATS, citeproc fails to process the info's embedded citations.
:::

::: thm
@thatone [@theother]. This works with a point too.
:::

::: thm
**(some info)** Info can be placed within Strong emphasis too.
:::

::: thm
**@thatone.** And a dot can be placed within the Strong emphasis.
:::

::: thm
**(some info)**. Or just outside.
:::

::: thm
**Klein's lemma**. This statement has a custom label.
:::

::: thm
**(KL) Klein's lemma**. This statement has a custom label and acronym.
:::

The acronym can be used to crossrefer the statement @KL.

::: thm
**(KL) Klein's lemma.** The filter doesn't care whether there is a dot
after or before the Strong emphasis label.
:::

::: thm
**(KL) Klein's lemma** Or no dot at all.
:::

::: thm
**(KL) Klein's lemma**Even if there's no space - ugly but we won't chase it.
:::

::: thm
**(PP) Principal Principle (Lewis).** Info can be placed with the Strong 
emphasis custom label.
:::

::: thm
**(PP) Principal Principle @thatone [@theother].** Here the info is
a Cite element within the label.
:::

::: thm
**(PP) Principal Principle ** @thatone [@theother] Here the info is
a Cite element without the label.
:::

::: thm
**(PP) (Lewis).** Acronym plus info without custom label should fail.
`**(PP) (Lewis).**` is treated is part of the theorem.
:::

# References
