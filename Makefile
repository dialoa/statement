INFO = quiet # use make INFO=verbose to get Pandoc verbose output
SRC_FILES = $(wildcard src/*.lua)

.PHONY: _extensions/statement/statement.lua

_extensions/statement/statement.lua: $(SRC_FILES) lua-builder/lua-builder.lua
	@lua lua-builder/lua-builder.lua src/main.lua -o _extensions/statement/statement.lua --verbose --recursive

