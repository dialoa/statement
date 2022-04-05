DIFF ?= diff --strip-trailing-cr -u
INFO = quiet
SRC_FILES = $(wildcard src/*.lua)

.PHONY: test

all: tex jats html docx

pdf: expected.pdf

tex: sample.md statement.lua expected.tex
	@pandoc --lua-filter statement.lua -s --$(INFO) --to=latex \
		--natbib $< \
	    | $(DIFF) expected.tex -

html: sample.md statement.lua expected.html
	@pandoc --lua-filter statement.lua -s --$(INFO) --to=html $< \
	    | $(DIFF) expected.html -

jats: sample.md statement.lua expected.xml
	@pandoc --lua-filter statement.lua -s --$(INFO) --to=jats $< \
	    | $(DIFF) expected.xml -

docx: sample.md statement.lua expected.docx
	@pandoc --lua-filter statement.lua -s --$(INFO) --to=docx $< \
	    | $(DIFF) expected.xml -

expected.pdf: sample.md statement.lua
	@pandoc --lua-filter statement.lua -s --$(INFO) --to=pdf \
		--natbib $< \
		--output $@

expected.tex: sample.md statement.lua
	@pandoc --lua-filter statement.lua -s --$(INFO) --to=latex \
		--natbib $< \
		--output $@

expected.xml: sample.md statement.lua
	@pandoc --lua-filter statement.lua -s --$(INFO) --to=jats $< --output $@

expected.html: sample.md statement.lua
	@pandoc --lua-filter statement.lua -s --$(INFO) --to=html $< --output $@

expected.docx: sample.md statement.lua
	@pandoc --lua-filter statement.lua -s --$(INFO) --to=docx $< --output $@

statement.lua: $(SRC_FILES) lua-builder/lua-builder.lua
	@lua lua-builder/lua-builder.lua src/main.lua -o statement.lua --verbose