--[[-- # Statement - a Lua filter for statements in Pandoc's markdown

This Lua filter provides support for statements (principles,
arguments, vignettes, theorems, exercises etc.) in Pandoc's markdown.

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@author Thomas Hodgson <hello@twshodgson.net>
@copyright 2021 Julien Dutant, Thomas Hodgson
@license MIT - see LICENSE file for details.
@release 0.1

]]

-- for debug only
package.path = package.path .. ';/home/t/pprint.lua/?.lua'
local pprint = require('pprint')

-- # Parameters

--- Options map, including defaults.
-- @param header boolean whether to include support code in the header (true).
-- @param convert_rules boolean whether to convert horinzontal rules to half length.
local options = {
  header = true,
  convert_rules = true,
}

--- list of formats for which we process the filter.
local target_formats = {
  'html.*',
  'latex',
  'jats',
  'native',
  'markdown'
}
--- code map for horizontal rules within statements.
-- One key for each format.
local horizontal_rule = {
  latex = "\\rule{0.5\\linewidth}{0.5pt}",
  html = '<hr style="width:50%" />',
  jats = "<hr/>"
}

--- Code for header-includes.
-- one key per format.
local header = {
  latex = [[]],
  html = [[<style>
  .statement {
    margin: 2.5em 1em;
  }
  </style>]],
}

--- Code for statement environments.
-- one key per format. Its value is a map with `beginenv` and `endenv` keys.
-- usage: environment_tags[FORMAT]["beginenv"].
local environment_tags = {
  latex = {
    beginenv = '\\begin{',
    endenv = '\\end{',
  },
  jats = {
    beginenv = '<statement>',
    endenv = '</statement>',
  },
  html = {
    beginenv = '<div class="statement">',
    endenv = '</div>',
  },
}

--- Code for label environments.
-- one key per format. Its value is a map with `beginenv` and `endenv` keys.
-- usage: label_tags[FORMAT]["beginenv"].
local label_tags = {
  jats = {
    beginenv = '<label>',
    endenv = '</label>',
  },
  html = {
    beginenv = '<div class="statement-label">',
    endenv = '</div>',
  },
}

