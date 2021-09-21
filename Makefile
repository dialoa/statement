DIFF ?= diff --strip-trailing-cr -u

.PHONY: test

test: test_html test_latex test_jats

tex: test_latex

test_html: sample.md statement.lua expected.html
	@pandoc --lua-filter statement.lua --standalone --to=html $< \
	    | $(DIFF) expected.html -

test_jats: sample.md statement.lua expected.xml
	@pandoc --lua-filter statement.lua --standalone --to=jats $< \
	    | $(DIFF) expected.xml -

test_latex: sample.md statement.lua expected.tex
	@pandoc --lua-filter statement.lua --standalone --to=latex $< \
	    | $(DIFF) expected.tex -

expected.xml: sample.md statement.lua
	@pandoc --lua-filter statement.lua --standalone --to=jats $< --output $@

expected.html: sample.md statement.lua
	@pandoc --lua-filter statement.lua --standalone --to=html $< --output $@

expected.tex: sample.md statement.lua
	@pandoc --lua-filter statement.lua --standalone --to=latex $< --output $@
