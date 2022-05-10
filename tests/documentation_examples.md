---
title: Source for Statement documentation examples.
abstract: Use this to regenerate the documentation's images.
numbersections: true # LaTeX only, in HTML use -N or --number-sections
linkcolor: blue
---

Theorem. (from Spivak 1967) {#fthc}
: Let $f$ be integrable on $[a,b]$, and define $F$ on $[a,b]$ by

    $$F(x) = \int_a^x f.$$

    If $f$ is continuous at $c$ in $[a,b]$ then $F$ is differentiable
    at $c$, and

    $$F'(c) = f(c).$$

    (If $c = a$ or $b$, then $F'(c)$ is understood to mean the right-
    or left-hand derivative of $F$.)

@Pre:fthc is known as the fundamental theorem of calculus.

::: theorem
(Pythagoras) The sum of angles in a triangle is equal to 
two right angles.
:::

::: {.theorem #quadratic}
The solutions of a quadratric equation $ax^2 + bx + c$ 
are given by: 
$$x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$
:::

::: corollary
A quadratic equation $ax^2 + bx + c$ has two real solutions 
if and only if $b^2 - 4ac > 0$.
:::

::: proof
Obvious from @quadratic.
:::
