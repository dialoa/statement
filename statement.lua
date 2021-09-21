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
-- package.path = package.path .. ';/home/t/pprint.lua/?.lua'
-- local pprint = require('pprint')

-- # Parameters

--- Options map, including defaults.
-- @param header boolean whether to include support code in the header (true).
-- @param convert_rules boolean whether to convert horinzontal rules to half length.
-- @param kinds map of the kinds of statement available
local options = {
  header = true,
  convert_rules = true,
  shorthands = true,
  latexskipinlist = '\\baselineskip',
  latexrightskipinlist = '2em'
}
--- Kinds map.
-- the generic key gives defaults to create new kinds on the fly if needed.
-- otherwise entries are maps of feature for a given kind:
-- @param latexenvname name of the latex environment
-- @param latexstyle string of parameters for \newtheoremstyle, excluding
-- the first parameter (name): space above, space below, body font, first \
-- line identation, theorem head font, punctuation after theorem head,
-- space after theorem head, head spec. Beware of escaping backslashes.
local kinds = {
  statement = {
    style = 'empty',
  },
  argument = {
    style = 'emptynoindent'
  },
  corollary = {
    style = 'plain',
    label = "Corollary"
  },
}
-- create a list of shorthands
local kinds_shorthands = pandoc.List:new()
for key,_ in pairs(kinds) do
  if key ~= 'statement' then
    kinds_shorthands:insert(key)
  end
end
--- Statement styles map.
-- plain, definition and remark are the AMS default styles.
-- empty is a custom empty style (no label).
local styles = {
  plain = {
    header = {
      latex = '',
      html = 'margin: 2em 1em'
    },
  },
  empty = {
    header = {
      latex = [[%
      {1em} % space above
      {1em} % space below
      {\addtolength{\leftskip}{2em}\addtolength{\rightskip}{2em}} % body font
      {0pt} % first line indentation (empty = no indent)
      {} % theorem head font
      {} % punctuation after theorem head
      {0pt} % space after theorem head
      {{}} % theorem head spec
    ]],
    html = 'margin: 2em 1em',
    }
  },
  emptynoindent = {
    header = {
      latex = [[%
      {1em} % space above
      {1em} % space below
      {\addtolength{\leftskip}{2em}\addtolength{\rightskip}{2em}\parindent 0pt} % body font
      {0pt} % first line indentation (empty = no indent)
      {} % theorem head font
      {} % punctuation after theorem head
      {0pt} % space after theorem head
      {{}} % theorem head spec
    ]],
    html = 'margin: 2em 1em',
    }
  },
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
  latex = "\\nopagebreak[4]\\raisebox{.25\\baselineskip}{"
      .. "\\rule{0.5\\linewidth}{0.5pt}"
      .. "}\\nopagebreak[4]",
  html = '<hr style="width:50%" />',
  jats = "<hr/>"
}

