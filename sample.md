---
title: A sample document for the statement filter
statement:
  header: true
indent: true
---


A simple statement. [Here is some dummy text to show the normal
line length of a text paragraph in LaTeX.] Should be empty style:

::: statement
This material is indented left and right. To see this we add a very long line that will need to be broken at some point or other.

The second paragraph has a first line indent.
:::

A statement of the kind `corollary`, which is defined in the defaults.

::: {.statement .corollary}

This is a corollary. The kind is defined by default.

:::

A statement of the kind `principle`, which has to be created on the fly.

::: {.statement kind="Principle" title="Quine's principle"}

Everything is something.

:::

A stament in the argument style, with an horizontal line in the statement:

::: argument
All is one.

One is less.

---

All is less.
:::

In LaTeX, statements that begin a list item normally create an empty line.
We avoid this by putting them into a minipage.

* ::: statement
  This starts a statement. To check the right indent we add a very long line that will need to be broken at some point or other. To check the right indent we add a very long line that will need to be broken at some point or other.
  To check the right indent we add a very long line that will need to be broken at some point or other.

  Statements second paragraphs are indented.
  :::

  This is more text in the item.

  And even more text.
* This item has normal text

  ::: statement
  Followed by a statement. To check the right indent we add a very long line that will need to be broken at some point or other. To check the right indent we add a very long line that will need to be broken at some point or other.
  To check the right indent we add a very long line that will need to be broken at some point or other.
  :::

  and more normal text.

* ::: argument
  This starts and argument

  ---

  Argument paragraphs aren't indented.
  :::

  This is more text in the item.


This list is a control to check that lists without statements are left
without changes:

1) ::: dummy
    Some random text in a Div
   :::
2) Another list entry
3) ::: dummy
  more text in a Div
   :::


