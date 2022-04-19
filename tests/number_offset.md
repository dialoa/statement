---
title: Testing counters
abstract: If this document is set to a book class, 
    or if Pandoc's  `--top-level-division` 
    is set to `chapter`,
    the theorem counter is attached to level 2 
    headings rather than level 1 ones. 
    In HTML output, the numbers are offset with
    Pandoc's `--number-offset` writer option. 
statement-kinds:
    theorem:
        counter: section
    proposition:
        counter: subsection
    lemma:
        counter: subsubsection
---

# Level 1

## Level 2

### Level 3

::: thm
Theorems are counted with sections.
:::

::: prop
Theorems are counted with subsections.
:::

::: lem
Test of this statement's counter.
:::

### Level 3

::: thm
Test of this statement's counter.
:::

::: prop
Test of this statement's counter.
:::

::: lem
Test of this statement's counter.
:::

## Level 2

### Level 3

::: thm
Test of this statement's counter.
:::

::: prop
Test of this statement's counter.
:::

::: lem
Test of this statement's counter.
:::

### Level 3

::: thm
Test of this statement's counter.
:::

::: prop
Test of this statement's counter.
:::

::: lem
Test of this statement's counter.
:::

# Level 1

## Level 2

### Level 3

::: thm
Theorems are counted with sections.
:::

::: prop
Theorems are counted with subsections.
:::

::: lem
Test of this statement's counter.
:::

### Level 3

::: thm
Test of this statement's counter.
:::

::: prop
Test of this statement's counter.
:::

::: lem
Test of this statement's counter.
:::

## Level 2

### Level 3

::: thm
Test of this statement's counter.
:::

::: prop
Test of this statement's counter.
:::

::: lem
Test of this statement's counter.
:::

### Level 3

::: thm
Test of this statement's counter.
:::

::: prop
Test of this statement's counter.
:::

::: lem
Test of this statement's counter.
:::