--- Code for header-includes.
-- one key per format.
local header = {
  latex = {
    before = '\\usepackage{amsthm}'
  },
  html = {
    before = '<style>',
    after = '</style>'
  }
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

--- Map of the kinds that are used in the document.
-- Used to build header-includes code.
--    keys should be lowercase (`statement`, `axiom` etc)
--    values are boolean
local kinds_used = pandoc.List({})

--- Process a statement's attributes
-- Keeps a list of kinds used, adds default "statement" kind if needed.
-- @param elem a Pandoc Div element
function process_attributes(elem)

  -- clean up the kind attribute name
  -- removes non-alphanumeric chars and puts in lowercase
  local kind = elem.attributes.kind or ''
  kind =  string.lower(string.gsub(kind, '%W', ''))
  -- if no kind attribute found, look in the classes
  for _,class in ipairs(elem.classes) do
    if kinds_shorthands:includes(class) then
      kind = class
    end
  end

  if kind == '' then kind = 'statement' end

  -- if the kind isn't in the list of available kinds, add it
  --    the label will be the original kind field
  if not kinds[kind] then
    kinds[kind] = {
      style = 'plain',
      label = elem.attributes.kind
    }
  end

  -- keep track of the kinds used
  if not kinds_used:includes(kind) then
    kinds_used:insert(kind)
  end

  -- save the cleaned-up kind name
  elem.attributes.kind = kind

  return elem
end

--- Format for the target output.
-- Wraps the div with suitable markup inserted as raw blocks.
-- @param elem the element to be processed
-- @return a formatted element (or list of elements?)
--
-- @TODO are we sure that environment_tags, label_tags, title_tags
--  contain values for FORMAT? What if the format is html5 or html4?
--  it is probably safer to have a strict list of output formats...
--
-- @TODO probably more efficient to define the RawBlocks in the
--  options tables, so as to avoid calling these functions all the time
--  and to make the code more legible
--
-- @todo provide hooks for customizing the starting/end tags.
local function format_statement(elem)

  if environment_tags[FORMAT] then

    local content = pandoc.List({})
    local kind = elem.attributes.kind
    local title = elem.attributes.title or ''
    local label = kinds[kind].label or ''
    local identifier = elem.identifier or ''

    if FORMAT:match('latex') then

      -- build the \begin command, adding title if defined
      local latex_begin = environment_tags[FORMAT]['beginenv'] .. kind .. '}'
      if title ~= '' then
       -- using stringify here will strip the formatting; is there a better option?
        content:insert(pandoc.RawBlock(FORMAT, latex_begin .. '['
          .. pandoc.utils.stringify(pandoc.read(elem.attributes.title)) .. ']' ))
      else
        content:insert(pandoc.RawBlock(FORMAT, latex_begin))
      end

      -- body of the statement
      content:extend(elem.content)

      -- identified if defined (in LaTeX, \label for crossreference)
      if identifier ~= '' then
        content:insert(pandoc.RawBlock('latex', '\\label{' .. identifier .. '}'))
      end

      -- end the statement
      local latex_end = environment_tags[FORMAT]['endenv'] .. kind .. '}'
      content:insert(pandoc.RawBlock(FORMAT, latex_end))

      -- insert the new content
      -- the div and its attributes remain as is
      elem.content = content

    elseif FORMAT:match('html.*') or FORMAT:match('jats') then

      content:insert(pandoc.RawBlock(FORMAT, environment_tags[FORMAT]['beginenv']))

      -- insert label if defined
      if label ~= '' then
        content:insert(pandoc.RawBlock(FORMAT, label_tags[FORMAT]['beginenv']))
        -- local pandoclabel = pandoc.List({pandoc.read(label).blocks[1]})
        -- content:extend(pandoclabel)
        content:insert(pandoc.Plain(pandoc.Str(label))) -- Plain is a block that is not a paragraph
        content:insert(pandoc.RawBlock(FORMAT, label_tags[FORMAT]['endenv']))
      end

      -- insert title if defined, and identifier in JATS
      if title ~= '' then
        content:insert(pandoc.RawBlock(FORMAT, title_tags[FORMAT]['beginenv']))
        -- local pandoctitle = pandoc.List({pandoc.read(title).blocks[1]})
        -- content:extend(pandoctitle)
        content:insert(pandoc.Plain(pandoc.Str(title)))
        -- I'm not sure that I am using the target tag correctly
        -- It can be in a <title>; should it wrap the content?
        -- https://jats.nlm.nih.gov/publishing/tag-library/1.2/element/target.html
        if FORMAT == 'jats' and identifier ~= '' then
          content:insert(pandoc.RawBlock('jats', '<target id="' .. elem.identifier .. '"></target>'))
        end
        content:insert(pandoc.RawBlock(FORMAT, title_tags[FORMAT]['endenv']))
      end

      -- body of the statement
      content:extend(elem.content)

      -- end the statement
      content:insert(pandoc.RawBlock(FORMAT, environment_tags[FORMAT]['endenv']))

      -- @todo in those formats we should probably replace the div instead
      elem.content = content

    end

    return elem -- keep the Div, return it only if you changed sthg

  end

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
    if options.convert_rules then
      element = replace_horizontal_rules(element)
    end

    -- process attributes
    element = process_attributes(element)

    -- format statement for output
    return format_statement(element)
end


--- Build header-includes code.
-- @param format string format to be used
-- @return string with the code
-- @todo (minor issue) "the for style,definition in pairs(styles) do"
--    loops doesn't go through the styles in the same order on every run
--    this sometimes prevents the Makefile to validate the code.
local function build_header(format)

  local result = ''

  -- basic setup
  if header[format] and header[format].before then
    result = result .. header[format].before .. '\n'
  end

  -- theorem styles
  for style,definition in pairs(styles) do

    if definition.header and definition.header[format] then

      if format:match('latex') and definition.header.latex ~= '' then
        result = result .. '\\newtheoremstyle{' .. style
          .. '}' .. definition.header.latex .. '\n'
      elseif format:match('html.*') then
        result = result .. '.statement-style-' .. style .. ' '
          .. '{' .. definition.header.html .. '}\n'
      end

    end

  end

  -- theorem kinds
  for _,kind in ipairs(kinds_used) do

    if format:match('latex') then

      local label = kinds[kind].label or ''
      result = result .. '\\theoremstyle{' .. kinds[kind].style .. '}\n'
        .. '\\newtheorem{' .. kind .. '}{' .. label .. '}\n'

    end

  end

  if header[format] and header[format].after then
    result = result .. header[format].after .. '\n'
  end

  return result
end


--- Write meta: add header-includes to the document's metadata.
--    If the output is native or markdown, add header-includes for
--    all formats.
-- @todo We get repeated includes for html, html4, html5. Is that
--  a problem?
-- @param meta pandoc Meta block
-- @return processed block
local function write_meta(meta)

  if options.header then


    if FORMAT:match('native') or FORMAT:match('markdown') then

      local output_types = {'latex', 'html', 'jats'}
      for _,output_type in ipairs(output_types) do
        add_header_includes(meta,
          pandoc.RawBlock(output_type, build_header(output_type))
        )
      end

    else

      add_header_includes(meta,
        pandoc.RawBlock(FORMAT, build_header(FORMAT))
      )

    end

    return meta

  end

end

--- Read options from meta block.
--  Get options from the `statement` field in a metadata block.
-- @todo read kinds settings
-- @param meta the document's metadata block.
-- @return nothing, values set in the `options` map.
-- @see options
local function get_options(meta)
  if meta.statement then

    -- header: if true we provide header-includes
    if meta.statement.header ~= nil then
      if meta.statement.header then
        options.header = true
      else
        options.header = false
      end
    end

    -- shorthands (default true): process divs with only a kind name
    if meta.statement.shorthands == false then
      options.shorthands = false
    end

    -- custom LaTeX skips for statements that appear as first line in a list
    if meta.statement.latexskipinlist ~= nil then
      options.latexskipinlist = meta.statement.latexskipinlist
    end
    if meta.statement.latexrightskipinlist ~= nil then
      options.latexrightskipinlist = meta.statement.latexrightskipinlist
    end

    -- @todo read kinds

  end
end

--- process list element
-- In LaTeX a statement at the first line of an list item creates an
-- unwanted empty line. We wrap it in a LaTeX minipage to avoid this.
-- @TODO This is hack, probably prevents page breaks within the statement
-- @TODO The skip below the statement is rigid, it should pick the
-- skip that statement kind
local function process_list_elem(elem)
  if FORMAT:match('latex') or FORMAT:match('native')
    or FORMAT:match('json') then
      -- only return something if `elem` is updated
      local list_updated = false

      -- function to wrap the first element of a list of blocks
      -- store the parindent value before, as minipage resets it to zero
      -- \docparindent will contain it, but needs to be picked before
      -- the list!
      -- with minipage commands
      local wrap = function(blocks)
        blocks:insert(1, pandoc.RawBlock('latex',
          '\\begin{minipage}[t]{\\textwidth}\\parindent \\docparindent'
          ))
        blocks:insert(3, pandoc.RawBlock('latex',
          '\\end{minipage}'
          .. '\\vskip ' .. options.latexskipinlist
          ))
        -- add a right skip declaration within the statement Div
        blocks[2].content:insert(1, pandoc.RawBlock('latex',
          '\\addtolength{\\rightskip}{'..options.latexrightskipinlist .. '}'
          )
        )

        return blocks
      end

      -- go through list items, check if they start with a statement Div
      for i = 1, #elem.content do
        if elem.content[i][1] and elem.content[i][1].t == 'Div' then
          if elem.content[i][1].classes:includes('statement') then
            elem.content[i] = wrap(elem.content[i])
            list_updated = true
          elseif options.shorthands then
            local is_statement = false
            for _,class in ipairs(elem.content[i][1].classes) do
              if kinds_shorthands:includes(class) then
                is_statement = true
                break
              end
            end
            if is_statement then
              elem.content[i] = wrap(elem.content[i])
              list_updated = true
            end
          end
        end
      end

      -- if the list has been updated we need to put a LaTeX line
      -- before to store the document's parindent value
      if list_updated == true then
        return {
          pandoc.RawBlock('latex',
            '\\edef\\docparindent{\\the\\parindent}\n'),
          elem
        }
      end
  end
end

--- Main filters: read options, process lists, process document.
-- In LaTeX statements that begin a list should be placed within
-- a minipage.
read_options_filter = {
  Meta = function(meta)
    get_options(meta)
  end,
}
process_lists_filter = {
  BulletList = process_list_elem,
  OrderedList = process_list_elem,
}
process_filter = {
  Div = function(elem)
    if options.shorthands then
      for _,name in ipairs(kinds_shorthands) do
        if elem.classes:includes(name) then
          return process(elem)
        end
      end
      if elem.classes:includes('statement') then
        return process(elem)
      end
    elseif elem.classes:includes('statement') then
      return process(elem)
    end
  end,
  Meta = function(meta)
    return write_meta(meta)
  end,
}


--- Main code:  Fill in global variables, read options, process
-- the document, write options.
if format_matches(target_formats) then

  fill_equivalent_formats(horizontal_rule)
  fill_equivalent_formats(header)
  fill_equivalent_formats(environment_tags)

  return {read_options_filter, process_lists_filter, process_filter}

end
