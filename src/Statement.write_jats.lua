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
	--passing writer options that affect inlines formatting in JATS
	--@BUG even with the doc's meta, citeproc doesn't convert citations
	function write_to_jats(inlines)
		local result, doc
		local options = pandoc.WriterOptions({
				cite_method = PANDOC_WRITER_OPTIONS.cite_method,
				columns = PANDOC_WRITER_OPTIONS.columns,
				email_obfuscation = PANDOC_WRITER_OPTIONS.email_obfuscation,
				extensions = PANDOC_WRITER_OPTIONS.extensions,
				highlight_style = PANDOC_WRITER_OPTIONS.highlight_style,
				identifier_prefix = PANDOC_WRITER_OPTIONS.identifier_prefix,
				listings = PANDOC_WRITER_OPTIONS.listings,
				prefer_ascii = PANDOC_WRITER_OPTIONS.prefer_ascii,
				reference_doc = PANDOC_WRITER_OPTIONS.reference_doc,
				reference_links = PANDOC_WRITER_OPTIONS.reference_links,
				reference_location = PANDOC_WRITER_OPTIONS.reference_location,
				tab_stop = PANDOC_WRITER_OPTIONS.tab_stop,
				wrap_text = PANDOC_WRITER_OPTIONS.wrap_text,
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

