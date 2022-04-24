---
title: Linebreak style in Statement
abstract: Tests various ways of defining a theorem
	style with a linebreak after the theorem's head.
statement-styles:
	break1: 
		based_on: plain
		space_after_head: '\n'
	break2: 
		based_on: plain
		space_after_head: \n
	break3: 
		based_on: plain
		space_after_head: \newline
statement:
	break1: B1-Theorem
	break2: B2-Theorem
	break3: B3-Theorem
---

B1-Theorem.
: test

B2-Theorem.
: test

B3-Theorem.
: test

::: B1-Theorem
* list
* test
:::

::: B2-Theorem
* list
* test
:::
