DIFF ?= diff --strip-trailing-cr -u
INFO = quiet # use make INFO=verbose to get Pandoc verbose output
SRC_FILES = $(wildcard src/*.lua)

.PHONY: statement.lua

statement.lua: $(SRC_FILES) lua-builder/lua-builder.lua
	@lua lua-builder/lua-builder.lua src/main.lua -o statement.lua --verbose --recursive

