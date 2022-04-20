---
statement-styles:
    plain:
        space_after_head: 3em # try to redefine `plain`
    style1:
        label: Style1 Theorem
        margin-top: 12pt
        based-on: style2
    style2:
        margin-top: 2em
        margin-bottom: 2em
        punctuation: ':'
        based-on: remark
    style5:
        margin-top: 5em
        based-on: style3 # circularity, this will generate an error but no crash
statement:
    styles:
        style3:
            margin-top: 3em
            based-on: style4
        style4:
            margin-top: 4em
            based-on: style5
statement-kinds:
    thm1:
        style: style1
        counter: thm1 # this will work, treated as 'self'
    thm2:
        style: style2
        counter: thm1
    thm3:
        style: style3
        counter: thm2 # this will throw an error, `thm2` has a shared counter
    thm4:
        style: style4
    thm5:
        style: style5
---

::: theorem
This is in `plain` style, redefined to have a large space after head.

:::

::: thm1
This is in `style1`. Not declared as based on anything, so it is
assumed to be based on `plain`. 
:::

::: thm2
This is in `style2`. It is based on `remark`. No label has been provided. We've
changed the punctuation to ':'.
:::

::: thm3
This is in `style3`.
:::

::: thm4
This is in `style4`.
:::

::: thm5
This is in `style5`.
:::



