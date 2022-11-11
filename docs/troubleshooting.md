---
layout: page
title: Troubleshooting
permalink: /troubleshooting/
---

* toc
{:toc}

## LaTeX issues

* The `calc` package is needed to handle statements placed
  within list (`itemize`/`enumerate` environements). The default Pandoc
  template for LaTeX loads it, but if you use a custom template instead
  its preamble should contain `\usepackage{calc}`.
