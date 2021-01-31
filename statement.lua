--[[-- # Statement - a Lua filter for statement support in Pandoc's markdown

This Lua filter provides support for statements (principles, arguments, vignettes,
theorems, exercises etc.) in Pandoc's markdown.

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@author Thomas Hodgson <hello@twshodgson.net>
@copyright 2021 Julien Dutant, Thomas Hodgson
@license MIT - see LICENSE file for details.
@release 0.1

]]

-- # Parameters

--- formats for which we process the
local target_formats = {
  'html.*',
  'latex',
  'jats'
}

local convert_horizontal_rules = {
  convert = "yes",
  latex = "\\rule{0.5\\linewidth}{0.5pt}",
  html = "<hr/>",
  html4 = "<hr/>",
  html5 = "<hr/>",
  jats = "<hr/>"
}

-- # Helper functions

--- Returns true if the current target format is in a given list.
--    The list is made of pandoc format names. They can include
--      pattern matching, e.g. "html.*" will match html4 and html5.
-- @param formats list of formats
-- @return true if the current target format is in `formats`
local function format_matches(formats)
  for _,format in pairs(formats) do
    if FORMAT:match(format) then
      return true
    end
  end
  return false
end

-- # Filter functions


--- Format for the target output.
-- Wraps the div with suitable markup inserted as raw blocks.
-- @param elem the element to be processed
-- @return the processed element
-- @todo provide hooks for customizing the starting/end tags.
function format_statement(elem)

  local content = pandoc.List:new(elem.content)

  if FORMAT:match 'latex' then
    content:insert(1, pandoc.RawBlock('latex', "\\begin{statement}\n\\setlength{\\parskip}{0em}"))
    content:insert(pandoc.RawBlock('latex', "\\end{statement}"))
    return content -- returns content, not the Div
  end
  if FORMAT:match 'jats' then
    content:insert(1, pandoc.RawBlock('jats', "<statement>"))
    content:insert(pandoc.RawBlock('jats', "</statement>"))
    elem.content = content
    return elem.content -- returns content, not the Div
  end
  if FORMAT:match 'html' then
    return elem -- keep the div
  end

end

--- Replace horizontal rules by custom output code depending on format.
--    Within statements, horizontal rules are only used to
--    state arguments: they separate premises and conclusionn.
-- @param elem where horizontal rules should be replaced
-- @return elem with horizontal rules replaced
local function replace_horizontal_rules(elem)
  return pandoc.walk_block(elem, {
    HorizontalRule = function(elem)
        if convert_horizontal_rules[FORMAT] then
          return pandoc.RawBlock(FORMAT, convert_horizontal_rules[FORMAT])
        end
      end
  })
end

--- Process an element of class `statement`.
-- @param element
-- @return the processed element
local function process(element)

    -- replace horizontal rules
    if convert_horizontal_rules["convert"] then
      element = replace_horizontal_rules(element)
    end

    -- format statement for output
    return format_statement(element)
end

--- Main filter, returned if the target format matches our list.
main_filter = {
  Div = function (element)
    if element.classes:includes ("statement") then
      return process(element)
    end
  end,
}

if format_matches(target_formats) then
  return {main_filter}
end
