---
title: Newtheorem and theoremstyle test
subtitle: recreated with the Pandoc Statement filter
author: Michael Downes, updated by Barbara Beeton
numbersections: true
linkcolor: blue
link-citations: true
statement:
    count-within: section
    swap-numbers: true
statement-kinds:
    remark:
        counter: none
    proposition:
        counter: self
    note:
        style: note
        counter: self
        label: Note
    varthm:
        style: citing
        counter: none
    bthm:
        style: break
        label: B-Theorem
        counter: self
    exercise:
        style: exercise
        label: Exercise
        counter: self
statement-styles:
    exercise:
        based-on: plain
        punctuation: ':'
    note:
        margin-top: 3pt
        margin-bottom: 3pt
        body-font: normal
        head-font: italics
        punctuation: ':'
        space-after-head: .5em
    citing:
        margin-top: 3pt
        margin-bottom: 3pt
        body-font: italics
        head-font: bold
        punctuation: '.'
        space-after-head: .5em
    break:
        margin-top: 9pt
        margin-bottom: 9pt
        body-font: italics
        head-font: bold
        punctuation: '.'
        space-after-head: \newline 
references:
- type: article-journal
  id: thatone
  author:
  - family: Dummy
    given: D.
  issued:
    date-parts:
    - - 1900
      - 1
      - 1
  title: 'Dummy reference'
  container-title: Journal
  volume: 1
  issue: 1
  page: 1-10
---

# Test of standard theorem styles

Ahlfors' Lemma gives the principal criterion for obtaining lower bounds
on the Kobayashi metric.

::: lemma
**Ahlfors' Lemma**. Let $ds^2 = h(z)|dz|^2$ be a Hermitian
pseudo-metric on $\mathbf{D}_r$, $h\in C^2(\mathbf{D}_r)$, with $\omega$
the associated $(1,1)$-form. If
$\mathop{\mathrm{Ric}}\nolimits\omega\geq\omega$ on $\mathbf{D}_r$, then
$\omega\leq\omega_r$ on all of $\mathbf{D}_r$ (or equivalently,
$ds^2\leq ds_r^2$).
:::

::: lem
(negatively curved families) Let $\{ds_1^2,\dots,ds_k^2\}$
be a negatively curved family of metrics on $\mathbf{D}_r$, with
associated forms $\omega^1$, ..., $\omega^k$. Then
$\omega^i \leq\omega_r$ for all $i$.
:::

Then our main theorem:

::: {.theorem #sdq}
Let $d_{\max}$ and $d_{\min}$ be the maximum,
resp. minimum distance between any two adjacent vertices of a
quadrilateral $Q$. Let $\sigma$ be the diagonal pigspan of a pig $P$
with four legs. Then $P$ is capable of standing on the corners of $Q$
iff $$\label{sdq}
\sigma\geq \sqrt{d_{\max}^2+d_{\min}^2}.$$
:::

::: corollary
Admitting reflection and rotation, a three-legged pig
$P$ is capable of standing on the corners of a triangle $T$ iff
@sdq holds.
:::

::: {.remark .unnumbered}
As two-legged pigs generally fall over, the case of a
polygon of order $2$ is uninteresting.
:::

# Custom theorem styles

::: exercise
Generalize Theorem @sdq to three and four dimensions.
:::

::: note
This is a test of the custom theorem style `note`. It is
supposed to have variant fonts and other differences.
:::

::: bthm
Test of the 'linebreak' style of theorem heading.
:::

This is a test of a citing theorem to cite a theorem from some other
source.

::: varthm
(Theorem 3.6 in @thatone). No hyperlinking available here yet 
but that's not a bad idea for the future.
:::

# The proof environment

::: proof
Here is a test of the proof environment.
:::

::: proof
(Proof of Theorem @sdq) And another test.
:::

::: proof
(Proof of *necessity*) And another.
:::

::: proof
(Proof of *sufficiency*)  And another, ending with
a display: $$1+1=2\,. \qedhere$$
:::

# References