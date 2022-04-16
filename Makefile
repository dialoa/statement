DIFF ?= diff --strip-trailing-cr -u
INFO = quiet # use make INFO=verbose to get Pandoc verbose output
SRC_FILES = $(wildcard src/*.lua)

.PHONY: statement.lua

statement.lua: $(SRC_FILES) lua-builder/lua-builder.lua
	@lua lua-builder/lua-builder.lua src/main.lua -o statement.lua --verbose --recursive

# keeping the all makefile code for the diff test

tex: sample.md statement.lua expected.tex
	@pandoc --lua-filter statement.lua -s --$(INFO) --to=latex \
		--natbib $< \
	    | $(DIFF) expected.tex -

expected.tex: sample.md statement.lua
	@pandoc --lua-filter statement.lua -s --$(INFO) --to=latex \
		--natbib $< \
		--output $@
