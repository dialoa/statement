---Setup:increment_counter: increment the counter of a level
-- Increments a level's counter and reset any statement
-- count that is counted within that level.
-- Reset the lower counters to 0 or their --number-offset value
-- (Mirroring Pandoc's `--number-offset` behaviour
-- The counters table tells us which statement counters to reset.
--@param level number, the level to be incremented
function Setup:increment_counter(level)
	if self.counters[level] then

		self.counters[level].count = self.counters[level].count + 1

		if self.counters[level].reset then
			for _,kind_key in ipairs(self.counters[level].reset) do
				self.kinds[kind_key].count = 0
			end
		end

		for i = level + 1, 6 do
			if self.counters[i] then
				self.counters[i].count = PANDOC_WRITER_OPTIONS.number_offset[i]
																	or 0
			end
		end

	end
end
