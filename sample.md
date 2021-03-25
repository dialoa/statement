---
title: A sample document for the statement filter
statement:
  header: true
---

An simple statement. Should be empty style:

::: statement
This material is normally indented.
:::

A statement of the kind `corollary`, which is defined in the defaults.

::: {.statement kind="Corollary"}

This is a corollary. The kind is defined by default.

:::

A statement of the kind `principle`, which has to be created on the fly.

::: {.statement kind="Principle" title="Quine's principle"}

Everything is something.

:::

An horizontal line within a statement:

::: statement
All is one.

One is less.

---

All is less.
:::

