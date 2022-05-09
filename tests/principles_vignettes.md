---
title: Principles and vignettes with the 
    Statement filter
abstract: Demonstrates two markdown syntaxes
  for principles or vignettes with optional label, 
  acronym and info, and for crossreferencing them.
linkcolor: blue
link-citations: true
statement-styles:
  break:
    based-on: empty
    space-after-head: '\n'
    punctuation: ''
    custom-label-changes: 
        punctuation: ''
statement-kinds:
  statement-break:
    based-on: statement
    style: break
---

# Div syntax

The statements in this section are entered in markdown using the
Div syntax. (We'll continue the text a bit to establish the
text width.)

::: statement

This statement will be rendered as simple indented text. Curabitur dictum gravida mauris. Nam arcu libero, nonummy eget, consectetuer id, vulputate a, magna. 

* It contains two paragraphs
* and a list.

Donec vehicula augue eu neque. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Mauris ut leo.

:::

The statement below has a custom label. The label is automatically
turned into an ID that can be used to 
[reference it](#the-principal-principle).

::: statement
**The Principal Principle**. One's credence in $p$ conditional
on the hypothesis that the chance of $p$ is $x$ should be $x$.
:::

The statement below is in a custom style in which the label
is followed by a linebreak:

::: statement-break
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

Info can also be added without label. In LaTeX/PDF output the 
AMSThm package doesn't handle this well. 

::: statement
(due to Lewis) One's credence in $p$ conditional on the hypothesis
that the chance of $p$ is $x$ should be $x$.
:::

Labels can contain UTF-8 chars and symbols. These are replaced by 
`_` and the letters are turned to lower-case:

::: statement
**Poincaré's conjecture**. Every simply connected, closed, three-dimensional manifold is topologically equivalent to $S^3$.
:::

# Definition List syntax

The second part replicates the first, except that in markdown the 
statements are now entered with the DefinitionList syntax. Identifier
conflicts are avoided automatically or by using custom identifiers.

Statement
: This statement will be rendered as simple indented text. Curabitur dictum gravida mauris. Nam arcu libero, nonummy eget, consectetuer id, vulputate a, magna. 

:   * It contains two paragraphs
    * and a list.

: Donec vehicula augue eu neque. Pellentesque habitant morbi tristique 
    senectus et netus et malesuada fames ac turpis egestas. Mauris ut leo.

The statement below has a custom label. The label is automatically
turned into an ID that can be used to 
[reference it](#the-principal-principle-2). 

Statement __The Principal Principe__. 
: One's credence in $p$ conditional on the hypothesis that the 
    chance of $p$ is $x$ should be $x$.

The statement below is in a custom style in which the label
is followed by a linebreak:

Statement-break __The Principal Principe__. 
: One's credence in $p$ conditional on the hypothesis that the 
    chance of $p$ is $x$ should be $x$.

Acronyms can be specified too, at the beginning of the custom
label. This time we specify a ID individually, so we can refer to @myid.

Statement **(PP) The Principal Principle**. {#myid}
:   One's credence in $p$ conditional
    on the hypothesis that the chance of $p$ is $x$ should be $x$.

We may add info after the label. Either a simple citation or 
something in brackets:

Statement __(PP) The Principal Principle__. (due to Lewis) 
:   One's credence in $p$ conditional
    on the hypothesis that the chance of $p$ is $x$ should be $x$.

Again that automatic ID conflicts are avoided: this link ([](#PP-2))
will point to the one above. 

Info can also be added without label:

Statement. (due to Lewis) 
:   One's credence in $p$ conditional on the hypothesis
    that the chance of $p$ is $x$ should be $x$.

Labels can contain UTF-8 chars and symbols. These are replaced by 
`_` and the letters are turned to lower-case:

Statement **Poincaré's conjecture**. 
:   Every simply connected, closed, three-dimensional manifold is topologically 
    equivalent to $S^3$.



