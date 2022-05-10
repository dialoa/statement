---
title: Cross-references with the statement filter
author: Julien Dutant
numbersections: true # LaTeX only, in HTML use -N or --number-sections
linkcolor: blue
link-citations: true
statement:
    count-within: section
abstract: Demonstrates cross-references with
    the statement filter. Filler text is used to
    make sure the links point to the theorem
    rather than a section heading. Theorems
    are counted within section to demonstrate
    numbered crosslabels.
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
- type: article-journal
  id: theother
  author:
  - family: Otherdummy
    given: A.N.
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

# Crossreference targets

Theorem. {#thm1}
: First statement to be crossreferenced.

Theorem. {#thm2}
: Second statement to be crossreferenced. Same kind as the first,
: to test prefix aggregation.

Theorem. {#thm3}
: Third statement to be crossreferenced. Same kind as the first,
: to test list aggregation ('1-3').

Lemma. {#lem4}
: Fourth statement, of a different kind, to check that 
  crossreferences with different prefix aren't aggregated.

::: theorem
**The Old Theorem**. This theorem has a custom label, not acronym.
It can be referenced by its label.
:::

::: statement
**A Familiar Principle.** This statement has a custom label, it can
be referred to by its label. 
:::

::: statement
**(NP) The New Principle.** This statement has a custom label and 
acronym, it can be crossreferenced by its acronym. 
:::

## Citation syntax

Simple citations in AuthorInText and NormalCitation styles,
aggregated when possible.

- `@thm1`: @thm1
- `@thm1 [@thm2]`: @thm1 [@thm2]
- `@thm1 [@thm2;@thm3]`: @thm1 [@thm2;@thm3]
- `@thm1 [@thm3;@thm2]`: @thm1 [@thm3;@thm2]
- `[@thm1;@thm2;@thm3]`: [@thm1;@thm2;@thm3]
- `[@thm1;@thm3;@thm2]`: [@thm1;@thm3;@thm2]
- `[@thm2;@thm3;@lem4]`: [@thm2;@thm3;@lem4]
- `[@thm3;@lem4;@thm2]`: [@thm3;@lem4;@thm2]

Citation references with automatic prefixes.

- `[@pre:thm1]`: [@pre:thm1]
- `[@Pres:thm1;@pre:thm2;@pre:thm3]`: [@Pres:thm1;@pre:thm2;@pre:thm3]
- `[@Pres:thm2;@pre:thm3;@pre:lem4]`: [[@Pres:thm2;@pre:thm3;@pre:lem4]
- `[@Pre:thm1;@thm2;@pre:thm3]`: [@Pre:thm1;@thm2;@pre:thm3]

Citations references with user-provided prefixes and suffixes, 
plus automatic ones. 

Citing automatically generated identifiers:

- `[@the-old-theorem; @NP; @the-familiar-principle]`:
  [@the-old-theorem; @NP; @a-familiar-principle]. The former is in 
  normal font because its base kind (theorem) doesn't specify a 
  crossref font. The second is in small caps because its kind 
  (statement) does.
- `[@NP]`: statement with acronyms, the acronym is used as 
  crossreference label. Note that acronym keys are case-sensitive: @np
  fails.
- `[@the-old-theorem]`: [@the-old-theorem] normal font, because its
  base 
- `[@pre:the-old-theorem; @pre:NP]`:
  [@pre:the-old-theorem; @pre:NP]. Automatic prefixes with custom
  labelled theorems is not recommended!
- With user prefixes and automatic prefix: [see @pre:the-old-theorem],
  [see @pre:a-familiar-principle above].
 
Adding prefixes and suffixes, possibly with automatic prefixes:

- `see @thm1 [@thm2 too]`: see @thm1 [@thm2 too].
- `[see @thm2; @lem4 above]`: [see @thm2; @lem4 above].
- `[see @thm1; @thm2; @thm3 above]`: [see @thm1; @thm2; @thm3 above].
- `[see @pre:lem4 above]`: [see @pre:lem4 above].

## Link syntax

* `[]{#thm1}`: [](#thm1)
* `[the statement]{#thm2}`: [the statement](#thm2)
* `[Theorem <>](#thm1)`: [Theorem <>](#thm1)
* `[Theorem (<>) inter alia](#thm1)`: [Theorem (<>) inter alia](#thm1)
* `[Theorem <>](#thm1 "This is a link to the first theorem")`: [Theorem <>](#thm1 "This is a link to the first theorem")

# Bug tests

## Standard citations

Standard citations still work [@thatone; @theother].

## Duplicate IDs

If a theorem's ID is a duplicate of [another element's]{#duplicate}, make sure the filter doesn't crash when we try to reference it with @duplicate
or [](#duplicate). The filter will warn, change the theorem id and process
references to this ID as pointing to the theorem. 

::: {.theorem #duplicate}
A theorem to be cross-referenced. References can precede their target, see
Theorem @the-old-theorem.
:::

## Point to the proper location

Check that [@isolated] points to the the theorem itself and not its section. 

Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Ut purus elit, vestibulum ut, placerat ac, adipiscing vitae, felis. Curabitur dictum gravida mauris. Nam arcu libero, nonummy eget, consectetuer id, vulputate a, magna. Donec vehicula augue eu neque. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Mauris ut leo. Cras viverra metus rhoncus sem. Nulla et lectus vestibulum urna fringilla ultrices. Phasellus eu tellus sit amet tortor gravida placerat. Integer sapien est, iaculis in, pretium quis, viverra ac, nunc. Praesent eget sem vel leo ultrices bibendum. Aenean faucibus. Morbi dolor nulla, malesuada eu, pulvinar at, mollis ac, nulla. Cur- abitur auctor semper nulla. Donec varius orci eget risus. Duis nibh mi, congue eu, accumsan eleifend, sagittis quis, diam. Duis eget orci sit amet orci dignissim rutrum.

Nam dui ligula, fringilla a, euismod sodales, sollicitudin vel, wisi. Morbi auctor lorem non justo. Nam lacus libero, pretium at, lobortis vitae, ultricies et, tellus. Donec aliquet, tortor sed accumsan bibendum, erat ligula aliquet magna, vitae ornare odio metus a mi. Morbi ac orci et nisl hendrerit mollis. Suspendisse ut massa. Cras nec ante. Pellentesque a nulla. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Aliquam tincidunt urna. Nulla ullamcorper vestibulum turpis. Pellentesque cursus luctus mauris.

Nulla malesuada porttitor diam. Donec felis erat, congue non, volutpat at, tincidunt tristique, libero. Vivamus viverra fermentum felis. Donec nonummy pellentesque ante. Phasellus adipiscing semper elit. Proin fermentum massa ac quam. Sed diam turpis, molestie vitae, placerat a, molestie nec, leo. Mae- cenas lacinia. Nam ipsum ligula, eleifend at, accumsan nec, suscipit a, ipsum. Morbi blandit ligula feugiat magna. Nunc eleifend consequat lorem. Sed lacinia nulla vitae enim. Pellentesque tincidunt purus vel magna. Integer non enim. Praesent euismod nunc eu purus. Donec bibendum quam in tellus. Nullam cur- sus pulvinar lectus. Donec et mi. Nam vulputate metus eu enim. Vestibulum pellentesque felis eu massa.

Theorem. {#isolated}
: This theorem is alone on its page.

Quisque ullamcorper placerat ipsum. Cras nibh. Morbi vel justo vitae lacus tincidunt ultrices. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. In hac habitasse platea dictumst. Integer tempus convallis augue. Etiam facilisis. Nunc elementum fermentum wisi. Aenean placerat. Ut imperdiet, enim sed gravida sollicitudin, felis odio placerat quam, ac pulvinar elit purus eget enim. Nunc vitae tortor. Proin tempus nibh sit amet nisl. Vivamus quis tortor vitae risus porta vehicula.

Fusce mauris. Vestibulum luctus nibh at lectus. Sed bibendum, nulla a fau- cibus semper, leo velit ultricies tellus, ac venenatis arcu wisi vel nisl. Vestibulum diam. Aliquam pellentesque, augue quis sagittis posuere, turpis lacus congue quam, in hendrerit risus eros eget felis. Maecenas eget erat in sapien mattis porttitor. Vestibulum porttitor. Nulla facilisi. Sed a turpis eu lacus commodo facilisis. Morbi fringilla, wisi in dignissim interdum, justo lectus sagittis dui, et vehicula libero dui cursus dui. Mauris tempor ligula sed lacus. Duis cursus enim ut augue. Cras ac magna. Cras nulla. Nulla egestas. Curabitur a leo. Quisque egestas wisi eget nunc. Nam feugiat lacus vel est. Curabitur consectetuer.

Suspendisse vel felis. Ut lorem lorem, interdum eu, tincidunt sit amet,
laoreet vitae, arcu. Aenean faucibus pede eu ante. Praesent enim elit, rutrum at, molestie non, nonummy vel, nisl. Ut lectus eros, malesuada sit amet, fer- mentum eu, sodales cursus, magna. Donec eu purus. Quisque vehicula, urna sed ultricies auctor, pede lorem egestas dui, et convallis elit erat sed nulla. Donec luctus. Curabitur et nunc. Aliquam dolor odio, commodo pretium, ultricies non, pharetra in, velit. Integer arcu est, nonummy in, fermentum faucibus, egestas vel, odio.

Sed commodo posuere pede. Mauris ut est. Ut quis purus. Sed ac odio. Sed vehicula hendrerit sem. Duis non odio. Morbi ut dui. Sed accumsan risus eget odio. In hac habitasse platea dictumst. Pellentesque non elit. Fusce sed justo eu urna porta tincidunt. Mauris felis odio, sollicitudin sed, volutpat a, ornare ac, erat. Morbi quis dolor. Donec pellentesque, erat ac sagittis semper, nunc dui lobortis purus, quis congue purus metus ultricies tellus. Proin et quam. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos hymenaeos. Praesent sapien turpis, fermentum vel, eleifend faucibus, vehicula eu, lacus.

# References
