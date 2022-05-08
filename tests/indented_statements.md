---
title: Indented statements
---

Dummy text to establish the text width: Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Ut purus elit, vestibulum ut, placerat ac, adipiscing vitae, felis. Curabitur dictum gravida mauris.

Statement.
: This is a plain statement. The default style is indented right 
    and left.

: It may run through several paragraphs.

:   * contain 
    * a list

:   ::: theorem
    or even another statement (here a theorem).
    :::

Statements can have a custom label, and acronym and some info.

Statement __My Principle__. {#pp1}
: Demonstrates a custom label. Also has a custom identifier to
    refer to it: `pp1`. 

We can then refer to @pp1.

Statement __(YP) Your Principle__.
: Demonstrates a custom label and acronym. The acronym
    will be used as crossreference key and displayed in 
    crossreferences.

We can refer to @YP.

Statement __(TP) Your Principle__. (various sources)
: Demonstrates a statement with custom label, acronym and info. 


