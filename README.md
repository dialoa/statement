---
title: "Statement - a Lua filter for statement support in Pandoc's markdown"
author: "Julien Dutant, Thomas Hodgson"
---

Statements are text blocks that are not quotations. They typically stand out from the surrounding text and are sometimes labelled and numbered. Examples are vignettes used in a psychology experiments, principles in a philosophy paper, arguments, mathematical theorems, proofs, exercises, and so on. In JATS XML (the XML tag suite used for scientific and academiic papers) there is a `<statement>` element to mark them up.

This project aims to provide:
* A markdown syntax for statements.
* A [Pandoc](http://pandoc.org) filter using that syntax to generate `LaTeX` and `PDF`, `html`, `JATS XML`.

The features we ultimately aim to provide include:
1. labelling statements,
2. cross-referencing statements, including with their label,
3. providing AMS-style statements (theorems, axioms, proofs, exercises, ...), and customizing them
4. ways to input statements in docx.

But this is a work in progress and we first focus on the first two features. Feedback on the proposed syntax and the code is welcome.

Usage
=====

Copy `statement.lua` in the folder of your markdown file or in your `PATH`.

```
pandoc -s --lua-filter=statement.lua source.md -o
```

Proposed syntax
=====

# Aims

* conservative (doesn't break down existing syntax)
* readable, 'markdown-y'
* graceful breakdown (in unsupported formats, without the filter)
* customizable: can be used to generated `<statement>` tags,

<table>
    <tr>
        <th>Markdown</th>
        <th>Output</th>
    </tr>
    <tr>
        <td>
```
::: statement
Everything is.
:::

::: {.statement}
Everything is.
:::
```
</td>
        <td>
::: statement
Everything is.
:::
</td>
    </tr>
    <tr>
        <td>
```
::: {.statement label="Totality"}
Everything is.
:::
```
</td>
        <td>
::: {.statement label="Totality"}
Everything is.
:::
**Totality**. Everything is.
</td>
    </tr>
    <tr>
        <td>
```
::: {.statement label="A *fine* story"}
He lived and died.
:::
```
</td>
        <td>
::: {.statement label="A *fine* story"}
He lived and died.
:::
**A *fine* story**. He lived and died.
</td>
    </tr>
    <tr>
        <td>
```
::: {.statement .theorem}
Two plus two equals four.
:::
```
</td>
        <td>
::: {.statement .theorem}
Two plus two equals four.
:::
**Theorem 1**. Two plus two equals four.
</td>
    </tr>
    <tr>
        <td>
```
::: {.statement .proposition .unnumbered}
Two plus two equals four.
:::
```
</td>
        <td>
::: {.statement .proposition .unnumbered}
Two plus two equals four.
:::
**Proposition**. Two plus two equals four
</td>
    </tr>
    <tr>
        <td>
```
::: {.statement label="Principle" #my-princ}
One thing after another.
:::

As @my-princ lays out, ...
```
</td>
        <td>
::: {.statement label="Principle" #my-princ}
One thing after another.
:::

As @my-princ lays out, ...

**Principle**. One thing after another.

As **Principle** lays out, ...
</td>
    </tr>


</table>


::::: columns
:::: column
```
::: statement
Two plus two equals four.
:::
```
:::: column
Output:

::: statement
Two plus two equals four.
:::
::::
:::::

```
::: {.statement}
Two plus two equals four.
:::
