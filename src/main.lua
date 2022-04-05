--[[-- # Statement - a Lua filter for statements in Pandoc's markdown

This Lua filter provides support for statements (principles,
arguments, vignettes, theorems, exercises etc.) in Pandoc's markdown.

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@author Thomas Hodgson <hello@twshodgson.net>
@copyright 2021 Julien Dutant, Thomas Hodgson
@license MIT - see LICENSE file for details.
@release 0.3

]]

-- # Global variables
stringify = pandoc.utils.stringify

-- options map
options = {
	amsthm = true, -- use the amsthm package in LaTeX
	aliases = true, -- use aliases (prefixes, labels) for statement classes
	swap_numbers = false, -- numbers before label
	define_in_header = true, -- defs in header, not local
	supply_header = true, -- modify header-includes 
	only_statement = false, -- only process Divs of 'statement' class
	fontsize = nil, -- document fontsize
}
-- kinds map. statement must exist
kinds = {
	-- prefix = string, crossreference prefix
	-- style = string, style (key of `styles`)
	-- counter = string, counter ('none', 'self', heading level,
	--			heading type, statement kind for shared counter)
}
-- styles map
styles = {}
-- alias map
aliases = {}
-- material to add in header 
header_includes = pandoc.List:new()
-- material to add in header (before defs) or at the first definition
-- make a list of blocks to trigger an insertion before first definition
before_definitions_includes = nil
-- LaTeX levels map
LaTeX_levels = {'section', 'subsection', 'subsubsection', 
	'paragraph', 'subparagrah'}
LaTeX_levels[0] = 'chapter'
LaTeX_levels[-1] = 'part'
LaTeX_levels[-2] = 'book'

-- modules
helpers = require('helpers')

length_format = require('length_format')

extract_first_balanced_brackets = require('extract_first_balanced_brackets')

Statement = require('Statement')

setup = require('setup')

walk_doc = require('walk_doc')

update_meta = require('update_meta')

-- end modules


return {
	-- process Meta for options first
	{
			Meta = setup		
	},
	-- process document, needs to be walked
	{
			Pandoc = walk_doc
	},
	-- update Meta 
	{
		Meta = update_meta
	},
}