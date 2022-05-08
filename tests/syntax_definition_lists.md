---
title: Definition list synatx with the statement filter
---

# Examples

Theorem.
: A simple theorem with definition label `Theorem`.

lem
: A simple theorem with a short prefix label `lem`.
: This definition list has several definitions.

    Some of them have multiple blocks.

:   All are included in the theorem's content.

Theorem (some info).
: This statement has only info.

Theorem some stuff that's not *bracketed*
: When the theorem name is followed by some content that's
    not marked out as custom label or info (no brackets),
    we insert it in the statement's content.

Term1
: We can insert genuine Definition Lists in the middle.
: Here `Term1` and `Term2` are defined.

Term2
: In the source they are part of a DefinitionList that
    includes the theorems above and below; the filter
    splits it. 

Theorem (some info).
: We can place a dot after the info.

Theorem. (some info)
: Or before.

Theorem (some info) \label{mytheorem}
: This label receives an identifier with the LaTeX
    `\label{...}` command.

Theorem (some info) {#another}
: This label receives an identifier with markdown
    syntax `{#another}``.

Some crossreferences: @mytheorem refers to the one identified
with `\label{...}` and @another to the one identified with
`{#...}`. @KL use an acronym to refer to the one below:

Lemma **(KL) Klein's lemma** (source)
: Perhaps we could Strong elements to create custom labels?

# Recursion test

Term3
:   This is a standard definition. Its contents are processed
    recursively in case they contain further definitions.
:   Here we include a Div-style statement:

    ::: theorem
    My embedded theorem
    :::

    It should be rendered as a theorem.

:   Pandoc doesn't create DefinitionLists within DefinitionLists
    so we don't test that.
:   But we can test Div-style statements within bullet lists
    within definitions.

    - list item
    - list item that contains a lemma
    
      ::: lemma
      My embedded lemma
      :::

    - list item

: This is the last definition of Term3.

The definition of Term 3 is complete.