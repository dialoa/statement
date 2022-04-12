--[[-- # Statement - a Lua filter for statements in Pandoc's markdown

This Lua filter provides support for statements (principles,
arguments, vignettes, theorems, exercises etc.) in Pandoc's markdown.

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@author Thomas Hodgson <hello@twshodgson.net>
@copyright 2021-2022 Julien Dutant, Thomas Hodgson
@license MIT - see LICENSE file for details.
@release 0.3

@TODO unnumbered class
@TODO handle cross-references. in LaTeX \ref prints out number or section number if unnumbered
@TODO LaTeX hack for statements in list
@TODO html output, read Pandoc's number-offset option

proof environement in LaTeX AMS:
- does not define a new theorem kind and style
- has a \proofname command to be redefined
- has an optional argument for label
\begin{proof}[label]
\end{proof}
how do we handle it in html, jats? best would be not to create 
a new class every time, so mirror LaTeX. 

]]

-- # Global variables
stringify = pandoc.utils.stringify

-- # Filter components

helpers = require('helpers')

Setup = require('Setup')

Statement = require('Statement')

-- # Main functions

walk_doc = require('walk_doc')

function main(doc) 

	-- create a setup object that holds the filter settings
	local setup = Setup:new(doc.meta)

	-- walk the document; sets `doc` to nil if no modification
	doc = walk_doc(doc,setup)

	-- if the doc has been modified, update its meta and return it
	if doc then
		doc.meta = setup:update_meta(doc.meta)
		return doc
	end
end

--- Return main as a Pandoc object filter
return {
	{
			Pandoc = main
	},
}