---
title: Lists in theorems with the Statement filter
abstract: This tests how the Statement handles
	lists within theorems. These sometimes create
	formatting issues for the AMS theorems package
	in LaTeX.
---

::: thm
* first item
* second item

A theorem with a bullet list.
:::

::: thm
1. first item
2. second item.

A theorem with an ordered list.
:::

::: thm
(this theorem has some info too)

* first item
* second item
:::

::: thm
**Custom labelled theorem** (with info)

* first item
* second item
:::

The following is a statement without label:

::: statement
* This statement should *not* start with
* a `\newline` because it has no label
:::

::: proof
* first item
* second item

Bullet list within proof.
:::

::: proof
1. first item
2. second item

Numbered list within proof.
:::

::: proof
1. This proofs ends with
2. the list's last item.
:::

::: thm
(Definition lists within theorems)

This theorem
: illustrates a DefinitionList within a theorem.
: The first item has two definitions.

The second item
: has only one definition.
:::