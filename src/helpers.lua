---Helpers class: helper functions
--This class collects helper functions that do not depend 
--on the filter's data structure.
Helpers = {}

-- # Global functions

stringify = pandoc.utils.stringify

--- type: pandoc-friendly type function
-- pandoc.utils.type is only defined in Pandoc >= 2.17
-- if it isn't, we extend Lua's type function to give the same values
-- as pandoc.utils.type on Meta objects: Inlines, Inline, Blocks, Block,
-- string and boolean
-- Caution: not to be used on non-Meta Pandoc elements, the 
-- results will differ (only 'Block', 'Blocks', 'Inline', 'Inlines' in
-- >=2.17, the .t string in <2.17).
Helpers.type = pandoc.utils.type or function (obj)
        local tag = type(obj) == 'table' and obj.t and obj.t:gsub('^Meta', '')
        -- convert to Block, Blocks, Inline, Inlines
        return tag and tag ~= 'Map' and tag or type(obj)
    end
type = Helpers.type

--- ensure_list: turns an element into a list if needed
-- If elem is nil returns an empty list
-- @param elem a Pandoc element
-- @return a Pandoc List
ensure_list = function (elem)
    return type(elem) == 'List' and elem or pandoc.List:new({elem})
end

---message: send message to std_error
-- @param type string INFO, WARNING, ERROR
-- @param text string message text
message = function (type, text)
    local level = {INFO = 0, WARNING = 1, ERROR = 2}
    if level[type] == nil then type = 'ERROR' end
    if level[PANDOC_STATE.verbosity] <= level[type] then
        io.stderr:write('[' .. type .. '] Collection lua filter: ' 
            .. text .. '\n')
    end
end

-- ## Functions stored in Helpers fields

!input Helpers.font_format -- parse font features into formatting commands

!input Helpers.font_format_native -- parse font features into pandoc elements

!input Helpers.length_format -- parse a length in the desired format

