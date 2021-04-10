local Log = require("api.Log")
local Rand = require("api.Rand")
local Stopwatch = require("api.Stopwatch")
local mod = require("internal.mod")
local fs = require("util.fs")
local dawg = require("internal.dawg")
local data = require("internal.data")

local i18n = {}
i18n.db = {}
i18n.index = nil
i18n.data = {}

local reify_one
reify_one = function(_db, item, key)
   if type(item) == "string" or type(item) == "function" then
      _db[key] = item
   elseif type(item) == "table" then
      if item[1] then
         -- List of options; one is chosen at random.
         _db[key] = item
      else
         -- Nested list of keys.
         for k, v in pairs(item) do
            local next_key
            if key == "" then
               next_key = k
            else
               next_key = key .. "." .. k
            end
            reify_one(_db, v, next_key)
         end
      end
   else
      error("unknown type: " .. key)
   end
end

function i18n.load_single_translation(path, merged, localize, namespace)
   path = fs.normalize(path)
   Log.debug("Loading translations at %s", path)
   local chunk, err = love.filesystem.load(path)

   if chunk == nil then
      error("Error loading translations:\n\t" .. err)
   end

   setfenv(chunk, i18n.env)

   local ok, result = xpcall(chunk, function(err) return debug.traceback(err, 2) end)

   if not ok then
      error("Error loading translations: " .. result)
   end
   if type(result) ~= "table" then
      error("Error loading translations: returned type not a table (" .. path .. ")")
   end

   reify_one(merged, result, "")

   for k, v in pairs(result) do
      local _type = namespace .. "." .. k
      if rawget(data, "schemas")[_type] then
         localize[_type] = localize[_type] or {}
         if type(v) == "table" and v._ then
            for mod_id, v in pairs(v._) do
               for name, v in pairs(v) do
                  local _id = ("%s.%s"):format(mod_id, name)
                  if data[_type][_id] then
                     localize[_type][_id] = {}
                     reify_one(localize[_type][_id], v, "")
                  end
               end
            end
         end
      end
   end
end

local load_translations
load_translations = function(path, merged, localize, namespace)
   merged[namespace] = merged[namespace] or {}

   for _, file in fs.iter_directory_items(path) do
      local full_path = fs.join(path, file)
      if fs.is_file(full_path) and fs.can_load(full_path) then
         i18n.load_single_translation(full_path, merged[namespace], localize, namespace)
      end
   end
end

i18n.load_translations = load_translations

function i18n.switch_language(lang, force)
   local lang_data = data["base.language"]:ensure(lang)
   i18n.language_id = lang
   i18n.language = lang_data.language_code
   local ok, env = pcall(require, "internal.i18n.env." .. i18n.language)
   if not ok then
      error(("Could not require I18N environment '%s': %s"):format(lang, env))
   end
   i18n.env = env

   i18n.env["get"] = i18n.get
   i18n.env["rnd"] = Rand.rnd

   if i18n.db[i18n.language] == nil or force then
      i18n.db[i18n.language] = {}
   end
   if i18n.data[i18n.language] == nil or force then
      i18n.data[i18n.language] = {}
   end

   i18n.index = nil

   local sw = Stopwatch:new()

   for _, mod in mod.iter_loaded() do
      local locale_folder = fs.join(mod.root_path, "locale")

      if fs.is_directory(locale_folder) then
         local path = fs.join(locale_folder, i18n.language)
         if fs.is_directory(path) then
            i18n.load_translations(path, i18n.db[i18n.language], i18n.data[i18n.language], "base")
            for _, item in fs.iter_directory_items(path) do
               local full_path = fs.join(path, item)
               if fs.is_directory(full_path) then
                  local namespace = item
                  i18n.load_translations(full_path, i18n.db[i18n.language], i18n.data[i18n.language], namespace)
               end
            end
         end
      end
   end

   Log.debug("Translations for language '%s' loaded in %02.02fms", i18n.language_id, sw:measure())
end

function i18n.get_language()
   return i18n.language
end

function i18n.get_language_id()
   return i18n.language_id
end

local function get_namespace_and_key(key)
   local pos = key:find(":")
   if pos == nil then
      -- If the namespace is omitted, assume it's `base`.
      return "base", key
   end

   return key:sub(1, pos-1), key:sub(pos+1)
end

function i18n.get_array(full_key, ...)
   local namespace, key = get_namespace_and_key(full_key)
   local entry = i18n.db[i18n.language][namespace][key]
   if not entry then
      return nil
   end

   if type(entry) == "table" and entry[1] then
      return entry
   elseif type(entry) ~= nil then
      return { entry }
   end

   return nil
end

function i18n.get(full_key, ...)
   local namespace, key = get_namespace_and_key(full_key)
   local entry = i18n.db[i18n.language][namespace][key]
   if not entry then
      return nil
   end

   if type(entry) == "table" and entry[1] then
      entry = Rand.choice(entry)
   end

   if type(entry) == "string" then
      return entry
   elseif type(entry) == "function" then
      local success, result = pcall(entry, ...)
      if not success then
         return ("<error [%s:%s]: %s>"):format(namespace, key, result)
      end
      return result
   end

   return nil
end

function i18n.localize(_type, _id, key, ...)
   local cache = i18n.data[i18n.language]

   if cache[_type] == nil then
      print(no1)
      return nil
   end
   local for_type = cache[_type]
   if for_type[_id] == nil then
      print("no2")
      return nil
   end

   local entry = for_type[_id][key]

   if type(entry) == "table" and entry[1] then
      entry = Rand.choice(entry)
   end

   if type(entry) == "string" then
      return entry
   elseif type(entry) == "function" then
      local success, result = pcall(entry, ...)
      if not success then
         return ("<error [%s:%s._%s]: %s>"):format(_type, _id, key, result)
      end
      return result
   end

   return nil
end

function i18n.capitalize(text)
   -- Find the "capitalize" function defined in the I18N environment.
   local cap = i18n.env.capitalize
   if type(cap) ~= "function" then
      return text
   end

   return cap(text)
end

function i18n.make_prefix_lookup()
   local d = dawg:new()
   local corpus = {}
   local add
   add = function(id, item)
      if type(item) == "string" then
         corpus[#corpus+1] = { item, id }
      elseif type(item) == "function" then
         local ok, result = pcall(item, {}, {}, {}, {}, {})
         if ok and type(result) == "string" then
            corpus[#corpus+1] = { result, id }
         end
      elseif type(item) == "table" then
         for _, v in ipairs(item) do
            add(id, v)
         end
      end
   end
   for id, item in pairs(i18n.db[i18n.language]) do
      add(id, item)
   end

   table.sort(corpus, function(a, b) return a[1] < b[1] end)

   for _, pair in ipairs(corpus) do
      d:insert(pair[1], pair[2])
   end

   d:finish()

   return d
end

function i18n.search(prefix)
   if i18n.index == nil then
      Log.warn("Building i18n search index.")
      i18n.index = i18n.make_prefix_lookup()
   end
   return i18n.index:search(prefix)
end

function i18n.on_hotload(old, new)
   table.replace_with(old, new)
   i18n.switch_language(old.language or "base.english")
end

return i18n
