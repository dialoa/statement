---Statement.write_latex: write a statement in LaTeX
-- Pandoc's JATS writer turns Plain blocks in to <p>...</p>
-- for this reason we must write <label> and <title> inlines
-- to text before we insert them.
-- <statement>
--		<label> Kind label number or Custom label </label>
--		<title> info </title>
--		content blocks
-- </statement
--@return Blocks
function Statement:write_jats()
	doc_meta = self.setup.meta -- pointer to the doc's Meta
														 -- needed by pandoc.write
	local blocks = pandoc.List:new()

	--write_to_jats: use pandoc to convert inlines to jats output
	--@BUG this needs the document meta, otherwise biblio not found 
	function write_to_jats(inlines)
		local result, doc
		local options = pandoc.WriterOptions({
				cite_method = PANDOC_WRITER_OPTIONS.cite_method
		})
		doc = pandoc.Pandoc(pandoc.Plain(inlines), doc_meta)
		result = pandoc.write(doc, 'jats', options)
		return result:match('^<p>(.*)</p>$') or result or ''

	end

	blocks:insert(pandoc.RawBlock('jats', '<statement>'))

	label_inlines = self:write_label() 
	if #label_inlines > 0 then
		local label_str = '<label>'..write_to_jats(label_inlines) 
											..'</label>'
		blocks:insert(pandoc.RawBlock('jats',label_str))
	end

	if self.info then
		local info_str = 	'<title>'..write_to_jats(self.info)
											..'</title>'
		blocks:insert(pandoc.RawBlock('jats',info_str))
	end

	blocks:extend(self.content)

	blocks:insert(pandoc.RawBlock('jats', '</statement>'))

	return blocks

end

