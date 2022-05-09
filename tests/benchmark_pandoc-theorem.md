---
title: Statement and Pandoc-theorem benchmark
abstract: Document used to measure the performance
    of the Statement filter against that of
    [pandoc-theorem](https://github.com/sliminality/pandoc-theorem).
    Based on pandoc-theorem's kitchen sink document. 
header-includes: |
    ```{=latex}
    \usepackage{amsthm}
    \newtheorem{claim}{Claim}
    \newtheorem{definition}{Definition}
    \newtheorem{lemma}{Lemma}
    \newtheorem{theorem}{Theorem}
    \newtheorem{example}{Example}
    \newtheorem{assumption}{Assumption}
    ```
statement:
    supply_header: no
---

Example results:

* `pandoc-theorem` unknown; as of may 2022 the  
  [release](https://github.com/sliminality/pandoc-theorem/releases) I found
  only ran with pandoc 2.7, which doesn't show filter processing times.
* `statement`: 71ms

To generate a PDF with `pandoc-amsthm` for this document,
add the following to the document's YAML metadata. 

````` yaml
header-includes: |
    ```{=latex}
    \usepackage{amsthm}
    \newtheorem{claim}{Claim}
    \newtheorem{definition}{Definition}
    \newtheorem{lemma}{Lemma}
    \newtheorem{theorem}{Theorem}
    \newtheorem{example}{Example}
    \newtheorem{assumption}{Assumption}
    ```
`````

## Simple block-level theorem

Theorem (Hedberg).

:   Any type with decidable equality is a set.

## Complex block-level theorem

Lemma (Pumping Lemming). \label{lem1}

:   Let $L$ be a regular language. Then there exists an integer $p \geq 1$ called the "pumping length" which depends only on $L$, such that every string $w \in L$ of length at least $p$ can be divided into three substrings $w = xyz$ such that the following conditions hold:

    - $|y| \geq 1$
    - $|xy| \leq p$
    - $xy^n z \in L$, for all $n \geq 0$.

    That is, the non-empty substring $y$ occurring within the first $p$ characters of $w$ can be "pumped" any number of times, and the resulting string is always in $L$.

## Single inline theorem

Proof. 
: By induction on the structure of the typing judgment.

## Multiple inline theorems

Def (Agda).
:   A dependently-typed programming language often used for interactive theorem proving.
:   A video game that doesn't mean you understand the underlying theory, according to Bob.

## Regular definition lists still work

Groceries
: Bananas
: Lenses
: Barbed wire

Programming language checklist

:     *Strictures:* Does the language have sufficiently many restrictions? It is always easier to relax strictures later on.

:     *Affordances:* Actually, these don't really matter.

## Simple block-level theorem

Theorem (Hedberg).

:   Any type with decidable equality is a set.

## Complex block-level theorem

Lemma (Pumping Lemming). \label{lem2}

:   Let $L$ be a regular language. Then there exists an integer $p \geq 1$ called the "pumping length" which depends only on $L$, such that every string $w \in L$ of length at least $p$ can be divided into three substrings $w = xyz$ such that the following conditions hold:

    - $|y| \geq 1$
    - $|xy| \leq p$
    - $xy^n z \in L$, for all $n \geq 0$.

    That is, the non-empty substring $y$ occurring within the first $p$ characters of $w$ can be "pumped" any number of times, and the resulting string is always in $L$.

## Single inline theorem

Proof. 
: By induction on the structure of the typing judgment.

## Multiple inline theorems

Def (Agda).
:   A dependently-typed programming language often used for interactive theorem proving.
:   A video game that doesn't mean you understand the underlying theory, according to Bob.

## Regular definition lists still work

Groceries
: Bananas
: Lenses
: Barbed wire

Programming language checklist

:     *Strictures:* Does the language have sufficiently many restrictions? It is always easier to relax strictures later on.

:     *Affordances:* Actually, these don't really matter.

## Simple block-level theorem

Theorem (Hedberg).

:   Any type with decidable equality is a set.

## Complex block-level theorem

Lemma (Pumping Lemming). \label{lem3}

:   Let $L$ be a regular language. Then there exists an integer $p \geq 1$ called the "pumping length" which depends only on $L$, such that every string $w \in L$ of length at least $p$ can be divided into three substrings $w = xyz$ such that the following conditions hold:

    - $|y| \geq 1$
    - $|xy| \leq p$
    - $xy^n z \in L$, for all $n \geq 0$.

    That is, the non-empty substring $y$ occurring within the first $p$ characters of $w$ can be "pumped" any number of times, and the resulting string is always in $L$.

## Single inline theorem

Proof. 
: By induction on the structure of the typing judgment.

## Multiple inline theorems

Def (Agda).
:   A dependently-typed programming language often used for interactive theorem proving.
:   A video game that doesn't mean you understand the underlying theory, according to Bob.

## Regular definition lists still work

Groceries
: Bananas
: Lenses
: Barbed wire

Programming language checklist

:     *Strictures:* Does the language have sufficiently many restrictions? It is always easier to relax strictures later on.

:     *Affordances:* Actually, these don't really matter.

## Simple block-level theorem

Theorem (Hedberg).

:   Any type with decidable equality is a set.

## Complex block-level theorem

Lemma (Pumping Lemming). \label{lem4}

:   Let $L$ be a regular language. Then there exists an integer $p \geq 1$ called the "pumping length" which depends only on $L$, such that every string $w \in L$ of length at least $p$ can be divided into three substrings $w = xyz$ such that the following conditions hold:

    - $|y| \geq 1$
    - $|xy| \leq p$
    - $xy^n z \in L$, for all $n \geq 0$.

    That is, the non-empty substring $y$ occurring within the first $p$ characters of $w$ can be "pumped" any number of times, and the resulting string is always in $L$.

## Single inline theorem

Proof. 
: By induction on the structure of the typing judgment.

## Multiple inline theorems

Def (Agda).
:   A dependently-typed programming language often used for interactive theorem proving.
:   A video game that doesn't mean you understand the underlying theory, according to Bob.

## Regular definition lists still work

Groceries
: Bananas
: Lenses
: Barbed wire

Programming language checklist

:     *Strictures:* Does the language have sufficiently many restrictions? It is always easier to relax strictures later on.

:     *Affordances:* Actually, these don't really matter.

## Simple block-level theorem

Theorem (Hedberg).

:   Any type with decidable equality is a set.

## Complex block-level theorem

Lemma (Pumping Lemming). \label{lem5}

:   Let $L$ be a regular language. Then there exists an integer $p \geq 1$ called the "pumping length" which depends only on $L$, such that every string $w \in L$ of length at least $p$ can be divided into three substrings $w = xyz$ such that the following conditions hold:

    - $|y| \geq 1$
    - $|xy| \leq p$
    - $xy^n z \in L$, for all $n \geq 0$.

    That is, the non-empty substring $y$ occurring within the first $p$ characters of $w$ can be "pumped" any number of times, and the resulting string is always in $L$.

## Single inline theorem

Proof. 
: By induction on the structure of the typing judgment.

## Multiple inline theorems

Def (Agda).
:   A dependently-typed programming language often used for interactive theorem proving.
:   A video game that doesn't mean you understand the underlying theory, according to Bob.

## Regular definition lists still work

Groceries
: Bananas
: Lenses
: Barbed wire

Programming language checklist

:     *Strictures:* Does the language have sufficiently many restrictions? It is always easier to relax strictures later on.

:     *Affordances:* Actually, these don't really matter.

## Simple block-level theorem

Theorem (Hedberg).

:   Any type with decidable equality is a set.

## Complex block-level theorem

Lemma (Pumping Lemming). \label{lem6}

:   Let $L$ be a regular language. Then there exists an integer $p \geq 1$ called the "pumping length" which depends only on $L$, such that every string $w \in L$ of length at least $p$ can be divided into three substrings $w = xyz$ such that the following conditions hold:

    - $|y| \geq 1$
    - $|xy| \leq p$
    - $xy^n z \in L$, for all $n \geq 0$.

    That is, the non-empty substring $y$ occurring within the first $p$ characters of $w$ can be "pumped" any number of times, and the resulting string is always in $L$.

## Single inline theorem

Proof. 
: By induction on the structure of the typing judgment.

## Multiple inline theorems

Def (Agda).
:   A dependently-typed programming language often used for interactive theorem proving.
:   A video game that doesn't mean you understand the underlying theory, according to Bob.

## Regular definition lists still work

Groceries
: Bananas
: Lenses
: Barbed wire

Programming language checklist

:     *Strictures:* Does the language have sufficiently many restrictions? It is always easier to relax strictures later on.

:     *Affordances:* Actually, these don't really matter.

## Simple block-level theorem

Theorem (Hedberg).

:   Any type with decidable equality is a set.

## Complex block-level theorem

Lemma (Pumping Lemming). \label{lem7}

:   Let $L$ be a regular language. Then there exists an integer $p \geq 1$ called the "pumping length" which depends only on $L$, such that every string $w \in L$ of length at least $p$ can be divided into three substrings $w = xyz$ such that the following conditions hold:

    - $|y| \geq 1$
    - $|xy| \leq p$
    - $xy^n z \in L$, for all $n \geq 0$.

    That is, the non-empty substring $y$ occurring within the first $p$ characters of $w$ can be "pumped" any number of times, and the resulting string is always in $L$.

## Single inline theorem

Proof. 
: By induction on the structure of the typing judgment.

## Multiple inline theorems

Def (Agda).
:   A dependently-typed programming language often used for interactive theorem proving.
:   A video game that doesn't mean you understand the underlying theory, according to Bob.

## Regular definition lists still work

Groceries
: Bananas
: Lenses
: Barbed wire

Programming language checklist

:     *Strictures:* Does the language have sufficiently many restrictions? It is always easier to relax strictures later on.

:     *Affordances:* Actually, these don't really matter.

## Simple block-level theorem

Theorem (Hedberg).

:   Any type with decidable equality is a set.

## Complex block-level theorem

Lemma (Pumping Lemming). \label{lem8}

:   Let $L$ be a regular language. Then there exists an integer $p \geq 1$ called the "pumping length" which depends only on $L$, such that every string $w \in L$ of length at least $p$ can be divided into three substrings $w = xyz$ such that the following conditions hold:

    - $|y| \geq 1$
    - $|xy| \leq p$
    - $xy^n z \in L$, for all $n \geq 0$.

    That is, the non-empty substring $y$ occurring within the first $p$ characters of $w$ can be "pumped" any number of times, and the resulting string is always in $L$.

## Single inline theorem

Proof. 
: By induction on the structure of the typing judgment.

## Multiple inline theorems

Def (Agda).
:   A dependently-typed programming language often used for interactive theorem proving.
:   A video game that doesn't mean you understand the underlying theory, according to Bob.

## Regular definition lists still work

Groceries
: Bananas
: Lenses
: Barbed wire

Programming language checklist

:     *Strictures:* Does the language have sufficiently many restrictions? It is always easier to relax strictures later on.

:     *Affordances:* Actually, these don't really matter.

## Simple block-level theorem

Theorem (Hedberg).

:   Any type with decidable equality is a set.

## Complex block-level theorem

Lemma (Pumping Lemming). \label{lem9}

:   Let $L$ be a regular language. Then there exists an integer $p \geq 1$ called the "pumping length" which depends only on $L$, such that every string $w \in L$ of length at least $p$ can be divided into three substrings $w = xyz$ such that the following conditions hold:

    - $|y| \geq 1$
    - $|xy| \leq p$
    - $xy^n z \in L$, for all $n \geq 0$.

    That is, the non-empty substring $y$ occurring within the first $p$ characters of $w$ can be "pumped" any number of times, and the resulting string is always in $L$.

## Single inline theorem

Proof. 
: By induction on the structure of the typing judgment.

## Multiple inline theorems

Def (Agda).
:   A dependently-typed programming language often used for interactive theorem proving.
:   A video game that doesn't mean you understand the underlying theory, according to Bob.

## Regular definition lists still work

Groceries
: Bananas
: Lenses
: Barbed wire

Programming language checklist

:     *Strictures:* Does the language have sufficiently many restrictions? It is always easier to relax strictures later on.

:     *Affordances:* Actually, these don't really matter.

## Simple block-level theorem

Theorem (Hedberg).

:   Any type with decidable equality is a set.

## Complex block-level theorem

Lemma (Pumping Lemming). \label{lem10}

:   Let $L$ be a regular language. Then there exists an integer $p \geq 1$ called the "pumping length" which depends only on $L$, such that every string $w \in L$ of length at least $p$ can be divided into three substrings $w = xyz$ such that the following conditions hold:

    - $|y| \geq 1$
    - $|xy| \leq p$
    - $xy^n z \in L$, for all $n \geq 0$.

    That is, the non-empty substring $y$ occurring within the first $p$ characters of $w$ can be "pumped" any number of times, and the resulting string is always in $L$.

## Single inline theorem

Proof. 
: By induction on the structure of the typing judgment.

## Multiple inline theorems

Def (Agda).
:   A dependently-typed programming language often used for interactive theorem proving.
:   A video game that doesn't mean you understand the underlying theory, according to Bob.

## Regular definition lists still work

Groceries
: Bananas
: Lenses
: Barbed wire

Programming language checklist

:     *Strictures:* Does the language have sufficiently many restrictions? It is always easier to relax strictures later on.

:     *Affordances:* Actually, these don't really matter.

## Simple block-level theorem

Theorem (Hedberg).

:   Any type with decidable equality is a set.

## Complex block-level theorem

Lemma (Pumping Lemming). \label{lem}

:   Let $L$ be a regular language. Then there exists an integer $p \geq 1$ called the "pumping length" which depends only on $L$, such that every string $w \in L$ of length at least $p$ can be divided into three substrings $w = xyz$ such that the following conditions hold:

    - $|y| \geq 1$
    - $|xy| \leq p$
    - $xy^n z \in L$, for all $n \geq 0$.

    That is, the non-empty substring $y$ occurring within the first $p$ characters of $w$ can be "pumped" any number of times, and the resulting string is always in $L$.

## Single inline theorem

Proof. 
: By induction on the structure of the typing judgment.

## Multiple inline theorems

Def (Agda).
:   A dependently-typed programming language often used for interactive theorem proving.
:   A video game that doesn't mean you understand the underlying theory, according to Bob.

## Regular definition lists still work

Groceries
: Bananas
: Lenses
: Barbed wire

Programming language checklist

:     *Strictures:* Does the language have sufficiently many restrictions? It is always easier to relax strictures later on.

:     *Affordances:* Actually, these don't really matter.
