---Crossref.aggregate_references: turn successive 
-- numbered references of the same kind into a list.
-- E.g. "Theorem 1;Theorem 1.2" -> "Theorem 1.1, 1.2"
-- "1.1; 1.2; 1.3" -> "1.2--1.3"
-- Whenever we find such a sequence we replace it by
-- the last item with:
--		- the first item's prefix
--		- some additional fields to specify the sequence
--@param references a list of reference items
function Crossref:aggregate_references(references)
	local identifiers = self.identifiers -- points to the identifier table
	local kinds = self.setup.kinds -- points to the kinds table
	local new_references = pandoc.List:new()

	---counters_are_shared: checks whether two items
	-- are counted together.
	local function counters_are_shared(item1,item2)
		local kind1 = identifiers[item1.id].kind
		local kind2 = identifiers[item2.id].kind
		if kind1 == kind2
				or kinds[kind1].counter == kind2
				or kinds[kind2].counter == kind1 then
			return true
		else
			return false
		end
	end

	---labels_are_consecutive: checks that one item's number
	-- precedes another. 
	-- We require the last number to be consecutive, e.g.:
	-- 2.9, 2.10 : ok
	-- 2.9, 3.1 : not ok
	--@param item1 the earlier reference list item
	--@param item2 the later reference list item
	local function labels_are_consecutive(item1,item2)
		local label1 = stringify(identifiers[item1.id].label)
		local label2 = stringify(identifiers[item2.id].label)
		local count1 = tonumber(label1:match('%d+$'))
		local count2 = tonumber(label2:match('%d+$'))
		return count1 and count2 and count2 == count1 + 1 
	end

	---auto_prefixes_are_compatible: if citations have
	-- auto prefixes, check that they are compatible.
	-- if the two items have auto prefix flag, they 
	-- need to be of the same kind.
	--@param item1, item2, reference list items
	local function auto_prefixes_are_compatible(item1, item2)
		local mode1 = item1.agg_pre_mode or self:get_pre_mode(item)
		local mode2 = item2.agg_pre_mode or self:get_pre_mode(item)
		return mode1 == 'none' and mode2 == 'none'
					 or identifiers[item1.id].kind == identifiers[item2.id].kind
	end

	-- Aggregate multiple references. Requirements:
	-- same counter
	-- not if the second has a prefix, unless it's the same
	-- not if either has custom text to replace its label
	-- consecutive numbers
	-- compatible auto prefixes
	-- 
	-- Strategy. When we concatenate an item, we give it the previous
	-- item's id (carried ofer since the first) and add two fields:
	-- `agg_last_id`: id of current item of the sequence
	-- `agg_first_id`: id of first item in the sequence
	-- `agg_count`: how many merges have occurred
	-- `agg_pre_mode`: string auto prefix flag or 'none'
	-- When the loop is over, we use these to create new labels for the
	-- aggregated items.
	local prev_item
	for i = 1, #references do
		item = references[i]
		-- do we aggregate this with the previous one?
		if prev_item
				and counters_are_shared(prev_item,item)
				and (not prev_item.suffix or #prev_item.suffix == 0)
				and not (item.text or prev_item.text)
				and (not item.prefix 
							or stringify(item.prefix) == stringify(prev_item.prefix))
				and labels_are_consecutive(prev_item,item)
				and auto_prefixes_are_compatible(prev_item, item) then

			-- first item's id: use the previous item's id,
			-- unless it's already carrying a first item's id
			item.agg_first_id = prev_item.agg_first_id 
													or prev_item.id
			-- auto prefix activated: use the previous item's
			-- auto prefix flag, unless it's already carrying that
			-- flag from another status
			item.agg_pre_mode = prev_item.agg_pre_mode 
													or self:get_pre_mode(prev_item)

			-- add one merge to the count
			item.agg_count = prev_item.agg_count and prev_item.agg_count + 1
												or 1

			-- carry over from the first item:
			-- prefix
			-- flags
			item.prefix = prev_item.prefix
			item.flags = prev_item.flags

		-- not aggregating: if we had a previous item in waiting we store it 
		elseif prev_item then
				
			new_references:insert(prev_item)
		
		end

		-- if that was the last item, we store it, otherwise we pass it to
		-- the next loop iteration.
		if i == #references then 
			new_references:insert(item)
		else
			prev_item = item
		end

	end

	return new_references
end

