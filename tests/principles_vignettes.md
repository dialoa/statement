---
title: Principles and vignettes with the 
    Statement filter
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
---

This line is here to establish the normal textblock width. Lorem ipsum
dolor sit amet, consectetuer adipiscing elit. Ut purus elit,
vestibulum ut, placerat ac, adipiscing vitae, felis.

::: statement

This statement will be rendered as simple indented text. Curabitur dictum gravida mauris. Nam arcu libero, nonummy eget, consectetuer id, vulputate a, magna. 

* It has two paragraphs
* and a list.

Donec vehicula augue eu neque. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Mauris ut leo.

:::

The statement below has a custom label. The label is automatically
turned into an ID that can be used to 
[reference it](#the-principal-principle)

::: statement
**The Principal Principle**. One's credence in $p$ conditional
on the hypothesis that the chance of $p$ is $x$ should be $x$.
:::

Acronyms can be specified too, at the beginning of the custom
label. When an acronym is present it is the basis of the automatic
id for crossreferencing, here @PP:

::: statement
**(PP) The Principal Principle**. One's credence in $p$ conditional
on the hypothesis that the chance of $p$ is $x$ should be $x$.
:::

We may add info after the label. Either a simple citation or 
something in brackets:

::: statement
**(PP) The Principal Principle**. (due to Lewis) One's credence in $p$ 
conditional on the hypothesis that the chance of 
$p$ is $x$ should be $x$.
:::

Note that automatic ID conflicts are avoided: the second PP statement
above is [identified as `PP-1`](#PP-1). 

Info can also be added without label:

::: statement
(due to Lewis) One's credence in $p$ 
conditional on the hypothesis that the chance of 
$p$ is $x$ should be $x$.
:::

Labels can contain UTF-8 chars and symbols. These are replaced by 
`_` and the letters are turned to lower-case:

::: statement
**Poincaré's conjecture**. Every simply connected, closed, three-dimensional manifold is topologically equivalent to $S^3$.
:::