--- Code for title environments.
-- one key per format. Its value is a map with `beginenv` and `endenv` keys.
-- usage: title_tags[FORMAT]["beginenv"].
local title_tags = {
  jats = {
    beginenv = '<title>',
    endenv = '</title>',
  },
  html = {
    beginenv = '<div class="statement-title">',
    endenv = '</div>',
  },
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

--- Interprets a metadata string as a read_boolean.
--    Following pandoc's conventions, returns true by default.
--  @param string user-set string that should express a boolean value.
--  @return boolean true unless read as false
local function read_boolean(string)

  local interpret_as_false = pandoc.List({'false', 'no'})

  if interpret_as_false:find(string.lower(string)) then
    return false
  else
    return true
  end

end

--- Add a block to the document's header-includes meta-data field.
-- @param meta the document's metadata block
-- @param block Pandoc block element (e.g. RawBlock or Para) to be added to header-includes
-- @return meta the modified metadata block
local function add_header_includes(meta, block)

    local header_includes

    -- make meta['header-includes'] a list if needed
    if meta['header-includes'] and meta['header-includes'].t == 'MetaList' then
        header_includes = meta['header-includes']
    else
        header_includes = pandoc.MetaList{meta['header-includes']}
    end

    -- insert `block` in header-includes and add it to `meta`

    header_includes[#header_includes + 1] =
        pandoc.MetaBlocks{block}

    meta['header-includes'] = header_includes

    return meta
end

--- Fill a map of outputs with equivalent formats.
--    Takes a map from pandoc format names to outputs and fills
--    it with any equivalent format that is not already
--    included. For example, the value of map['html'] will
--    be copied to map['html4'] if the latter doesn't exist.
--    We only fill from more general formats: copy `html`
--    to `html4` but not `html4` to `html` or `html5`.
--  @param map map to be modified
--  @return modified map
local function fill_equivalent_formats(map)

  map['html4'] = map['html4'] or map['html']
  map['html5'] = map['html5'] or map['html']
  map['beamer'] = map['beamer'] or map['latex']

  return map

end

-- # Filter functions

-- The kinds that have been set, which are used to build the LaTeX header
local kinds = {}

--- Format for the target output.
-- Wraps the div with suitable markup inserted as raw blocks.
-- @param elem the element to be processed
-- @return the processed element
-- @todo keep
-- @todo provide hooks for customizing the starting/end tags.
local function format_statement(elem)

  if environment_tags[FORMAT] then
    if not elem.attributes.kind then
      elem.attributes.kind = 'Statement'
    end
    local content = pandoc.List({})
    if FORMAT == 'latex' then
      if kinds[elem.attributes.kind] == nil then
        header['latex'] = header['latex'] .. '\\newtheorem{' .. string.lower(elem.attributes.kind) .. '}' .. '{' .. elem.attributes.kind .. '}\n'
        kinds[elem.attributes.kind] = 1 else
        kinds[elem.attributes.kind] = kinds[elem.attributes.kind] + 1
       end
       local latex_begin = environment_tags[FORMAT]['beginenv'] .. string.lower(elem.attributes.kind) .. '}'
       if elem.attributes.title then
       -- using stringify here will strip the formatting; is there a better option?
        content:insert(pandoc.RawBlock(FORMAT, latex_begin .. '[' .. pandoc.utils.stringify(pandoc.read(elem.attributes.title)) .. ']' )) else
        content:insert(pandoc.RawBlock(FORMAT, latex_begin))
      end
      else
      content:insert(pandoc.RawBlock(FORMAT, environment_tags[FORMAT]['beginenv']))
    end
    if FORMAT ~= 'latex' and elem.attributes.kind then
      content:insert(pandoc.RawBlock(FORMAT, label_tags[FORMAT]['beginenv']))
      local label = pandoc.List({pandoc.read(elem.attributes.kind).blocks[1]})
      content:extend(label)
      content:insert(pandoc.RawBlock(FORMAT, label_tags[FORMAT]['endenv']))
    end
    if FORMAT ~= 'latex' and elem.attributes.title then
      content:insert(pandoc.RawBlock(FORMAT, title_tags[FORMAT]['beginenv']))
      local title = pandoc.List({pandoc.read(elem.attributes.title).blocks[1]})
      content:extend(title)
      -- I'm not sure that I am using the target tag correctly
      -- It can be in a <title>; should it wrap the content?
      -- https://jats.nlm.nih.gov/publishing/tag-library/1.2/element/target.html
      if FORMAT == 'jats' and elem.identifier ~= '' then
        content:insert(pandoc.RawBlock('jats', '<target id="' .. elem.identifier .. '"></target>'))
      end
      content:insert(pandoc.RawBlock(FORMAT, title_tags[FORMAT]['endenv']))
    end
    content:extend(elem.content)
    if FORMAT == 'latex' and elem.identifier ~= '' then
      content:insert(pandoc.RawBlock('latex', '\\label{' .. elem.identifier .. '}'))
    end
    if FORMAT == 'latex' then
      local latex_end = environment_tags[FORMAT]['endenv'] .. string.lower(elem.attributes.kind) .. '}'
      content:insert(pandoc.RawBlock(FORMAT, latex_end)) else
      content:insert(pandoc.RawBlock(FORMAT, environment_tags[FORMAT]['endenv']))
    end
    return content -- returns contents, not the Div

  end

  return elem -- keep the Div

end

--- Replace horizontal rules by custom output code depending on format.
--    Within statements, horizontal rules are only used to
--    state arguments: they separate premises and conclusion.
-- @param elem where horizontal rules should be replaced
-- @return elem with horizontal rules replaced
-- @see horizontal_rule
local function replace_horizontal_rules(elem)
  return pandoc.walk_block(elem, {
    HorizontalRule = function(elem)
        if horizontal_rule[FORMAT] then
          return pandoc.RawBlock(FORMAT, horizontal_rule[FORMAT])
        end
      end
  })
end

--- Process an element (Div) of class statement.
-- @param element
-- @return the processed element
-- @see options
local function process(element)

    -- replace horizontal rules
    if options['convert_rules'] then
      element = replace_horizontal_rules(element)
    end

    -- format statement for output
    return format_statement(element)
end

--- Process meta block: add header-includes.
--    If the output is native or markdown, copy header-includes for
--    all formats. We get repeated includes for html, html4, html5.
--    Is that a problem?
-- @param meta pandoc Meta block
-- @return processed block
local function process_meta(meta)

  if options["header"] then

    if FORMAT:match('native') or FORMAT:match('markdown') then

      for format_name,format_code in pairs(header) do
        add_header_includes(meta,
          pandoc.RawBlock(format_name, format_code))
      end

    elseif header[FORMAT] then

      add_header_includes(meta,
        pandoc.RawBlock(FORMAT, header[FORMAT]))

    end

  end

  return meta

end

--- Read options from meta block.
--  Get options from the `statement` field in a metadata block.
-- @param meta the document's metadata block.
-- @return nothing, values set in the `options` map.
-- @see options
local function get_options(meta)
  if meta.statement and meta.statement.header then

    options['header'] = read_boolean(
      pandoc.utils.stringify(meta.statement.header))

  end
end

--- Main filter, returned if the target format matches our list.
main_filter = {

  Meta = function(meta)
    get_options(meta)
    return process_meta(meta)
  end,

  Div = function (element)
    if element.classes:includes ("statement") then
      return process(element)
    end
  end,
}

-- Main.
-- Set parameters, return filter.
if format_matches(target_formats) then

  fill_equivalent_formats(horizontal_rule)
  fill_equivalent_formats(header)
  fill_equivalent_formats(environment_tags)

  return {main_filter}

end
