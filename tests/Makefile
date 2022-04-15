ROOT = ../# repository's root
INFO = quiet # use make INFO=verbose to get Pandoc verbose output
SRC_FILES = $(wildcard $(ROOT)src/*.lua)
TEST_FILES = $(wildcard *.md)

.PHONY: 

$(ROOT)statement.lua: $(SRC_FILES) $(ROOT)lua-builder/lua-builder.lua
	@lua $(ROOT)lua-builder/lua-builder.lua $(ROOT)src/main.lua \
		-o $(ROOT)statement.lua --verbose --recursive

%.tex: %.md $(ROOT)statement.lua
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		-C --to=latex --output $@

%.pdf: %.md $(ROOT)statement.lua
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		-C --to=pdf --output $@

%.html: %.md $(ROOT)statement.lua
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		-C --to=html --output $@

%.xml: %.md $(ROOT)statement.lua
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		-C --to=jats --output $@

%.docx: %.md $(ROOT)statement.lua
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		-C --to=docx --output $@
