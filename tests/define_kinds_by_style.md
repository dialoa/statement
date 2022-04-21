---
title: Statements by kind
author: Julien Dutant
subtitle: Define statement kinds by their style
			with the Statement filter
abstract: In this document statement kinds are defined
	in lists, one per style. This works with predefined
	styles (`plain`, `remark`, `definition`) as well
	as user-defined ones (`mystyle`).
statement:
	plain:
	- My First Kind
	- My Second Kind
	definition: [Explanation, Elaboration]
	remark: Digression
	mystyle: My Custom Kind
    plain-unnumbered: [Aside, 'Little Known Fact']
statement-styles:
	mystyle:
		based-on: plain
		space-after-head: 3em
        margin-left: 1em
        margin-right: 1em
---

My_First_Kind.
: This is a statement of the first kind. Note that if our
  kind label has spaces or special chars, I must replace
  them with '_'.

My_Second_Kind.
: This is a statement of the second kind.

My_Custom_Kind.
: This is a statement of my custom kind, in the new `mystyle` style.

Explanation.
: This is a statement of the Explanation kind, `definition` style.

Elaboration.
: This is a statement of the Elaboration kind, `definition` style.

Digression.
: This is a statement of the Elaboration kind, `remark` style.

Aside.
: This statement is based on `plain`, but unnumbered.

Little_Known_Fact.
: This statement is based on `plain` and unnumbered.