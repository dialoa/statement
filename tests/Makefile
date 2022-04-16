ROOT = ../# repository's root
INFO = quiet # use make INFO=verbose to get Pandoc verbose output
SRC_FILES = $(wildcard $(ROOT)src/*.lua)
TEST_FILES = $(wildcard *.md)
LATEX_TARGETS = $(patsubst %.md,%.tex,$(TEST_FILES))
PDF_TARGETS = $(patsubst %.md,%.pdf,$(TEST_FILES))
HTML_TARGETS = $(patsubst %.md,%.html,$(TEST_FILES))
JATS_TARGETS = $(patsubst %.md,%.xml,$(TEST_FILES))
DOCX_TARGETS = $(patsubst %.md,%.docx,$(TEST_FILES))

.PHONY:

$(ROOT)statement.lua: $(SRC_FILES) $(ROOT)lua-builder/lua-builder.lua
	@lua $(ROOT)lua-builder/lua-builder.lua $(ROOT)src/main.lua \
		-o $(ROOT)statement.lua --verbose --recursive

all: allbutpdf pdf

allbutpdf: tex html jats docx

tex: $(LATEX_TARGETS)

pdf: $(PDF_TARGETS)

html: $(HTML_TARGETS)

jats: $(JATS_TARGETS)

docx: $(DOCX_TARGETS)

automatic_locale.tex : automatic_locale.md $(ROOT)statement.lua
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		--pdf-engine lualatex --to=latex --output $@

automatic_locale.pdf : automatic_locale.md $(ROOT)statement.lua
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		--pdf-engine lualatex --to=pdf --output $@

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

clean: 
	@rm -f $(LATEX_TARGETS) $(PDF_TARGETS) $(HTML_TARGETS) $(JATS_TARGETS) $(DOCX_TARGETS)