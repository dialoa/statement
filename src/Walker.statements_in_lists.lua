---Walker.statements_in_lists: filter to handle statements within
-- lists in LaTeX.
-- In LaTeX a statement at the first line of a list item creates an
-- unwanted empty line. We wrap it in a LaTeX minipage to avoid this.
-- Uses
--		self.setup (passed to Statement:Div_is_statement)
--		self.setup.options.LaTeX_in_list_afterskip
-- @TODO This is hack, probably prevents page breaks within the statement
-- @TODO The skip below the statement is rigid, it should pick the
-- skip that statement kind
function Walker:statements_in_lists()
	filter = {}

	-- wrap: wraps the first element of a list of blocks in a minipage.
  -- store the `\parindent` value before, as minipage resets it to zero.
  -- We will set \docparindent before the list to pick it up.
  -- with minipage commands
  local function wrap(blocks)
    blocks:insert(1, pandoc.RawBlock('latex',
      '\\begin{minipage}[t]{\\textwidth-\\itemindent-\\labelwidth}'
      ..'\\parindent\\docparindent'
      ))
    blocks:insert(3, pandoc.RawBlock('latex',
      '\\end{minipage}'
      .. '\\vskip ' .. self.setup.options.LaTeX_in_list_afterskip
      ))
    -- add a right skip declaration within the statement Div
    blocks[2].content:insert(1, pandoc.RawBlock('latex',
      '\\addtolength{\\rightskip}{'
      .. self.setup.options.LaTeX_in_list_rightskip .. '}'
      )
    )

    return blocks
  end

  -- process: processes a BulletList or OrderedList element
  -- return nil if nothing done
  function process(elem)
  	if FORMAT:match('latex') or FORMAT:match('native')
    		or FORMAT:match('json') then
 				
			local list_updated = false
	    -- go through list items, check if they start with a statement
      for i = 1, #elem.content do
        if elem.content[i][1] then
          if elem.content[i][1].t and elem.content[i][1].t == 'Div'
                and Statement:Div_is_statement(elem.content[i][1],self.setup) then
            elem.content[i] = wrap(elem.content[i])
            list_updated = true
          elseif elem.content[i][1].t and elem.content[i][1].t == 'DefinitionList' then
            --@TODO handle DefinitionLists here 
          end
        end
      end

      -- if list has been updated, we need to add a line at the beginning
      -- to store the document's `\parindent` value
      if list_updated == true then
      	return pandoc.Blocks({
          pandoc.RawBlock('latex',
            '\\edef\\docparindent{\\the\\parindent}\n'),
          elem      		
      	})
      end

    end
  end

  -- return the filter
  return {BulletList = process,
  	OrderedList = process}

end