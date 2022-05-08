ROOT = ../# repository's root
INFO = quiet # use make INFO=verbose to get Pandoc verbose output
SRC_FILES = $(wildcard $(ROOT)src/*.lua)
TEST_FILES = $(wildcard *.md)
LATEX_TARGETS = $(patsubst %.md,%.tex,$(TEST_FILES))
PDF_TARGETS = $(patsubst %.md,%.pdf,$(TEST_FILES))
HTML_TARGETS = $(patsubst %.md,%.html,$(TEST_FILES))
JATS_TARGETS = $(patsubst %.md,%.xml,$(TEST_FILES))
DOCX_TARGETS = $(patsubst %.md,%.docx,$(TEST_FILES))
NATIVE_TARGETS = $(patsubst %.md,%.native,$(TEST_FILES))

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

native: $(NATIVE_TARGETS)

number_offset.html : number_offset.md $(ROOT)statement.lua
	@echo Generating $@
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		--number-offset=2,2,2 \
		--top-level-division=chapter \
		--mathjax --number-sections --citeproc --to=html --output $@

automatic_locale.tex : automatic_locale.md $(ROOT)statement.lua
	@echo Generating $@
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		--pdf-engine lualatex \
		--number-sections --citeproc --to=latex --output $@

automatic_locale.pdf : automatic_locale.md $(ROOT)statement.lua
	@echo Generating $@
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		--pdf-engine lualatex \
		--number-sections --citeproc --to=pdf --output $@

%.tex: %.md $(ROOT)statement.lua
	@echo Generating $@
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		--number-sections --citeproc --to=latex --output $@

%.pdf: %.md $(ROOT)statement.lua
	@echo Generating $@
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		--number-sections --citeproc --to=pdf --output $@

%.html: %.md $(ROOT)statement.lua
	@echo Generating $@
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		--mathjax --number-sections --citeproc --to=html --output $@

%.xml: %.md $(ROOT)statement.lua
	@echo Generating $@
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		--citeproc --to=jats --output $@

%.docx: %.md $(ROOT)statement.lua
	@echo Generating $@
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		--number-sections --citeproc --to=docx --output $@

%.native: %.md $(ROOT)statement.lua
	@echo Generating $@
	@pandoc $< --lua-filter $(ROOT)statement.lua -s --$(INFO) \
		--number-sections --citeproc --to=native --output $@

clean: 
	@echo Cleaning up generated files
	@rm -f $(LATEX_TARGETS) $(PDF_TARGETS) $(HTML_TARGETS) \
			$(JATS_TARGETS) $(DOCX_TARGETS) $(NATIVE_TARGETS)