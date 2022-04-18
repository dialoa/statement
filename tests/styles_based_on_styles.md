---
statement-styles:
    style1:
        margin_top: 12pt
        based_on: style2
    style2:
        margin_top: 2em
        margin_bottom: 2em
        based_on: remark
    style5:
        margin_top: 5em
        based_on: style3 # circularity, this will generate an error but no crash
statement:
    styles:
        style3:
            margin_top: 3em
            based_on: style4
        style4:
            margin_top: 4em
            based_on: style5
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

::: thm1
This is in `style1`.
:::

::: thm2
This is in `style2`.
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



