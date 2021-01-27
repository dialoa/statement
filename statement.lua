--[[-- # Statement - a Lua filter for statement support in Pandoc's markdown

This Lua filter provides support for statements (principles, arguments, vignettes,
theorems, exercises etc.) in Pandoc's markdown.

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@author Thomas Hodgson <hello@twshodgson.net>
@copyright 2021 Julien Dutant, Thomas Hodgson
@license MIT - see LICENSE file for details.
@release 0.1

]]

-- # Helper functions

--- Merge two lists
--    TODO: get rid of that function, you should
--    instead declare the desired lists as pandoc.Lists
-- @param one ore more list
-- @return merged list
function merge_lists (...)

  local arguments_table = table.pack(...)
  local lists_to_merge = {}
  local merged_lists = {}

  -- helper function: merge two lists
  local function merge_two_lists(list1, list2)
    result = {}
    for _,value in ipairs(list2) do -- using ipairs, assuming only indexed items are to be merged
      table.insert(list1, value)
    end

    return
  end

  -- we only keep lists
  for _,item in ipairs(arguments_table) do
    if type(item) == "table" then
      table.insert (lists_to_merge, item)
    else
      -- assert(false, "Not a list, expecting lists to be merged"); -- error handling here if needed
    end
  end

  -- if more than one left, merge
  if #lists_to_merge > 0 then
    for i = 1, #lists_to_merge do
      for _,value in ipairs(lists_to_merge[i]) do -- using ipairs, assuming only indexed items are to be merged
        table.insert(merged_lists, value)
      end
    end
  end

  return merged_lists
end

-- function insert label
-- arguments:
--    - label : list of inlines
--    - elem: Div where the label is to be inserted
function insert_label(label, elem)
  -- if the first element is a paragraph, add the label to it.
  -- Otherwise put the label in its own paragraph.

  if elem.content[1] ~= nil and elem.content[1].t == "Para" then
    table.insert (label, pandoc.Space()) -- insert space after the label
    elem.content[1].content = merge_lists(label, elem.content[1].content)
  else
    table.insert (elem.content, 1, pandoc.Para(label))
  end
end

-- wrap element with suitable output markup
-- TODO: match all latex formats, all html formats; and epub

function format_statement(elem)
  if FORMAT:match 'latex' then
    table.insert(elem.content, 1, pandoc.RawBlock('latex', "\\begin{statement}\n\\setlength{\\parskip}{0em}"))
    table.insert(elem.content, pandoc.RawBlock('latex', "\\end{statement}"))
    return elem.content -- returns content, not the Div
  end
  if FORMAT:match 'jats' then
    table.insert(elem.content, 1, pandoc.RawBlock('jats', "<statement>"))
    table.insert(elem.content, pandoc.RawBlock('jats', "</statement>"))
    return elem.content -- returns content, not the Div
  end
  if FORMAT:match 'html' then
    return elem -- keep the div
  end

end

-- function build_label
--   returns a list of inlines
--   NB, do not add space at the end of the label, it will be provided if needed
function build_label ()
  -- return {pandoc.Str("Label.")} -- for tests

end

-- function replace_horizontal_rules
--  walk blocks and replace horizontal rules with custom output blocks
--  TODO reduce the space in LaTeX. may require fusing with the blocks before and after!
function replace_horizontal_rules(elem)
  return pandoc.walk_block(elem, {
    HorizontalRule = function(elem)
      if FORMAT:match 'latex' then
        return pandoc.RawBlock('latex', "\\rule{0.5\\linewidth}{0.5pt}")
      end
    end
  })
end


-- process Div elements with "statement" class
--  TODO: in JATS the label should be typeset in <label> tags
--    typesetting the label has to be done independently
--    one option: turn label into a span, and then typeset the span by format?
--    divide the process in two bits. First, make a table with the relevant
--    label info (type, numbering if needed, etc.)
--    then typeset statement by format.
function Div (elem)
  if elem.classes:includes ("statement") then
    -- typset label (inline element)
    label = build_label()
    -- insert label, if any
    if label ~= nil then
      insert_label (label, elem)
    end
    -- replace horizontal rules
        elem = replace_horizontal_rules(elem)

    -- format statement for output
    return format_statement(elem)
  end
end

