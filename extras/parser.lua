-- Create a Setup.LOCALE definition from the Lyx file layouttranslations
-- Usage lua parser.lua > Setup.LOCALE.lua
-- source file must be named layouttranslations, part of LyX
--
-- Credit: LyX <www.lyx.org> contributors for the translations

-- MODEL; only the entries presented here will be copied
-- this also allows us to override LyX's translations
MODEL = {
		en = {
			theorem = 'Theorem',
			corollary = 'Corollary',
			lemma = 'Lemma',
			proposition = 'Proposition',
			conjecture = 'Conjecture',
			fact = 'Fact',
			definition = 'Definition',
			example = 'Example',
			problem = 'Problem',
			exercise = 'Exercise',
			solution = 'Solution',
			remark = 'Remark',
			claim = 'Claim',
			proof = 'Proof',
			axiom = 'Axiom',
			criterion = 'Criterion',
			algorithm = 'Algorithm',
			condition = 'Condition',
			note = 'Note',
			notation = 'Notation',
			summary = 'Summary',
			conclusion = 'Conclusion',
			assumption = 'Assumption',
			hypothesis = 'Hypothesis',
			question = 'Question',
		},
		de = {
			hypothesis = 'Annahme',
		},
		es = {
			hypothesis = 'Hipótesis',
		},
		fr = {
			proof = 'Démonstration',
			assumption = 'Supposition',
			hypothesis = 'Hypothèse',
		},
		it = {
			hypothesis = 'Ipotesi',
		}
}

-- return the LyX file as string
function read_file(name)
	local name = name or 'layouttranslations'
	f = io.open(name, 'r')
	if f then
		local contents = f:read('a')	
		f:close()
		return contents
	end
end

-- split the file by languages
function split_languages(str)
	local pattern = 'Translation%s(.-)\nEnd'
	local result = {}
	--local matches = string.gmatch(str, pattern)
	for match in str:gmatch(pattern) do
		result[#result + 1] = match
	end
	return result
end

-- parse a language into tag and dictionary
function parse_language(str)
	local tag = str:match('^%g+') -- first string of printable chars is lang label
	local dic = {}
	-- get rid of 'de_alt' language
	if tag == 'de_alt' then 
		return nil
	end
	-- tag is case-insensitive, must be lowercase
	tag = tag:lower()

	-- create the dictionary
	for line in str:gmatch('(.-)\n') do
		key,translation = line:match('"([%w%s]+)"%s"(.+)"')
		-- if key found, find its lua key in MODEL
		if key then
			for lua_key,eng in pairs(MODEL.en) do
				if eng == key then
					dic[lua_key] = translation
				end
			end
		end
	end
	return {
		tag = tag,
		dictionary = dic
	}
end

function find_in_list(list, needle)
	local result
	for i = 1, #list do
		if list[i] == needle then
			result = i
			break
		end
	end
	return result
end

-- locale: a langtag = dictionary map
--					each dictionary is a entry = translation (string) map
local locale = {} 
-- languages is the list of language tags (for alphabetical sorting)
local languages = {}
-- entries is the list of dictionary entries in MODEL (for alphabetical sorting)
local entries = {} -- list of keys in MODEL

-- read the file and split it into languages
local matches = split_languages(read_file())

-- create the locale table
for _,lang_str in pairs(matches) do
	local result = parse_language(lang_str, keys)
	if result then
		locale[result.tag] = result.dictionary
	end
end

-- tune the locale table
locale.pt = locale.pt_PT
locale.zh = locale.zh_CN

-- build a list of dictionary entries keys present in MODEL
for tag,dictionary in pairs(MODEL) do
	for k,_ in pairs(dictionary) do
		if not find_in_list(entries, k) then
			table.insert(entries, k)
		end
	end
end

-- compare locale and MODEL, insert missing / changed keys
for tag,dictionary in pairs(MODEL) do
	-- make a key by key comparison of the dictionaries
	if locale[tag] then
		for _,key in ipairs(entries) do
			if MODEL[tag][key] then
				if locale[tag][key] == MODEL[tag][key] then 
					-- io.stderr:write('Matching translation for '..key..'.\n')
				elseif locale[tag][key] then
					local lyx_version = locale[tag][key] or ''
					local my_version = MODEL[tag][key] or ''
					io.stderr:write('Lyx '..tag..' translation for '..key.. ', '
						..lyx_version ..' replaced by '..my_version..'.\n')
					locale[tag][key] = MODEL[tag][key]
				else -- no key in the LyX file, adding from MODEL
					io.stderr:write('No Lyx '..tag..' translation for '..key
						..', inserting '..MODEL[tag][key]..'.\n')
					locale[tag][key] = MODEL[tag][key]
				end
			end -- if MODEL[tag][key]
		end -- loop key in entries
	else 
		io.stderr:write('Language '..tag..' not found.\n')
	end
end
-- build a list of languages
for tag,_ in pairs(locale) do
	if not find_in_list(languages, tag) then
		table.insert(languages, tag)
	end
end
-- sort the entries and languages lists alphabetically
table.sort(entries)
table.sort(languages)

-- built the lua code to define the table, in clean alphabetical order
local result = 
[[--- Setup.LOCALE: localize statement labels
Setup.LOCALE = {
]]
for _,tag in ipairs(languages) do
	result = result .. '\t\t' .. tag .. ' = {\n'
	for _,entry in ipairs(entries) do
		if locale[tag][entry] then
			result = result.. '\t\t\t' .. entry .. ' = "' .. locale[tag][entry] .. '",\n'
		end
	end
	result = result .. '\t\t' .. '},\n'
end
result = result .. '}\n'
print(result)