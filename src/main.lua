--[[-- # Statement - a Lua filter for statements in Pandoc's markdown

This Lua filter provides support for statements (principles,
arguments, vignettes, theorems, exercises etc.) in Pandoc's markdown.

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@author Thomas Hodgson <hello@twshodgson.net>
@copyright 2021-2022 Julien Dutant, Thomas Hodgson
@license MIT - see LICENSE file for details.
@release 0.3

@TODO provide 'break-after-head' style field
@TODO provide head-pattern, '<label> <num>. **<info>**', relying on Pandoc's rawinline parsing
@TODO provide \ref \label crossreferences in LaTeX?
@TODO handle pandoc-amsthm style Div attributes?
@TODO handle the Case environment?

@TODO proof environment in non-LaTeX outputs
proof environement in LaTeX AMS:
- does not define a new theorem kind and style
- has a \proofname command to be redefined
- has an optional argument for label
\begin{proof}[label]
\end{proof}
how do we handle it in html, jats? best would be not to create 
a new class every time, so mirror LaTeX. 

]]

-- # Global helper functions

!input helpers -- a few helper functions

-- # Filter components

!input Setup -- the Setup class

!input Statement -- the Statement class

!input Walker -- the Walker class

-- # Main function

function main(doc) 

	-- JATS writer requires pandoc.write
	-- not sure which is the lowest compatible version otherwise, 
	-- 2.14 is definitely enough, 2.12 should be good
	if FORMAT:match('jats') then
		PANDOC_VERSION:must_be_at_least '2.17'
	else 
		PANDOC_VERSION:must_be_at_least '2.12'
	end		

	-- create a setup object that holds the filter settings
	local setup = Setup:new(doc.meta)

	-- create a new document walker based on the setting
	local walker = Walker:new(setup, doc)

	-- Protect statements in lists in LaTeX 
	-- by applying the `statement_in_lists` filter
	-- See this function for details.
	walker.blocks = pandoc.Blocks(walker.blocks):walk(walker:statements_in_lists())

	-- walk the document; returns nil if no modification
	local blocks = walker:walk()
	-- process crossreferences if statements were created
	if blocks then
		blocks = pandoc.Blocks(blocks):walk(walker:crossreferences())
	end

	-- if the doc has been modified, update its meta and return it
	if blocks then
		doc.blocks = blocks
		doc.meta = setup:update_meta(doc.meta)
		return doc
	end
end

--- Return main as a Pandoc element filter
return {
	{
			Pandoc = main
	},
}