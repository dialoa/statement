---
title: Definition list synatx with the statement filter
---

Theorem.
: A simple theorem with definition label `Theorem`.

<!-- This separates the lists; needed for the moment. --> 

lem
: A simple theorem with a short prefix label `lem`.
: This definition list has two definitions.

  The second has two blocks.

<!-- This separates the lists; needed for the moment. --> 

Theorem (some info).
: This statement has only info.

<!-- This separates the lists; needed for the moment. --> 

Theorem some ongoing text without *structure*
: What to do with info that's not in brackets?

<!-- This separates the lists; needed for the moment. --> 

Theorem (some info).
: We can place a dot after the info.

<!-- This separates the lists; needed for the moment. --> 

Theorem. (some info)
: Or before.

<!-- This separates the lists; needed for the moment. --> 

Theorem (some info) \label{mytheorem}
: This label receives an identifier with the LaTeX
    `\label{...}` command.

<!-- This separates the lists; needed for the moment. --> 

Theorem (some info) {#another}
: This label receives an identifier with markdown
    syntax {#another}.

Some crossreferences: @mytheorem refers to the former
and @another to the latter.

Lemma **Klein's lemma** (source) \label{KL}
: Perhaps we could Strong elements to create custom labels?
