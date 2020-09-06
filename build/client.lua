local loading = {}
local oldRequire, preload, loaded = require, {}, { startup = loading }

local function require(name)
	local result = loaded[name]

	if result ~= nil then
		if result == loading then
			error("loop or previous error loading module '" .. name .. "'", 2)
		end

		return result
	end

	loaded[name] = loading
	local contents = preload[name]
	if contents then
		result = contents(name)
	elseif oldRequire then
		result = oldRequire(name)
	else
		error("cannot load '" .. name .. "'", 2)
	end

	if result == nil then result = true end
	loaded[name] = result
	return result
end
preload["vendor.uuid"] = function(...)
-- https://gist.github.com/jrus/3197011

local random = math.random
return function()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end
end
preload["vendor.serpent"] = function(...)
local n, v = "serpent", "0.302" -- (C) 2012-18 Paul Kulchenko; MIT License
local c, d = "Paul Kulchenko", "Lua serializer and pretty printer"
local snum = {[tostring(1/0)]='1/0 --[[math.huge]]',[tostring(-1/0)]='-1/0 --[[-math.huge]]',[tostring(0/0)]='0/0'}
local badtype = {thread = true, userdata = true, cdata = true}
local getmetatable = debug and debug.getmetatable or getmetatable
local pairs = function(t) return next, t end -- avoid using __pairs in Lua 5.2+
local keyword, globals, G = {}, {}, (_G or _ENV)
for _,k in ipairs({'and', 'break', 'do', 'else', 'elseif', 'end', 'false',
  'for', 'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
  'return', 'then', 'true', 'until', 'while'}) do keyword[k] = true end
for k,v in pairs(G) do globals[v] = k end -- build func to name mapping
for _,g in ipairs({'coroutine', 'debug', 'io', 'math', 'string', 'table', 'os'}) do
  for k,v in pairs(type(G[g]) == 'table' and G[g] or {}) do globals[v] = g..'.'..k end end

local function s(t, opts)
  local name, indent, fatal, maxnum = opts.name, opts.indent, opts.fatal, opts.maxnum
  local sparse, custom, huge = opts.sparse, opts.custom, not opts.nohuge
  local space, maxl = (opts.compact and '' or ' '), (opts.maxlevel or math.huge)
  local maxlen, metatostring = tonumber(opts.maxlength), opts.metatostring
  local iname, comm = '_'..(name or ''), opts.comment and (tonumber(opts.comment) or math.huge)
  local numformat = opts.numformat or "%.17g"
  local seen, sref, syms, symn = {}, {'local '..iname..'={}'}, {}, 0
  local function gensym(val) return '_'..(tostring(tostring(val)):gsub("[^%w]",""):gsub("(%d%w+)",
    -- tostring(val) is needed because __tostring may return a non-string value
    function(s) if not syms[s] then symn = symn+1; syms[s] = symn end return tostring(syms[s]) end)) end
  local function safestr(s) return type(s) == "number" and tostring(huge and snum[tostring(s)] or numformat:format(s))
    or type(s) ~= "string" and tostring(s) -- escape NEWLINE/010 and EOF/026
    or ("%q"):format(s):gsub("\010","n"):gsub("\026","\\026") end
  local function comment(s,l) return comm and (l or 0) < comm and ' --[['..select(2, pcall(tostring, s))..']]' or '' end
  local function globerr(s,l) return globals[s] and globals[s]..comment(s,l) or not fatal
    and safestr(select(2, pcall(tostring, s))) or error("Can't serialize "..tostring(s)) end
  local function safename(path, name) -- generates foo.bar, foo[3], or foo['b a r']
    local n = name == nil and '' or name
    local plain = type(n) == "string" and n:match("^[%l%u_][%w_]*$") and not keyword[n]
    local safe = plain and n or '['..safestr(n)..']'
    return (path or '')..(plain and path and '.' or '')..safe, safe end
  local alphanumsort = type(opts.sortkeys) == 'function' and opts.sortkeys or function(k, o, n) -- k=keys, o=originaltable, n=padding
    local maxn, to = tonumber(n) or 12, {number = 'a', string = 'b'}
    local function padnum(d) return ("%0"..tostring(maxn).."d"):format(tonumber(d)) end
    table.sort(k, function(a,b)
      -- sort numeric keys first: k[key] is not nil for numerical keys
      return (k[a] ~= nil and 0 or to[type(a)] or 'z')..(tostring(a):gsub("%d+",padnum))
           < (k[b] ~= nil and 0 or to[type(b)] or 'z')..(tostring(b):gsub("%d+",padnum)) end) end
  local function val2str(t, name, indent, insref, path, plainindex, level)
    local ttype, level, mt = type(t), (level or 0), getmetatable(t)
    local spath, sname = safename(path, name)
    local tag = plainindex and
      ((type(name) == "number") and '' or name..space..'='..space) or
      (name ~= nil and sname..space..'='..space or '')
    if seen[t] then -- already seen this element
      sref[#sref+1] = spath..space..'='..space..seen[t]
      return tag..'nil'..comment('ref', level) end
    -- protect from those cases where __tostring may fail
    if type(mt) == 'table' and metatostring ~= false then
      local to, tr = pcall(function() return mt.__tostring(t) end)
      local so, sr = pcall(function() return mt.__serialize(t) end)
      if (to or so) then -- knows how to serialize itself
        seen[t] = insref or spath
        t = so and sr or tr
        ttype = type(t)
      end -- new value falls through to be serialized
    end
    if ttype == "table" then
      if level >= maxl then return tag..'{}'..comment('maxlvl', level) end
      seen[t] = insref or spath
      if next(t) == nil then return tag..'{}'..comment(t, level) end -- table empty
      if maxlen and maxlen < 0 then return tag..'{}'..comment('maxlen', level) end
      local maxn, o, out = math.min(#t, maxnum or #t), {}, {}
      for key = 1, maxn do o[key] = key end
      if not maxnum or #o < maxnum then
        local n = #o -- n = n + 1; o[n] is much faster than o[#o+1] on large tables
        for key in pairs(t) do if o[key] ~= key then n = n + 1; o[n] = key end end end
      if maxnum and #o > maxnum then o[maxnum+1] = nil end
      if opts.sortkeys and #o > maxn then alphanumsort(o, t, opts.sortkeys) end
      local sparse = sparse and #o > maxn -- disable sparsness if only numeric keys (shorter output)
      for n, key in ipairs(o) do
        local value, ktype, plainindex = t[key], type(key), n <= maxn and not sparse
        if opts.valignore and opts.valignore[value] -- skip ignored values; do nothing
        or opts.keyallow and not opts.keyallow[key]
        or opts.keyignore and opts.keyignore[key]
        or opts.valtypeignore and opts.valtypeignore[type(value)] -- skipping ignored value types
        or sparse and value == nil then -- skipping nils; do nothing
        elseif ktype == 'table' or ktype == 'function' or badtype[ktype] then
          if not seen[key] and not globals[key] then
            sref[#sref+1] = 'placeholder'
            local sname = safename(iname, gensym(key)) -- iname is table for local variables
            sref[#sref] = val2str(key,sname,indent,sname,iname,true) end
          sref[#sref+1] = 'placeholder'
          local path = seen[t]..'['..tostring(seen[key] or globals[key] or gensym(key))..']'
          sref[#sref] = path..space..'='..space..tostring(seen[value] or val2str(value,nil,indent,path))
        else
          out[#out+1] = val2str(value,key,indent,nil,seen[t],plainindex,level+1)
          if maxlen then
            maxlen = maxlen - #out[#out]
            if maxlen < 0 then break end
          end
        end
      end
      local prefix = string.rep(indent or '', level)
      local head = indent and '{\n'..prefix..indent or '{'
      local body = table.concat(out, ','..(indent and '\n'..prefix..indent or space))
      local tail = indent and "\n"..prefix..'}' or '}'
      return (custom and custom(tag,head,body,tail,level) or tag..head..body..tail)..comment(t, level)
    elseif badtype[ttype] then
      seen[t] = insref or spath
      return tag..globerr(t, level)
    elseif ttype == 'function' then
      seen[t] = insref or spath
      if opts.nocode then return tag.."function() --[[..skipped..]] end"..comment(t, level) end
      local ok, res = pcall(string.dump, t)
      local func = ok and "((loadstring or load)("..safestr(res)..",'@serialized'))"..comment(t, level)
      return tag..(func or globerr(t, level))
    else return tag..safestr(t) end -- handle all other types
  end
  local sepr = indent and "\n" or ";"..space
  local body = val2str(t, name, indent) -- this call also populates sref
  local tail = #sref>1 and table.concat(sref, sepr)..sepr or ''
  local warn = opts.comment and #sref>1 and space.."--[[incomplete output with shared/self-references skipped]]" or ''
  return not name and body..warn or "do local "..body..sepr..tail.."return "..name..sepr.."end"
end

local function deserialize(data, opts)
  local env = (opts and opts.safe == false) and G
    or setmetatable({}, {
        __index = function(t,k) return t end,
        __call = function(t,...) error("cannot call functions") end
      })
  local f, res = (loadstring or load)('return '..data, nil, nil, env)
  if not f then f, res = (loadstring or load)(data, nil, nil, env) end
  if not f then return f, res end
  if setfenv then setfenv(f, env) end
  return pcall(f)
end

local function merge(a, b) if b then for k,v in pairs(b) do a[k] = v end end; return a; end
return { _NAME = n, _COPYRIGHT = c, _DESCRIPTION = d, _VERSION = v, serialize = s,
  load = deserialize,
  dump = function(a, opts) return s(a, merge({name = '_', compact = true, sparse = true}, opts)) end,
  line = function(a, opts) return s(a, merge({sortkeys = true, comment = true}, opts)) end,
  block = function(a, opts) return s(a, merge({indent = '  ', sortkeys = true, comment = true}, opts)) end }
end
preload["vendor.json"] = function(...)
--
-- json.lua
--
-- Copyright (c) 2020 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "0.1.2" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
  [ "\\" ] = "\\",
  [ "\"" ] = "\"",
  [ "\b" ] = "b",
  [ "\f" ] = "f",
  [ "\n" ] = "n",
  [ "\r" ] = "r",
  [ "\t" ] = "t",
}

local escape_char_map_inv = { [ "/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end


local function escape_char(c)
  return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end


local function encode_nil(val)
  return "null"
end


local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  if rawget(val, 1) ~= nil or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      error("invalid table: sparse array")
    end
    -- Encode
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

  else
    -- Treat as an object
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end


local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
  -- Check for NaN, -inf and inf
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end


local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}


encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end


function json.encode(val)
  return ( encode(val) )
end


-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}


local function next_char(str, idx, set, negate)
  for i = idx, #str do
    if set[str:sub(i, i)] ~= negate then
      return i
    end
  end
  return #str + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                       f(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
  local n1 = tonumber( s:sub(1, 4),  16 )
  local n2 = tonumber( s:sub(7, 10), 16 )
   -- Surrogate pair?
  if n2 then
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)
  end
end


local function parse_string(str, i)
  local res = ""
  local j = i + 1
  local k = j

  while j <= #str do
    local x = str:byte(j)

    if x < 32 then
      decode_error(str, j, "control character in string")

    elseif x == 92 then -- `\`: Escape
      res = res .. str:sub(k, j - 1)
      j = j + 1
      local c = str:sub(j, j)
      if c == "u" then
        local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                 or str:match("^%x%x%x%x", j + 1)
                 or decode_error(str, j - 1, "invalid unicode escape in string")
        res = res .. parse_unicode_escape(hex)
        j = j + #hex
      else
        if not escape_chars[c] then
          decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
        end
        res = res .. escape_char_map_inv[c]
      end
      k = j + 1

    elseif x == 34 then -- `"`: End of string
      res = res .. str:sub(k, j - 1)
      return res, j + 1
    end

    j = j + 1
  end

  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  return n, x
end


local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end


local function parse_array(str, i)
  local res = {}
  local n = 1
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if str:sub(i, i) == "]" then
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i)
    res[n] = x
    n = n + 1
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "]" then break end
    if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
  end
  return res, i
end


local function parse_object(str, i)
  local res = {}
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if str:sub(i, i) == "}" then
      i = i + 1
      break
    end
    -- Read key
    if str:sub(i, i) ~= '"' then
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i)
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if str:sub(i, i) ~= ":" then
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i)
    -- Set
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = str:sub(i, i)
    i = i + 1
    if chr == "}" then break end
    if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
  end
  return res, i
end


local char_func_map = {
  [ '"' ] = parse_string,
  [ "0" ] = parse_number,
  [ "1" ] = parse_number,
  [ "2" ] = parse_number,
  [ "3" ] = parse_number,
  [ "4" ] = parse_number,
  [ "5" ] = parse_number,
  [ "6" ] = parse_number,
  [ "7" ] = parse_number,
  [ "8" ] = parse_number,
  [ "9" ] = parse_number,
  [ "-" ] = parse_number,
  [ "t" ] = parse_literal,
  [ "f" ] = parse_literal,
  [ "n" ] = parse_literal,
  [ "[" ] = parse_array,
  [ "{" ] = parse_object,
}


parse = function(str, idx)
  local chr = str:sub(idx, idx)
  local f = char_func_map[chr]
  if f then
    return f(str, idx)
  end
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true))
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end


return json
end
preload["shared.validate"] = function(...)
local validate = {}

local apierrors = require("shared.apierrors")

local function pchk(d, t)
    if type(d) ~= t then
        error({prim = t})
    end
end

validate.types = {
    Color = function()
        return function(d, key)
            pchk(d, "number")

            local cval = 1 + (math.log(d) / math.log(2))
            return (cval >= 1 and cval <= 16), apierrors.WTYPE("COLOR", key)
        end
    end,

    String = function(max, min)
        return function(d, key)
            pchk(d, "string")

            local len = #d
            if max and len > max then
                return false, apierrors.BOUND("# <= " .. max, key)
            end

            if min and len < min then
                return false, apierrors.BOUND("# >= " .. min, key)
            end

            return true
        end
    end,

    Bool = function()
        return function(d)
            pchk(d, "boolean")
            return true
        end
    end,

    Min = function(minval)
        return function(d, key)
            pchk(d, "number")
            return d >= minval, apierrors.BOUND(">= " .. minval, key)
        end
    end,

    Max = function(maxval)
        return function(d, key)
            pchk(d, "number")
            return d <= maxval, apierrors.BOUND("<= " .. maxval, key)
        end
    end,

    Tab = function(spec)
        return function(d, key)
            return validate:exec(d, spec, key .. ".")
        end
    end
}

function validate:exec(data, spec, path)
    path = path or ""

    if type(data) ~= "table" then
        return false, apierrors.INVALIDREQ
    end

    for key, validators in pairs(spec) do
        if data[key] == nil then
            return false, apierrors.MISSING(key)
        end

        local kpath = path .. key

        local datum = data[key]
        for _, validator in ipairs(validators) do
            local s, ev, err = pcall(validator, datum, kpath)
            if s then
                if not ev then
                    return false, err or apierrors.INVALIDREQ
                end
            else
                if type(ev) == "table" and ev.prim then
                    return false, apierrors.WTYPE(ev.prim, kpath)
                else
                    return false, apierrors.SVERR
                end
            end
        end
    end

    return true
end

setmetatable(validate, { __call = validate.exec })

return validate
end
preload["shared.tableutils"] = function(...)
local tableutils = {}

local function ultraShittyUnpack(t, i, n)
    if (n and i == n + 1) or not (n or t[i]) then return end
    return t[i], ultraShittyUnpack(t, i + 1)
end

function tableutils.unpack(tab, s, n)
    if table.unpack then
        return table.unpack(tab, s, n)
    elseif _G["unpack"] then
        return _G["unpack"](tab, s, n)
    else
        return ultraShittyUnpack(tab, s or 1, n)
    end
end

--- Packs the last `# - count` elements of the varargs, leaving the first `count` intact
--- Example: prepack(2, "a", "b", "c", "d", "e") = ("a", "b", {"c", "d", "e"})
function tableutils.postpack(count, ...)
    local prehand = {}
    local posthand = {}

    local values = {...}
    for i = 1, select("#", ...) do
        if count > 0 then
            table.insert(prehand, values[i])
            count = count - 1
        else
            table.insert(posthand, values[i])
        end
    end

    table.insert(prehand, posthand)
    return tableutils.unpack(prehand)
end

-- Produces a metatable which indexes as if the given tables were concatenated.
function tableutils.proxycat(...)
    local tabs = {...}
    local index = {}
    local i = 0
    for t = 1, #tabs do
        for j = 1, #tabs[t] do
            i = i + 1
            index[i] = {tabs[t], j}
        end
    end

    local function search(k)
        for t = 1, #tabs do
            if tabs[t][k] then
                return tabs[t][k]
            end
        end
    end

    return setmetatable({}, {
        __index = function(_, k)
            if index[k] then
                return index[k][1][index[k][2]]
            else
                return search(k)
            end
        end
    })
end

return tableutils
end
preload["shared.stringutils"] = function(...)
local stringutils = {}

function stringutils.explode(pattern, text)
    local result = {}
    while #text > 0 do
        local nextInst, endInst = text:find(pattern)
        if nextInst then
            table.insert(result, text:sub(1, nextInst - 1))
            table.insert(result, text:sub(nextInst, endInst))
            text = text:sub(endInst + 1)
        else
            table.insert(result, text)
            break
        end
    end

    return result
end

function stringutils.split(pattern, text)
    local result = {}
    while #text > 0 do
        local nextInst, endInst = text:find(pattern)
        if nextInst then
            table.insert(result, text:sub(1, nextInst - 1))
            text = text:sub(endInst + 1)
        else
            table.insert(result, text)
            break
        end
    end

    return result
end

return stringutils
end
preload["shared.socket.types"] = function(...)
local types = {}

types.SocketType = {
    INITIATOR = 1, COMPANION = 2
}

return types
end
preload["shared.socket"] = function(...)
local socket = {}

local uuid = require("vendor.uuid")

local logger = require("shared.logger")
local async = require("shared.async")
local fn = require("shared.funcutils")

local sockType = require("shared.socket.types")

socket.backends = {
    require("shared.socket.backends.modem")
}

local backend
for i = 1, #socket.backends do
    if socket.backends[i].tryInit() then
        backend = socket.backends[i]
        break
    end
end

if not backend then
    error("No socket backend could be initialized."
    .. " Please add attach a modem to your computer.")
end

socket.Socket = {}
function socket.Socket.new(bsocket)
    local self = {
        uuid = uuid(),
        bsocket = bsocket,
        handlers = {},
        request_handlers = {},
        active_requests = {},
        hid = 0,
        rid = 0
    }

    bsocket:onRecieve(fn.bind(socket.Socket.handleMsg, self))
    bsocket:onDisconnect(function()
        if self.onDisconnect then
            self:onDisconnect()
        end
    end)

    setmetatable(self, {
        __index = socket.Socket,
        __tostring = socket.Socket.tostring
    })
    return self
end

function socket.Socket:tostring()
    return "Socket<" .. tostring(self.bsocket) .. ">"
end

function socket.Socket:handleMsg(msg)
    logger.debug("Socket message:", msg)
    if msg.type == "event" then
        if type(msg.data) == "table" then
            if self.handlers[msg.event] then
                for _, handler in ipairs(self.handlers[msg.event]) do
                    handler.callback(msg.data)
                end
            else
                logger.warn("Received unrouted event", msg.event, msg.data)
            end
        end
    elseif msg.type == "request" then
        if type(msg.rid) ~= "number" then return end
        if self.request_handlers[msg.request] then
            self.request_handlers[msg.request]({
                succeed = function(response)
                    self.bsocket:write({
                        ok=true,
                        type="response",
                        rid=msg.rid,
                        data=response
                    })
                end,
                fail = function(err)
                    self.bsocket:write({
                        ok=false,
                        type="response",
                        rid=msg.rid,
                        error=err
                    })
                end
            }, msg.data)
        else
            logger.error("Invalid endpoint '" .. msg.request .. "' requested")
            self.bsocket:write({
                ok=false,
                type="response",
                rid=msg.rid,
                error="No such request defined"
            })
        end
    elseif msg.type == "response" then
        if type(msg.rid) ~= "number" then return end
        if self.active_requests[msg.rid] then
            if msg.ok then
                self.active_requests[msg.rid][1](msg.data)
                self.active_requests[msg.rid] = nil
            else
                self.active_requests[msg.rid][2](msg.error)
                self.active_requests[msg.rid] = nil
            end
        end
    end
end

function socket.Socket:handleDisconnect(callback)
    self.onDisconnect = callback
end

function socket.Socket:request(rtype, data)
    self.rid = (self.rid + 1) % 2^32
    return async.Promise.new(function(resolve, reject)
        self.active_requests[self.rid] = {resolve, reject}
        self.bsocket:write({
            type="request",
            request=rtype,
            rid = self.rid,
            data = data or {}
        })
    end)
end

function socket.Socket:emit(event, data)
    self.bsocket:write({
        type="event",
        event = event,
        data = data
    })
end

function socket.Socket:handle(rtype, func)
    self.request_handlers[rtype] = func
end

function socket.Socket:on(event, callback)
    self.hid = self.hid + 1
    self.handlers[event] = self.handlers[event] or {}
    table.insert(self.handlers[event], {
        hid = self.hid,
        callback = callback
    })

    return self.hid
end

function socket.Socket:off(event, hid)
    local hlist = self.handlers[event]
    if not hlist then return end
    for i = 1, #hlist do
        if hlist[i].hid == hid then
            table.remove(hlist, i)
            break
        end
    end
end

local handleSocketConnection = async { function(onNewSocket, sock)
    logger.debug("BSocket Connection:", sock.uid)
    -- local msgQueue = {}



    -- TODO: Encryption?
    -- if sock.type == sockType.SocketType.COMPANION then
    --     -- We go first.
    --     -- sock:write()
    -- else -- INITIATOR

    -- end

    onNewSocket(socket.Socket.new(sock))
    -- onConnectionEstablished()
end }

function socket.listen(options, onNewSocket)
    backend.listen(fn.bind(handleSocketConnection, onNewSocket), options)
end

function socket.connect(options)
    return backend.connect(options):next(socket.Socket.new)
end

return socket
end
preload["shared.socket.backends.modem"] = function(...)
local modemBackend = {}

local json = require("vendor.json")
local uuid = require("vendor.uuid")

local gcm = require("shared.gcm")
local async = require("shared.async")
local logger = require("shared.logger")
local tableutils = require("shared.tableutils")
local coroutines = require("shared.coroutines")

local sockType = require("shared.socket.types")

local defaultPort = 14762
local modem

modemBackend.ModemError = {
    UID_TAKEN = { id=1, description="UID already taken, please use another" },
    INVALID_OPTS = { id=2, description="Connection options are invalid" }
}
local ModemError = modemBackend.ModemError

modemBackend.ModemSocketStatus = {
    CONNECTING = 1,
    READY = 2,
    DEAD = 3
}
local ModemSocketStatus = modemBackend.ModemSocketStatus

local ModemSocket = {}

function ModemSocket.new(uid, port, stype)
    local self = {
        uid = uid,
        port = port,
        type = stype,
        status = ModemSocketStatus.CONNECTING,
        handlers = {},
        last_active = os.clock()
    }

    setmetatable(self, {
        __index = ModemSocket,
        __tostring = ModemSocket.tostring
    })

    -- Spawn listen thread
    self:spawnListener()

    return self
end

function ModemSocket:tostring()
    return "MSock<" .. tostring(self.uid) .. ">"
end

function ModemSocket:write(data)
    modem.transmit(self.port, self.port,
        json.encode({
            type="data",
            uid=self.uid,
            port=self.port,
            data=data
        }))
end

function ModemSocket:ping()
    logger.trace("Transmitting on port", self.port)
    modem.transmit(self.port, self.port,
        json.encode({
            type="ping",
            uid=self.uid,
            port=self.port
        }))
end

function ModemSocket:onRecieve(callback)
    table.insert(self.handlers, callback)
end

function ModemSocket:onDisconnect(callback)
    self.dcHandler = callback
end

function ModemSocket:spawnListener()
    gcm:addRoutine(function()
        self.status = ModemSocketStatus.READY

        while true do
            local event, evdata = tableutils.postpack(1, coroutine.yield("modem_message_data"))
            if event == "modem_message_data" then
                local data = tableutils.unpack(evdata)
                if data.type == "data" and data.uid == self.uid and type(data.data) == "table" then
                    self.last_active = os.clock()

                    logger.debug("MSocket", self.uid, "received:", data)
                    if #self.handlers == 0 then
                        logger.warn("Discarding unhandled modem message.")
                    end

                    for i = 1, #self.handlers do
                        self.handlers[i](data.data)
                    end
                elseif data.type == "ping" then
                    logger.trace("Recieved ping, sending pong!")
                    modem.transmit(self.port, self.port, json.encode({
                        type = "pong",
                        uid = self.uid,
                        port = self.port
                    }))
                elseif data.type == "pong" and data.uid == self.uid then
                    self.last_active = os.clock()
                    logger.trace("Recieved pong from", self.uid)
                end
            end
        end
    end)
end


function modemBackend.tryInit()
    if not peripheral then return end
    modem = peripheral.find("modem")
    if modem then
        logger.debug("Using " .. (
            modem.isWireless() and "wireless" or ""
        ) .. " modem for socket backend")

        return true
    end
end

function modemBackend.listen(callback, options)
    options = options or {}

    local port = options.port or defaultPort
    modem.open(port)
    logger.debug("Modem backend opened port " .. port .. " for connections")

    local activeSockets = {}
    local channelPortMap = {}

    local function tryClosePortMap(socket)
        local mapping = channelPortMap[socket.port]
        if not mapping then
            logger.error("Socket was never inserted into portmap?")

            return -- Don't close the port since apparently it was never opened?
        end

        if socket.dcHandler then
            socket:dcHandler()
        end

        for i = 1, #mapping do
            if mapping[i] == socket.uid then
                table.remove(mapping, i)
            end
        end

        if #mapping == 0 then
            logger.debug("Closing port " .. socket.port)
            modem.close(socket.port)
            channelPortMap[socket.port] = nil
        end
    end

    local function tryConnect(data, reply)
        if options.service ~= data.service then
            return -- Not meant for us
        end

        logger.debug("Attempted connection on port " .. reply .. " by " .. tostring(data.uid))

        if type(data.uid) ~= "string" and type(data.port) ~= "number" then
            return modem.transmit(reply, 65535,
                json.encode({ type="connect", uid=data.uid, ok=false, error=ModemError.INVALID_OPTS }))
        end

        if activeSockets[data.uid] then
            logger.debug("Connector tried to take existing uid")
            return modem.transmit(reply, 65535,
                json.encode({ type="connect", uid=data.uid, ok=false, error=ModemError.UID_TAKEN }))
        end

        activeSockets[data.uid] = ModemSocket.new(data.uid, data.port, sockType.SocketType.COMPANION)
        if not channelPortMap[data.port] then
            logger.debug("Opening port " .. data.port)
            modem.open(data.port)
            channelPortMap[data.port] = {}
        end

        table.insert(channelPortMap[data.port], data.uid)
        callback(activeSockets[data.uid])

        return modem.transmit(data.port, data.port,
            json.encode({ type="connect", uid=data.uid, ok=true }))
    end

    coroutines.loop(
        function() -- Ping check thread
            while true do
                coroutines.runTimer(10)

                for id, socket in pairs(activeSockets) do
                    socket:ping()

                    if os.clock() - socket.last_active > 30 then
                        logger.warn(socket, " is not responding to pings, dropping...")

                        -- Drop the connection
                        activeSockets[id] = nil

                        -- Try to close the port
                        tryClosePortMap(socket)
                    end
                end
            end
        end, function() -- Connection thread
            local servStr = options.service and ("for '" .. options.service .. "'") or ""
            logger.info("Modem backend now listening on port " .. port, servStr)

            while true do
                local event, evdata = tableutils.postpack(1, coroutine.yield("modem_message"))
                if event == "modem_message" then
                    local _, _, reply, msg = tableutils.unpack(evdata)
                    local success, data = pcall(json.decode, msg)
                    if success and type(data) == "table" then
                        if data.type == "connect" then
                            tryConnect(data, reply)
                        else
                            os.queueEvent("modem_message_data", data)
                        end
                    else
                        logger.debug("Invalid JSON received: '" .. msg .. "'")
                    end
                end
            end
        end)
end

local function genPort()
    return math.random(1000, 9999)
end

function modemBackend.connect(options)
    return async.Promise.new(function(resolve, reject)
        options = options or {}
        local port = options.port or defaultPort
        local selfPort = options.selfPort or genPort()
        local uid = uuid()

        modem.open(selfPort)
        modem.transmit(port, selfPort, json.encode({
            type = "connect",
            uid = uid,
            port = selfPort,
            service = options.service
        }))
            --'{"type":"connect","uid":"' .. uid .. '","port":9876}')
        gcm:addRoutine(function()
            while true do
                local event, evdata = tableutils.postpack(1, coroutine.yield("modem_message"))
                if event == "modem_message" then
                    local _, _, _, msg = tableutils.unpack(evdata)
                    local success, data = pcall(json.decode, msg)
                    if success and type(data) == "table" then
                        logger.trace("Modem message:", data)

                        if data.type == "connect" and data.uid == uid then
                            if data.ok then
                                if options.service then
                                    logger.info("Established connection to '" .. options.service .. "' as", uid)
                                else
                                    logger.info("Connection established!")
                                end
                                resolve(ModemSocket.new(uid, selfPort, sockType.SocketType.INITIATOR))
                            else
                                logger.error("Error establishing connection:", data.error)
                                reject(data.error)
                            end
                        else
                            os.queueEvent("modem_message_data", data)
                        end
                    else
                        logger.debug("Invalid JSON received: '" .. msg .. "'")
                    end
                end
            end
        end)
    end)
end

return modemBackend
end
preload["shared.pretty"] = function(...)
local pretty = {}

local syntaxTheme = {
    keyword = colors.purple,
    specialKeyword = colors.lightBlue,
    func = colors.cyan,
    string = colors.red,
    stringEscape = colors.yellow,
    primitive = colors.orange,
    comment = colors.lightGray,
    cref = colors.lightGray,
    catch = colors.white
}

local keywords = {
  [ "and" ] = true, [ "break" ] = true, [ "do" ] = true, [ "else" ] = true,
  [ "elseif" ] = true, [ "end" ] = true, [ "false" ] = true, [ "for" ] = true,
  [ "function" ] = true, [ "if" ] = true, [ "in" ] = true, [ "local" ] = true,
  [ "nil" ] = true, [ "not" ] = true, [ "or" ] = true, [ "repeat" ] = true, [ "return" ] = true,
  [ "then" ] = true, [ "true" ] = true, [ "until" ] = true, [ "while" ] = true,
}

local curColor
local function pwrite(text, color)
    if color ~= curColor then
        term.setTextColor(color)
        curColor = color
    end

    write(text)
end

local function prettySort(a, b)
    local ta, tb = type(a), type(b)

    if ta == "string" then return tb ~= "string" or a < b
    elseif tb == "string" then return false end

    if ta == "number" then return tb ~= "number" or a < b end

    return false
end

local debugInfo = (type(debug) == "table" and type(debug.getinfo) == "function" and debug.getinfo)

local function getFunctionArgs(func)
if debugInfo then
local args = {}
local hook = debug.gethook()

local argHook = function()
    local info = debugInfo(3)
    if info.name ~= "pcall" then return end

    for i = 1, math.huge do
        local name = debug.getlocal(2, i)

        if name == "(*temporary)" or not name then
            debug.sethook(hook)
            return error()
        end

        args[#args + 1] = name
    end
end

debug.sethook(argHook, "c")
pcall(func)

return args
end
end

local function prettyFunction(fn)
if debugInfo then
local info = debugInfo(fn, "S")
if info.short_src and info.linedefined and info.linedefined >= 1 then
    local args
    if info.what == "Lua" then
        args = getFunctionArgs(fn)
    end

    if args then
        return "function<" .. info.short_src .. ":" .. info.linedefined .. ">(" .. table.concat(args, ", ") .. ")"
        else
            return "function<" .. info.short_src .. ":" .. info.linedefined .. ">"
            end
        end
    end

    return tostring(fn)
end

local function prettySize(obj, tracking, limit)
    local objType = type(obj)
    if objType == "string" then return #string.format("%q", obj):gsub("\\\n", "\\n")
    elseif objType == "function" then return #prettyFunction(obj)
    elseif objType ~= "table" or tracking[obj] then return #tostring(obj) end

    local count = 2
    tracking[obj] = true
    for k, v in pairs(obj) do
        count = count + prettySize(k, tracking, limit) + prettySize(v, tracking, limit)
        if count >= limit then break end
    end
    tracking[obj] = nil
    return count
end

local function prettyImpl(obj, tracking, width, height, indent, tupleLength)
    local objType = type(obj)
    if objType == "string" then
        local formatted = string.format("%q", obj):gsub("\\\n", "\\n")

        local limit = math.max(8, math.floor(width * height * 0.8))

        if #formatted > limit then
            pwrite(formatted:sub(1, limit-3), syntaxTheme.string)
            pwrite("...", syntaxTheme.string)
        else
            pwrite(formatted, syntaxTheme.string)
        end

        return
    elseif objType == "number" then
        return pwrite(tostring(obj), syntaxTheme.primitive)
    elseif objType == "boolean" then
        return pwrite(tostring(obj), syntaxTheme.primitive)
    elseif objType == "function" then
        return pwrite(prettyFunction(obj), syntaxTheme.func)
    elseif objType ~= "table" or tracking[obj] then
        return pwrite(tostring(obj), syntaxTheme.cref)
    elseif (getmetatable(obj) or {}).__tostring then
        return pwrite(tostring(obj), syntaxTheme.catch)
    end

    local open, close = "{", "}"
    if tupleLength then open, close = "(", ")" end

    if (tupleLength == nil or tupleLength == 0) and next(obj) == nil then
        return pwrite(open .. close, syntaxTheme.catch)
    elseif width <= 7 then
        pwrite(open, syntaxTheme.catch)
        pwrite(" ... ", syntaxTheme.cref)
        pwrite(close, syntaxTheme.catch)
        return
    end

    local shouldNewline = false
    local length = tupleLength or #obj

    local size, children, keys, kn = 2, 0, {}, 0
    for k, v in pairs(obj) do
        if type(k) == "number" and k >= 1 and k <= length and k % 1 == 0 then
            local vs = prettySize(v, tracking, width)
            size = size + vs + 2
            children = children + 1
        else
            kn = kn + 1
            keys[kn] = k

            local vs, ks = prettySize(v, tracking, width), prettySize(k, tracking, width)
            size = size + vs + ks + 2
            children = children + 2
        end

        if size >= width * 0.6 then shouldNewline = true end
    end

    if shouldNewline and height <= 1 then
        pwrite(open, syntaxTheme.catch)
        pwrite(" ... ", syntaxTheme.cref)
        pwrite(close, syntaxTheme.catch)
        return
    end

    table.sort(keys, prettySort)

    local nextNewline, subIndent, childWidth, childHeight
    if shouldNewline then
        nextNewline, subIndent = ",\n", indent .. " "

        height = height - 2
        childWidth, childHeight = width - 2, math.ceil(height / children)

        if children > height then children = height - 2 end
    else
        nextNewline, subIndent = ", ", ""

        width = width - 2
        childWidth, childHeight = math.ceil(width / children), 1
    end

    pwrite(open .. (shouldNewline and "\n" or " "), syntaxTheme.catch)

    tracking[obj] = true
    local seen = {}
    local first = true
    for k = 1, length do
        if not first then pwrite(nextNewline, syntaxTheme.catch) else first = false end
        pwrite(subIndent, syntaxTheme.catch)

        seen[k] = true
        prettyImpl(obj[k], tracking, childWidth, childHeight, subIndent)

        children = children - 1
        if children < 0 then
            if not first then pwrite(nextNewline, syntaxTheme.catch) else first = false end
            pwrite(subIndent .. "...", syntaxTheme.cref)
            break
        end
    end

    for i = 1, kn do
        local k, v = keys[i], obj[keys[i]]
        if not seen[k] then
            if not first then pwrite(nextNewline, syntaxTheme.catch) else first = false end
            pwrite(subIndent, syntaxTheme.catch)

            if type(k) == "string" and not keywords[k] and k:match("^[%a_][%a%d_]*$") then
                pwrite(k .. " = ", syntaxTheme.catch)
                prettyImpl(v, tracking, childWidth, childHeight, subIndent)
            else
                pwrite("[", syntaxTheme.catch)
                prettyImpl(k, tracking, childWidth, childHeight, subIndent)
                pwrite("] = ", syntaxTheme.catch)
                prettyImpl(v, tracking, childWidth, childHeight, subIndent)
            end

            children = children - 1
            if children < 0 then
                if not first then pwrite(nextNewline, syntaxTheme.catch) end
                pwrite(subIndent .. "...", syntaxTheme.cref)
                break
            end
        end
    end
    tracking[obj] = nil

    pwrite((shouldNewline and "\n" .. indent or " ") .. (tupleLength and ")" or "}"), syntaxTheme.catch)
end

local function prettyp(t, n)
    local width, height = term.getSize()
    prettyImpl(t, {}, width, height - 2, "", n)
end

function pretty.write(...)
    local n = select("#", ...)
    if n > 1 then
        prettyp({...}, n)
    else
        local value = (...)
        prettyp(value)
    end
end

function pretty.print(...)
    pretty.write(...)
    print()
end

return pretty
end
preload["shared.logger"] = function(...)
local defaultLogLevel = _G.LOG_LEVEL or "info"
local logger = {}

logger.LogLevels = {
    "off", OFF = "off",
    "fatal", FATAL = "fatal",
    "error", ERROR = "error",
    "warn", WARN = "warn",
    "info", INFO = "info",
    "debug", DEBUG = "debug",
    "trace", TRACE = "trace",
    ALL = "all"
}

local instance -- Logger is setup as singleton
function logger.init(backends, options)
    backends = backends or {}
    options = options or {}

    if instance then
        error("Logger already initialized. Use logger.destroy() to reset.", 2)
    end

    for i = 1, #backends do
        local backend = backends[i]
        for _, level in ipairs(logger.LogLevels) do
            if not backend[level] and not backend.generic then
                error("Backend #" .. i .. " (" .. tostring(backend) .. ") does"
                .. " not implement '" .. level .. "' and does not provide a"
                .. " generic logger method.")
            end
        end
    end

    local maxLevel = options.level or defaultLogLevel
    local enabledLevels = {}
    for _, level in ipairs(logger.LogLevels) do
        enabledLevels[level] = true
        if level == maxLevel then
            break
        end
    end

    instance = {
        backends = backends,
        options = options,
        enabledLevels = enabledLevels
    }
end

function logger.destroy()
    for i = 1, #instance.backends do
        local bk = instance.backends[i]
        if bk.destroy then
            bk:destroy()
        end
    end

    instance = nil
end

-------------------------------------
local function checkValid(level)
    if not instance then
        error("Logger not initialized, use logger.init first", 4)
    end

    if not instance.enabledLevels[level] then
        return false
    end

    return true
end

local function dispatch(level, valueList)
    if not checkValid(level) then return end

    for _, backend in ipairs(instance.backends) do
        if backend[level] then
            backend[level](backend, valueList)
        else
            backend:generic(level, valueList)
        end
    end
end

function logger.fatal(...)
    dispatch("fatal", {...})
end

function logger.error(...)
    dispatch("error", {...})
end

function logger.warn(...)
    dispatch("warn", {...})
end

function logger.info(...)
    dispatch("info", {...})
end

function logger.debug(...)
    dispatch("debug", {...})
end

function logger.trace(...)
    dispatch("trace", {...})
end

return logger
end
preload["shared.logger.backends.file"] = function(...)
local file = {}

local serpent = require("vendor.serpent")

function file.new(filename)
    local self = {
        handle = fs.open(filename, "a")
    }

    return setmetatable(self, {__index = file})
end

function file:generic(level, text)
    local str = ("[%s] [%s]"):format(tostring(os.epoch("utc")), level:upper())
    for i = 1, #text do
        str = str .. " "
        local val = text[i]
        if type(val) == "string" then
            str = str .. val
        elseif (getmetatable(val) or {}).__tostring then
            str = str .. tostring(val)
        else
            str = str .. serpent.block(val)
        end
    end

    self.handle.write(str .. "\n")
    self.handle.flush()
end

function file:destroy()
    self.handle.close()
end

return file
end
preload["shared.logger.backends.console"] = function(...)
local console = {}

local stringutils = require("shared.stringutils")
local tableutils = require("shared.tableutils")
local pretty = require("shared.pretty")

function console.new()
    local self = {}
    return setmetatable(self, {__index = console})
end

local function setBG(c)
    if term.isColor() then
        term.setBackgroundColor(c)
    end
end

local function setFG(c)
    if term.isColor() then
        term.setTextColor(c)
    end
end

local function cprintf(fmt, ...)
    local instructions = stringutils.explode("%%.", fmt)
    local values = {...}
    for _, instr in ipairs(instructions) do
        if instr:match("^%%.$") then
            local w = instr:sub(2)
            if w == "B" then
                setBG(table.remove(values, 1))
            elseif w == "C" then
                setFG(table.remove(values, 1))
            elseif w == "R" then
                setBG(colors.black)
                setFG(colors.white)
            elseif w == "s" then
                local val = table.remove(values, 1)
                if type(val) == "string" then
                    write(val)
                else
                    pretty.write(val)
                end
            elseif w == "v" then
                local tab = table.remove(values, 1)
                local n = #tab
                for i = 1, n do
                    local val = tab[i]
                    if type(val) == "string" then
                        write(val)
                    else
                        pretty.write(val)
                    end

                    if i ~= n then
                        write(" ")
                    end
                end
            end
        else
            -- local this = {}
            -- for p in instr:gmatch("%%.") do
            --     if p ~= "%%" then
            --         table.insert(this, table.remove(values, 1))
            --     end
            -- end

            write(instr)--:format(tableutils.unpack(this)))
        end
    end
    print()
end

function console:generic(level, text)
    cprintf("%C[%s] %R%v", colors.lightGray, level:upper(), text)
end

function console:trace(text)
    cprintf("%C[TRACE] %R%C%v", colors.gray, colors.lightGray, text)
end

function console:debug(text)
    cprintf("%C[DEBUG] %R%v", colors.purple, text)
end

function console:info(text)
    cprintf("%C[INFO] %R%v", colors.cyan, text)
end

function console:warn(text)
    cprintf("%C[WARN] %R%v", colors.yellow, text)
end

function console:error(text)
    cprintf("%C[ERROR] %R%v", colors.red, text)
end

function console:fatal(text)
    cprintf("%B%C[FATAL]%R %C%v\n", colors.red, colors.white, colors.red, text)
end


return console
end
preload["shared.gcm"] = function(...)
local Manager = require("shared.coroutines").Manager
return Manager.new()
end
preload["shared.funcutils"] = function(...)
local funcutils = {}

local tableutils = require("shared.tableutils")

function funcutils.bind(fn, ...)
    local n = select("#", ...)
    local bound = {...}
    return function(...)
        local rn = select("#", ...)
        local rargs = {...}

        local args = {}
        for i = 1, n do
            args[i] = bound[i]
        end

        for i = 1, rn do
            args[i + n] = rargs[i]
        end

        return fn(tableutils.unpack(args, 1, n + rn))
    end
end

return funcutils
end
preload["shared.encrypt"] = function(...)
local encrypt = {}

local bit64 = require("shared.bit64")

local prime_bank = {
    0xffffffc5,0xffffffad,0xffffffa1,0xffffff4d,0xffffff43,0xfffffeff,0xfffffee9,
    0xfffffebd,0xfffffe9f,0xfffffe95,0xfffffe57,0xfffffe3b,0xfffffe09,0xfffffd19,
    0xfffffcc7,0xfffffcb5,0xfffffcb3,0xfffffc7f,0xfffffc7d,0xfffffc59,0xfffffc4f,
    0xfffffc01,0xfffffbff,0xfffffbcb,0xfffffbc9,0xfffffb2d,0xfffffb05,0xfffffad5,
    0xfffffa9d,0xfffffa43,0xfffffa3d,0xfffffa31,0xfffffa1f,0xfffffa13,0xfffff9df,
    0xfffff9d1,0xfffff9b9,0xfffff97f,0xfffff925,0xfffff8f9,0xfffff8f3,0xfffff8d1,
    0xfffff8bd,0xfffff8a5,0xfffff863,0xfffff835,0xfffff82d,0xfffff80f,0xfffff803,
    0xfffff7cf,0xfffff7ab,0xfffff781,0xfffff733,0xfffff713,0xfffff70f,0xfffff6fb,
    0xfffff6b5,0xfffff661,0xfffff643,0xfffff60b,0xfffff605,0xfffff5db,0xfffff5b7,
    0xfffff563,0xfffff557,0xfffff53b,0xfffff52f,0xfffff509,0xfffff49f,0xfffff437,
    0xfffff42b,0xfffff40d,0xfffff3df,0xfffff3d7,0xfffff3d1,0xfffff3c1,0xfffff36d,
    0xfffff367,0xfffff35b,0xfffff341,0xfffff33d,0xfffff2ff,0xfffff2ef,0xfffff2cf,
    0xfffff2a1,0xfffff257,0xfffff229,0xfffff215,0xfffff12d,0xfffff115,0xfffff101,
    0xfffff0d3,0xfffff0bb,0xfffff095,0xfffff089,0xfffff011,0xfffff001,0xffffefe1,
    0xffffefd1,0xffffefcf,0xffffef6b,0xffffef5d,0xffffef35,0xffffef27,0xffffee6d,
    0xffffee4f,0xffffedfb,0xffffed91,0xffffed7f,0xffffed79,0xffffed59,0xffffecf3,
    0xffffece9,0xffffeca1,0xffffec93,0xffffec69,0xffffec41,0xffffec2d,0xffffebfd,
    0xffffebbd,0xffffeba9,0xffffeb97,0xffffeb7b,0xffffeb61,0xffffeb5d,0xffffeb31,
    0xffffeb1f,0xffffeb0d,0xffffeb07,0xffffea6d,0xffffea5f,0xffffea2b,0xffffe9e1,
    0xffffe9b7,0xffffe98f,0xffffe959,0xffffe951,0xffffe933,0xffffe90f,0xffffe8e1,
    0xffffe8d9,0xffffe8cd,0xffffe8c9,0xffffe8bd,0xffffe869,0xffffe83d,0xffffe7cd,
    0xffffe711,0xffffe70d,0xffffe6d1,0xffffe695,0xffffe5f3,0xffffe5ed,0xffffe587,
    0xffffe50d,0xffffe4fb,0xffffe4b9,0xffffe4b3,0xffffe4af,0xffffe48f,0xffffe485,
    0xffffe47d,0xffffe45b,0xffffe401,0xffffe3cf,0xffffe357,0xffffe34d,0xffffe31d,
    0xffffe267,0xffffe243,0xffffe201,0xffffe1ef,0xffffe1e9,0xffffe1dd,0xffffe17f,
    0xffffe147,0xffffe113,0xffffe0d7,0xffffe095,0xffffe027,0xffffdf8d,0xffffdf81,
    0xffffdf5b,0xffffdf37,0xffffdf13,0xffffdef7,0xffffded7,0xffffdecd,0xffffde9d,
    0xffffde73,0xffffde4f,0xffffde4d,0xffffde2f,0xffffde29,0xffffde19,0xffffdde1,
    0xffffddd5,0xffffddc5,0xffffdd89,0xffffdd5f,0xffffdd3f,0xffffdd39,0xffffdce5,
    0xffffdcb7,0xffffdc99,0xffffdc7f,0xffffdc63,0xffffdc43,0xffffdc3f,0xffffdc2b,
    0xffffdb73,0xffffda05,0xffffd9db,0xffffd9b5,0xffffd997,0xffffd979,0xffffd973,
    0xffffd8f5,0xffffd8a3,0xffffd88f,0xffffd871,0xffffd853,0xffffd823,0xffffd789,
    0xffffd759,0xffffd753,0xffffd733,0xffffd6ff,0xffffd6f9,0xffffd6cd,0xffffd681,
    0xffffd657,0xffffd631,0xffffd62b,0xffffd5b9,0xffffd591,0xffffd573,0xffffd565,
    0xffffd529,0xffffd475,0xffffd463,0xffffd459,0xffffd447,0xffffd433,0xffffd405,
    0xffffd3c3,0xffffd3b7,0xffffd397,0xffffd36f,0xffffd369,0xffffd2fd,0xffffd2df,
    0xffffd2d1,0xffffd2ad,0xffffd261,0xffffd21f,0xffffd1ff,0xffffd169,0xffffd163,
    0xffffd11b,0xffffd109,0xffffd0df,0xffffd0af,0xffffd05d,0xffffd04b,0xffffd021,
    0xffffd009,0xffffcf9d,0xffffcf37,0xffffcf25,0xffffced7,0xffffcec9,0xffffcec3,
    0xffffce7d,0xffffce4d,0xffffce03,0xffffcdd5,0xffffcdbb,0xffffcda3,0xffffcd75,
    0xffffcd3d,0xffffcd07,0xffffccc5,0xffffcc9b,0xffffcc91,0xffffcc8b,0xffffcc85,
    0xffffcc59,0xffffcc2b,0xffffcc0d,0xffffcbe1,0xffffcb87,0xffffcb83,0xffffcb4b,
    0xffffcb35,0xffffcae7,0xffffca75,0xffffca4f,0xffffca3d,0xffffca39,0xffffca31,
    0xffffca2d,0xffffca1f,0xffffca01,0xffffc9e3,0xffffc9bb,0xffffc989,0xffffc961,
    0xffffc935,0xffffc8db,0xffffc8b1,0xffffc8a7,0xffffc881,0xffffc833,0xffffc7e5,
    0xffffc7d9,0xffffc7cf,0xffffc7c3,0xffffc781,0xffffc769,0xffffc757,0xffffc755,
    0xffffc713,0xffffc6e5,0xffffc6c7,0xffffc65f,0xffffc623,0xffffc5d7,0xffffc5cf,
    0xffffc5c3,0xffffc577,0xffffc541,0xffffc4fd,0xffffc4eb,0xffffc4d5,0xffffc4cf,
    0xffffc4ab,0xffffc491,0xffffc449,0xffffc403,0xffffc3bf,0xffffc3a1,0xffffc39d,
    0xffffc349,0xffffc347,0xffffc227,0xffffc221,0xffffc1fd,0xffffc1df,0xffffc185,
    0xffffc173,0xffffc163,0xffffc137,0xffffc12b,0xffffc0f1,0xffffc0ef,0xffffc0e5,
    0xffffc0b9,0xffffc0a7,0xffffc07f,0xffffc023,0xffffc007,0xffffc005,0xffffbf89
}

local base_bank = {
    0x3,0x5,0x7,0xb,0xd,0x11,0x13,0x17,0x1d,0x1f,0x25,0x29,0x2b,0x2f,0x35,0x3b,
    0x3d,0x43,0x47,0x49,0x4f,0x53,0x59,0x61,0x65,0x67,0x6b,0x6d,0x71,0x7f,0x83,
    0x89,0x8b,0x95,0x97,0x9d,0xa3,0xa7,0xad,0xb3,0xb5,0xbf,0xc1,0xc5,0xc7,0xd3,
    0xdf,0xe3,0xe5,0xe9,0xef,0xf1,0xfb,0x101,0x107,0x10d,0x10f,0x115,0x119,0x11b,
    0x125,0x133,0x137,0x139,0x13d,0x14b,0x151,0x15b,0x15d,0x161,0x167,0x16f,0x175
}

function encrypt.generatePartialSecret()

end

function encrypt.performHandshake(socket)

end

return encrypt
end
preload["shared.coroutines"] = function(...)
local coroutines = {}

local tableutils = require("shared.tableutils")
local logger = require("shared.logger")

local function isDead(co)
    if not co then return true end

    return coroutine.status(co) == "dead"
end

coroutines.Manager = {}
function coroutines.Manager.new()
    local self = {
        routines = {},
        garbage = {},
        running = false,
        id_counter = 0,
    }

    return setmetatable(self, { __index = coroutines.Manager })
end

function coroutines.Manager:addRoutine(constructor, ...)
    self.id_counter = (self.id_counter + 1) % 2^32
    local co = setmetatable({
        id = self.id_counter,
        constructor = constructor,
        thread = coroutine.create(constructor)
    }, { __tostring = function(self)
        return tostring(self.thread) .. "<" .. tostring(self.constructor) .. ">"
    end})

    logger.trace("Priming " .. tostring(co))
    local success, datum = coroutine.resume(co.thread, ...)
    if success then
        if coroutine.status(co.thread) == "suspended" then
            co.filter = datum
            table.insert(self.routines, co)
        end
        logger.trace("Primed " .. tostring(co))

        return self.id_counter
    else
        logger.fatal("Error priming " .. tostring(co) .. ": " .. datum)

        return false
    end
end

function coroutines.Manager:killRoutine(id)
    logger.trace("Thread " .. tostring(id) .. " marked for culling")
    table.insert(self.garbage, id)
end

function coroutines.Manager:shutdown()
    self.running = false
    coroutine.yield()
end

function coroutines.Manager:run(main, disableTerminate)
    self.running = true
    self:addRoutine(require, main)

    while self.running and #self.routines > 0 do
        local event = {coroutine.yield()}

        if event[1] == "terminate" then
            if not disableTerminate then
                self.running = false
                break
            end
        end

        self.garbage = {}
        for i = 1, #self.routines do
            local co = self.routines[i]
            if isDead(co.thread) then
                logger.trace("Marking " .. tostring(co) .. " for collection")
                table.insert(self.garbage, co.id)
            else
                if co.filter == event[1] or not co.filter then
                    local success, datum = coroutine.resume(co.thread, tableutils.unpack(event))
                    if not self.running then
                        break
                    end

                    if success then
                        if type(datum) == "string" then
                            co.filter = datum
                        else
                            co.filter = nil
                        end
                    else
                        logger.error("Error resuming coroutine: " .. datum)
                        logger.trace("Marking " .. tostring(co) .. " for collection")
                        table.insert(self.garbage, co.id)
                    end
                end
            end
        end

        for i = 1, #self.garbage do
            for j = 1, #self.routines do
                local co = self.routines[j]
                if co.id == self.garbage[i] then
                    logger.trace("Collecting", self.routines[j])
                    table.remove(self.routines, j)
                    break
                end
            end
        end
    end

    logger.info("Coroutine manager shutting down...")
end


function coroutines.loop(...)
    local routineCount = select("#", ...)
    local routineConstructors = {...}
    local activeRoutines = {}
    local filters = {}

    local first = true
    while true do
        local event
        if first then
            first = false
        else
            event = {coroutine.yield()}
        end

        if event and event[1] == "terminate" then
            break
        end

        for i = 1, routineCount do
            local resumeSuccess = true
            if isDead(activeRoutines[i]) then
                activeRoutines[i] = coroutine.create(routineConstructors[i])
                resumeSuccess, filters[i] = coroutine.resume(activeRoutines[i])
            else
                if filters[i] == event[1] or not filters[i] then
                    resumeSuccess, filters[i] = coroutine.resume(activeRoutines[i], tableutils.unpack(event))
                end
            end

            if not resumeSuccess then
                logger.error("Error resuming coroutine: " .. filters[i])
                filters[i] = nil
            end
        end
    end
end

function coroutines.runTimer(duration)
    local timerId = os.startTimer(duration)
    while true do
        local e, i = coroutine.yield("timer")
        if e == "timer" and i == timerId then
            return
        end
    end
end

return coroutines
end
preload["shared.bit64"] = function(...)
local bit64 = {}

local bit32 = bit or bit32 or require("bit32")

local b32lshift = bit32.lshift or bit32.blshift
local b32rshift = bit32.blogic_rshift or bit32.rshift
local b32arshift = bit32.arshift or bit32.rshift or bit32.brshift
local b32not, b32and, b32or, b32xor = bit32.bnot, bit32.band, bit32.bor, bit32.bxor

-- LuaJIT's bit library behaves a little unexpectedly, so we have to account for that
if jit then
    local ffi = require("ffi")
    local function forceUnsign(ofn)
        return function(...)
            return tonumber(ffi.cast("uint32_t", ofn(...)))
        end
    end

    b32lshift = forceUnsign(b32lshift)
    b32rshift = forceUnsign(b32rshift)
    b32arshift = forceUnsign(b32arshift)
    b32not, b32and = forceUnsign(b32not), forceUnsign(b32and)
    b32or, b32xor = forceUnsign(b32or), forceUnsign(b32xor)
end

local unsignMask = 0x7FFFFFFF
local low32Mask  = 0xFFFFFFFF
local high16Mask = 0xFFFF0000
local low16Mask  = 0x0000FFFF
local carryBit   = 0x100000000
local high32Bit  = 0x80000000

local constZero = {0, 0}
local constOne = {1, 0}
local constNegOne = {0xFFFFFFFF, 0xFFFFFFFF}

local floor = math.floor
local ceil = math.ceil
local min, max, abs = math.min, math.max, math.abs

local unpack = table.unpack or unpack

local function xp(n, ...)
    local ags = {...}
    n = n or 8
    print((("%%0%dX "):format(n)):rep(#ags):format(...))
end


function bit64.newInt(v, hv)
    v, hv = v or 0, hv or 0
    assert(v >= 0 and hv >= 0, "newInt cannot be called with negative components, use :arInverse()")

    local t = {v, hv}
    return setmetatable(t, bit64)
end

function bit64.copy(n)
    return bit64.newInt(n[1], n[2])
end
bit64.clone = bit64.copy -- Alias

-- Assumes Little Endian
function bit64.fromBytes(b0, b1, b2, b3, b4, b5, b6, b7)
    return bit64.newInt(
        b0 + b32lshift(b1, 8) + b32lshift(b2, 16) + b32lshift(b3, 24),
        b4 + b32lshift(b5, 8) + b32lshift(b6, 16) + b32lshift(b7, 24)
    )
end

function bit64.fromBytesBE(...)
    local bytes = {...}
    for i = 1, 4 do
        bytes[i], bytes[9 - i] = bytes[9 - i], bytes[i]
    end

    return bit64.fromBytes(unpack(bytes))
end

-- Pure functions
function bit64:plus(b)
    local sv, shv = self[1], self[2]
    local ov, ohv = b[1], b[2]

    local nv, nhv = sv + ov, shv + ohv
    if nv > low32Mask then
        -- Possible values are 0x1
        nv = nv - carryBit
        nhv = nhv + 1
    end

    -- Overflow behavior: ignore high bit
    if nhv > low32Mask then
        nhv = nhv - carryBit
    end

    return nv, nhv
end

function bit64:minus(b)
    return self:plus({bit64.unaryMinus(b)})
end

local function multiply32(a, b)
    local a_l, a_h = b32and(a, low16Mask), b32rshift(b32and(a, high16Mask), 16)
    local b_l, b_h = b32and(b, low16Mask), b32rshift(b32and(b, high16Mask), 16)

    local r_3h = bit64.newInt(0, a_h*b_h)
    local r_hc = a_l*b_h + a_h*b_l
    local r_hcV = b32and(low16Mask, r_hc)
    local r_hcU = b32lshift(r_hcV, 16)
    local r_hcO = b32rshift((r_hc - r_hcV) / 2, 15)
    local r_h = bit64.newInt(r_hcU, r_hcO)
    local r_l = bit64.newInt(a_l*b_l, 0)

    return r_3h:add(r_h):plus(r_l)
end

function bit64:times(b)
    local sv, shv = self[1], self[2]
    local ov, ohv = b[1], b[2]

    local b0 = bit64.newInt(multiply32(sv, ov))
    local b1 = bit64.newInt(multiply32(shv, ov))
    local b2 = bit64.newInt(multiply32(sv, ohv))
    local b3 = bit64.newInt(0, (b1:plus(b2)))
    return b0:plus(b3)
end

-- Division algorithm shamelessly stolen from
-- https://github.com/llvm-mirror/compiler-rt/blob/master/lib/builtins/udivmoddi4.c
local n_uword_bits = 32
local n_udword_bits = 64
function bit64:dividedByU(d)
    local n = self
    local q = bit64.newInt()
    local r = bit64.newInt()

    local nlow, nhigh = n[1] or 0, n[2] or 0
    local dlow, dhigh = d[1] or 0, d[2] or 0

    local sr = 0

    -- Special cases, X is unknown, K != 0
    if nhigh == 0 then
        if dhigh == 0 then
            -- 0 X
            -- ---
            -- 0 X
            if dlow == 0 then
                error("Integer divide by zero")
            end

            return floor(nlow / dlow), 0, nlow % dlow, 0
        end

        -- 0 X
        -- ---
        -- K X
        return 0, 0, nlow, 0
    end

    -- nhigh != 0
    if dlow == 0 then
        if dhigh == 0 then
            -- K X
            -- ---
            -- 0 0
            error("Integer divide by zero")
        end

        -- dhigh != 0
        if nlow == 0 then
            -- K 0
            -- ---
            -- K 0
            return floor(nhigh / dhigh), 0, 0, nhigh % dhigh
        end

        -- K K
        -- ---
        -- K 0
        if b32and(dhigh, dhigh - 1) == 0 then -- d power of 2
            return b32rshift(nhigh, bit64.countTrailingZeros({dhigh})), 0, nlow, b32and(nhigh, dhigh - 1)
        end

        sr = bit64.countLeadingZeros({dhigh}) - bit64.countLeadingZeros({nhigh})
        if sr < 0 then
            return 0, 0, nlow, nhigh
        end

        sr = sr + 1

        q[1] = 0
        q[2] = b32lshift(nlow, n_uword_bits - sr)

        r[2] = b32rshift(nhigh, sr)
        r[1] = b32or(b32lshift(nhigh, n_uword_bits - sr), b32rshift(nlow, sr))
    else -- dlow != 0
        if dhigh == 0 then
            -- K X
            -- ---
            -- 0 K
            if b32and(dlow, dlow - 1) == 0 then -- d power of 2
                if dlow == 1 then
                    return nlow, nhigh, b32and(nlow, dlow - 1), 0
                end

                sr = bit64.countTrailingZeros({dlow})
                return b32or(b32lshift(nhigh, n_uword_bits - sr), b32rshift(nlow, sr)), b32rshift(nhigh, sr),
                       b32and(nlow, dlow - 1), 0
            end

            sr = 1 + n_uword_bits + bit64.countLeadingZeros({dlow}) - bit64.countLeadingZeros({nhigh})

            if sr == n_uword_bits then
                q[1] = 0
                q[2] = nlow
                r[2] = 0
                r[1] = nhigh
            elseif sr < n_uword_bits then
                q[1] = 0
                q[2] = b32lshift(nlow, n_uword_bits - sr)
                r[2] = b32rshift(nhigh, sr)
                r[1] = b32or(b32lshift(nhigh, n_uword_bits - sr), b32rshift(nlow, sr))
            else
                q[1] = b32lshift(nlow, n_udword_bits - sr)
                q[2] = b32or(b32lshift(nhigh, n_udword_bits - sr),
                             b32rshift(nlow, sr - n_uword_bits))
                r[2] = 0
                r[1] = b32rshift(nhigh, sr - n_uword_bits)
            end
        else
            -- K X
            -- ---
            -- K K
            sr = bit64.countLeadingZeros({dhigh}) - bit64.countLeadingZeros({nhigh})
            if sr < 0 then
                return 0, 0, nlow, nhigh
            end

            sr = sr + 1

            q[1] = 0
            if sr == n_uword_bits then
                q[2] = nlow
                r[2] = 0
                r[1] = nhigh
            else
                q[2] = b32lshift(nlow, n_uword_bits - sr)
                r[2] = b32rshift(nhigh, sr)
                r[1] = b32or(b32lshift(nhigh, n_uword_bits - sr), b32rshift(nlow, sr))
            end
        end
    end

    -- Not a special case
    -- q and r are initialized with:
    -- q = n << (n_udword_bits - sr);
    -- r = n >> sr;
    -- 1 <= sr <= n_udword_bits - 1
    local carry = 0
    while sr > 0 do
        r[2] = b32or(b32lshift(r[2], 1), b32rshift(r[1], n_uword_bits - 1))
        r[1] = b32or(b32lshift(r[1], 1), b32rshift(q[2], n_uword_bits - 1))
        q[2] = b32or(b32lshift(q[2], 1), b32rshift(q[1], n_uword_bits - 1))
        q[1] = b32or(b32lshift(q[1], 1), carry)

        local t = bit64.newInt(bit64.minus(d, r)):sub(constOne):shr_s({n_udword_bits - 1})
        carry = b32and(t[1], 1)
        r:sub({bit64.band(d, t)})

        sr = sr - 1
    end

    q:shl({1})
    q[1] = b32or(q[1], carry)

    return q[1], q[2], r[1], r[2]
end

function bit64:dividedByS(o)
    print("WHYYY")
    print(debug.traceback())
    local s_a = bit64.copy(bit64.isNegative(self) and constNegOne or constZero)
    local s_b = bit64.copy(bit64.isNegative(o)    and constNegOne or constZero)
    local a = bit64.newInt(bit64.bxor(self, s_a)):sub(s_a)
    local b = bit64.newInt(bit64.bxor(o   , s_b)):sub(s_b)

    s_a:bxored(s_b) -- s_a now holds the sign of the quotient

    local ir = bit64.newInt(a:dividedByU(b))
    return ir:bxored(s_a):minus(s_a)
end

function bit64:modU(b)
    local _, _, vl, vh = bit64.dividedByU(self, b)
    return vl, vh
end

function bit64:modS(b)
    local d = {bit64.dividedByS(self, b)}
    return self:minus({b:times(d)})
end

function bit64:raiseTo(exp)
    local base = self
    local res = bit64.copy(constOne)
    exp = bit64.copy(exp)

    while true do
        if exp:band(constOne) ~= 0 then
            res:mult(base)
        end

        exp:shr_u(constOne)
        if exp:eqz() == 1 then
            break
        end

        base:mult(base)
    end

    return res[1], res[2]
end

function bit64:lshift(c)
    local sl, sh = self[1], self[2]
    if sl == 0 and sh == 0 then
        return 0, 0
    end

    -- Mod c by 64
    c = b32and(c[1], 0x3F)
    if c == 0 then return sl, sh end

    if c >= 32 then
        return 0, b32lshift(sl, c - 32)
    end

    local remLowHi = b32rshift(sl, n_uword_bits - c)

    return b32lshift(sl, c), b32lshift(sh, c) + remLowHi
end

function bit64:rshift(c)
    local sl, sh = self[1], self[2]
    if sl == 0 and sh == 0 then
        return 0, 0
    end

    -- Mod c by 64
    c = b32and(c[1], 0x3F)
    if c == 0 then return sl, sh end

    if c >= 32 then
        return b32rshift(sh, c - 32), 0
    end

    local remHiLow = b32lshift(sh, n_uword_bits - c)

    return b32rshift(sl, c) + remHiLow, b32rshift(sh, c)
end

function bit64:arshift(c)
    local sl, sh = self[1], self[2]
    if sl == 0 and sh == 0 then
        return 0, 0
    end

    -- Mod c by 64
    c = b32and(c[1], 0x3F)
    if c == 0 then return sl, sh end

    if c >= 32 then
        return b32arshift(sh, c - 32), b32arshift(b32arshift(sh, 31), 1)
    end

    local remHiLow = b32lshift(sh, n_uword_bits - c)

    local hiRes = b32arshift(sh, min(31, c))
    local loRes = b32rshift(sl, c) + remHiLow
    if hiRes == low32Mask then
        loRes = b32or(loRes, b32arshift(high32Bit, c - 33))
    end

    return loRes, hiRes
end

function bit64:rotateLeft(c)
    local sl, sh = self[1], self[2] or 0

    -- Mod c by 64
    c = b32and(c, 0x3F)
    if c == 0 then return sl, sh end

    if c > 32 then
        return bit64.rotateRight(self, 64 - c)
    elseif c == 32 then
        return sh, sl
    end

    local overflowMask = b32arshift(high32Bit, c)

    local upperLower = b32and(low32Mask, b32lshift(sl, c))
    local lowerLower = b32rshift(b32and(overflowMask, sh), 32 - c)
    local lowRes = b32or(upperLower, lowerLower)

    local upperHigh = b32and(low32Mask, b32lshift(sh, c))
    local lowerHigh = b32rshift(b32and(overflowMask, sl), 32 - c)
    local highRes = b32or(upperHigh, lowerHigh)

    return lowRes, highRes
end

function bit64:rotateRight(c)
    local sl, sh = self[1], self[2] or 0

    -- Mod c by 64
    c = b32and(c, 0x3F)
    if c == 0 then return sl, sh end

    if c > 32 then
        return bit64.rotateLeft(self, 64 - c)
    elseif c == 32 then
        return sh, sl
    end

    local overflowMask = b32rshift(b32arshift(high32Bit, c), 32 - c)

    local upperLower = b32lshift(b32and(overflowMask, sh), 32 - c)
    local lowerLower = b32rshift(sl, c)
    local lowRes = b32or(upperLower, lowerLower)

    local upperHigh = b32lshift(b32and(overflowMask, sl), 32 - c)
    local lowerHigh = b32rshift(sh, c)
    local highRes = b32or(upperHigh, lowerHigh)

    return lowRes, highRes
end

function bit64:band(b)
    local sl, sh = self[1], self[2] or 0
    return b32and(sl, b[1]), b32and(sh, b[2] or 0)
end

function bit64:bor(b)
    local sl, sh = self[1], self[2] or 0
    return b32or(sl, b[1]), b32or(sh, b[2] or 0)
end

function bit64:bxor(b)
    local sl, sh = self[1], self[2] or 0
    return b32xor(sl, b[1]), b32xor(sh, b[2] or 0)
end

function bit64.modexp(x, y, N)
    -- print(x)
    -- print()
    -- print(x, y, N)
    -- print("y:" .. tostring(y) .. "; " .. tostring(y:equals({0})))
    -- print(N)
    if y:equals({0}) then return 1 end

    local yp = bit64.newInt(y:dividedByU({2, 0}))
    local z = bit64.newInt(bit64.modexp(x, yp, N))
    -- print(z)
    -- print("ymod", y, y:modU({2}), bit64.equals({y:modU({2})}, {0}))
    if bit64.equals({y:modU({2})}, {0}) then -- The worst case big O of these branches is the second
        -- print("zmod", z, bit64.newInt({z:times(z)}), bit64.newInt(bit64.modU({z:times(z)}, N)))
        return bit64.modU({z:times(z)}, N)
    else
        -- print("hfaf", x:times({z:times(z)}))
        -- print(bit64.modU({5, 0}, N))
        return bit64.modU({x:times({z:times(z)})}, N)
    end
end

function bit64:countLeadingZeros()
    local x, hi32 = self[1], self[2] or 0
    if x == 0 and hi32 == 0 then return 64 end

	local n = 0
	if hi32 == 0 then
		n = n + 32
	else
		x = hi32
    end

	if b32and(x, 0xFFFF0000) == 0 then
		n = n + 16
		x = b32lshift(x, 16)
	end
	if b32and(x, 0xFF000000) == 0 then
		n = n + 8
		x = b32lshift(x, 8)
	end
	if b32and(x, 0xF0000000) == 0 then
		n = n + 4
		x = b32lshift(x, 4)
	end
	if b32and(x, 0xC0000000) == 0 then
		n = n + 2
		x = b32lshift(x, 2)
	end
	if b32and(x, 0x80000000) == 0 then
		n = n + 1
	end
	return n
end

function bit64:countTrailingZeros()
    local x, hi32 = self[1], self[2]
    if x == 0 and hi32 == 0 then return 64 end

	local n = 0
	if x == 0 then
        n = n + 32
        x = hi32
    end

	if b32and(x, 0x0000FFFF) == 0 then
		n = n + 16
		x = b32rshift ( x , 16 )
	end
	if b32and(x, 0x000000FF) == 0 then
		n = n + 8
		x = b32rshift ( x, 8)
	end
	if b32and(x, 0x0000000F) == 0 then
		n = n + 4
		x = b32rshift ( x, 4)
	end
	if b32and(x, 0x00000003) == 0 then
		n = n + 2
		x = b32rshift ( x, 2)
	end
	if b32and(x, 0x00000001) == 0 then
		n = n + 1
	end
	return n
end

local function count32SetBits(n)
    local i, c = 1, 0
    while i <= high32Bit do
        if b32and(n, i) ~= 0 then
            c = c + 1
        end
        i = i * 2
    end

    return c
end

function bit64:countSetBits()
    local sl, sh = self[1], self[2]
    return count32SetBits(sl) + count32SetBits(sh)
end

function bit64:sign()
    local sl, sh = self[1], self[2]
    if sl == 0 and sh == 0 then
        return 0
    end

    if b32and(sh, high32Bit) == 0 then
        return 1
    else
        return -1
    end
end

function bit64:unaryMinus()
    -- 2's complement
    -- invert all bits and then add one
    local lo = b32not(self[1]) % carryBit
    local hi = b32not(self[2] or 0) % carryBit
    return bit64.plus({lo, hi}, constOne)
end

function bit64:isPositive()
    return bit64.sign(self) == 1
end

function bit64:isNegative()
    return bit64.sign(self) == -1
end

function bit64:equals(b)
    return (self[1] or 0) == (b[1] or 0) and (self[2] or 0) == (b[2] or 0)
end

function bit64:eqz()
    return (self[1] == 0 and self[2] == 0) and 1 or 0
end

function bit64:eq(b)
    return (self[1] == b[1] and self[2] == b[2]) and 1 or 0
end

function bit64:ne(b)
    return (self[1] ~= b[1] or self[2] ~= b[2]) and 1 or 0
end

function bit64:lt_s(o)
    local selfSign, otherSign = bit64.sign(self), bit64.sign(o)
    if selfSign ~= otherSign then
        return (selfSign < otherSign) and 1 or 0
    end

    -- They're both 0
    if selfSign == 0 then return 0 end

    local diff = bit64.sign({bit64.minus(o, self)})
    return (diff == 1) and 1 or 0
end

function bit64:lt_u(o)
    local sl, sh = self[1], self[2]
    local ol, oh = o[1], o[2]

    local shz, ohz = sh == 0, oh == 0

    if shz and ohz then
        return (sl < ol) and 1 or 0
    end

    if shz and not ohz then
        return 1
    elseif ohz and not shz then
        return 0
    end

    if sh == oh then
        return (sl < ol) and 1 or 0
    else
        return (sh < oh) and 1 or 0
    end
end

function bit64:le_s(o)
    return 1 - bit64.lt_s(o, self)
end

function bit64:gt_s(o)
    return bit64.lt_s(o, self)
end

function bit64:ge_s(o)
    return 1 - bit64.lt_s(self, o)
end

function bit64:le_u(o)
    return 1 - bit64.lt_u(o, self)
end

function bit64:gt_u(o)
    return bit64.lt_u(o, self)
end

function bit64:ge_u(o)
    return 1 - bit64.lt_u(self, o)
end

function bit64:signExtend8()
    local sbit = b32and(self[1], 0x80) ~= 0 and high32Bit or 0
    return b32or(b32and(self[1], 0xFF), b32arshift(sbit, 23)), b32arshift(sbit, 31)
end

function bit64:signExtend16()
    local sbit = b32and(self[1], 0x8000) ~= 0 and high32Bit or 0
    return b32or(b32and(self[1], 0xFFFF), b32arshift(sbit, 15)), b32arshift(sbit, 31)
end

function bit64:signExtend32()
    local sbit = b32and(self[1], 0x80000000) ~= 0 and high32Bit or 0
    return self[1], b32arshift(sbit, 31)
end


-- Mutating functions
function bit64:add(b)
    self[1], self[2] = self:plus(b)
    return self
end

function bit64:sub(b)
    self[1], self[2] = self:minus(b)
    return self
end

function bit64:mult(b)
    self[1], self[2] = self:times(b)
    return self
end

function bit64:div_u(b)
    self[1], self[2] = self:dividedByU(b)
    return self
end

function bit64:div_s(b)
    self[1], self[2] = self:dividedByS(b)
    return self
end

function bit64:rem_u(b)
    self[1], self[2] = self:modU(b)
    return self
end

function bit64:rem_s(b)
    self[1], self[2] = self:modS(b)
    return self
end

function bit64:shl(c)
    self[1], self[2] = self:lshift(c)
    return self
end

function bit64:shr_u(c)
    self[1], self[2] = self:rshift(c)
    return self
end

function bit64:shr_s(c)
    self[1], self[2] = self:arshift(c)
    return self
end

function bit64:ctz(c)
    self[1], self[2] = self:countTrailingZeros(c), 0
    return self
end

function bit64:clz(c)
    self[1], self[2] = self:countLeadingZeros(c), 0
    return self
end

function bit64:popcnt()
    self[1], self[2] = self:countSetBits(), 0
    return self
end

function bit64:rotl(c)
    self[1], self[2] = self:rotateLeft(c[1])
    return self
end

function bit64:rotr(c)
    self[1], self[2] = self:rotateRight(c[1])
    return self
end

function bit64:banded(c)
    self[1], self[2] = self:band(c)
    return self
end

function bit64:bored(c)
    self[1], self[2] = self:bor(c)
    return self
end

function bit64:bxored(c)
    self[1], self[2] = self:bxor(c)
    return self
end

function bit64:arInverse()
    self[1], self[2] = self:unaryMinus()
    return self
end

function bit64:extend8_s()
    self[1], self[2] = self:signExtend8()
    return self
end

function bit64:extend16_s()
    self[1], self[2] = self:signExtend16()
    return self
end

function bit64:extend32_s()
    self[1], self[2] = self:signExtend32()
    return self
end

-- Metamethods
function bit64:__tostring()
    return ("i64<%08X,%08X>"):format(self[2], self[1])
end

local function repack(fn)
    return function(...)
        return bit64.newInt(fn(...))
    end
end

bit64.__index = bit64
bit64.__call = function(t, ...) return bit64.newInt(...) end
bit64.__unm = repack(bit64.unaryMinus)
bit64.__add = repack(bit64.plus)
bit64.__sub = repack(bit64.minus)
bit64.__mul = repack(bit64.times)
bit64.__div = repack(bit64.dividedByS)
bit64.__idiv = repack(bit64.dividedByS)
bit64.__mod = repack(bit64.modS)
bit64.__pow = repack(bit64.raiseTo)

-- Helper Constants
bit64.zero = function() return bit64.copy(constZero) end
bit64.one = function() return bit64.copy(constOne) end
bit64.negOne = function() return bit64.copy(constNegOne) end

setmetatable(bit64, bit64)
return bit64
end
preload["shared.async"] = function(...)
local async = {}

local tableutils = require("shared.tableutils")
local logger = require("shared.logger")
local gcm = require("shared.gcm")

async.Promise = {
    States = { PENDING = 1, RESOLVED = 2, REJECTED = 3, CANCELED = 4 }
}

local function dispatchYield(promise, waiter)
    logger.trace(tostring(promise), ": trying to dispatch")
    if promise.yield then
        if waiter then
            waiter(tableutils.unpack(promise.yield))
        end
    end
end

function async.Promise.new(runner)
    local self = {}
    self.status = async.Promise.States.PENDING
    setmetatable(self, {
        __index = async.Promise,
        __tostring = async.Promise.tostring
    })

    local resolve = function(...)
        if self.status ~= async.Promise.States.PENDING then
            return
        end

        self.status = async.Promise.States.RESOLVED
        self.yield = {...}
        dispatchYield(self, self.waiter)
    end

    local reject = function(...)
        if self.status ~= async.Promise.States.PENDING then
            return
        end

        self.status = async.Promise.States.REJECTED
        self.yield = {...}
        dispatchYield(self, self.catcher)
        if not self.catcher then
            logger.fatal("Unhandled promise rejection:", ...)
        end
    end

    self.rid = gcm:addRoutine(runner, resolve, reject)
    return self
end

--- Takes a list of promises, and returns a promise that resolves immediately when any of them resolve
function async.Promise.any(...)
    local promises = {...}
    return async.Promise.new(function(resolve, reject)
        local function cancelAll()
            for i = 1, #promises do
                promises[i]:cancel()
            end
        end

        for i = 1, #promises do
            local promise = promises[i]

            promise:next(function(...)
                cancelAll()
                resolve(...)
            end):catch(function(...)
                cancelAll()
                reject(...)
            end)
        end
    end)
end

function async.Promise:tostring()
    if self.status == async.Promise.States.PENDING then
        return "Promise<pending>"
    else
        return "Promise<" .. tostring(self.yield) .. ">"
    end
end

function async.Promise:cancel()
    if self.status == async.Promise.States.PENDING then
        self.status = async.Promise.States.CANCELED
    end
end

function async.Promise:next(callback)
    if self.status == async.Promise.States.RESOLVED then
        local val = {callback(tableutils.unpack(self.yield))}
        if select("#", tableutils.unpack(val)) > 0 then
            self.yield = val
        end

        return self
    end

    if self.waiter then
        local first = self.waiter
        self.waiter = function(...)
            local val = {first(...)}
            if select("#", tableutils.unpack(val)) > 0 then
                self.yield = val
            end

            return callback(tableutils.unpack(self.yield))
        end
    else
        self.waiter = callback
    end

    return self
end

function async.Promise:catch(callback)
    return async.Promise.new(function(resolve, reject)
        self:next(resolve)
        self.catcher = function(...)
            local s, e = tableutils.postpack(1, pcall(callback, ...))
            if s then
                resolve(tableutils.unpack(e))
            else
                reject(tableutils.unpack(e))
            end
        end
    end)
end

function async.Promise:finally(callback)
    return async.Promise.new(function(resolve, reject)
        self:next(function(...)
            resolve(...)
            callback(...)
        end):catch(function(...)
            reject(...)
            callback(...)
        end)
    end)
end

function async.await(promise)
    if type(promise[1]) == "table" then
        promise = promise[1]
    end

    if not promise.next then
        error("await called with non-promise", 2)
    end

    local returnValue
    promise:next(function(...)
        logger.trace(promise, ": resolved!")
        returnValue = {...}
    end)

    logger.trace("await : about to yield for", tostring(promise))
    while not returnValue do
        coroutine.yield()
    end

    return tableutils.unpack(returnValue)
end

setmetatable(async, { __call = function(_, val)
    if type(val) == "table" then
        val = val[1]
    end

    if type(val) ~= "function" then
        error("async generator called with non-function", 2)
    end

    return function(...)
        local args = {...}
        return async.Promise.new(function(resolve, reject)
            local success, datum = tableutils.postpack(1, pcall(val, tableutils.unpack(args)))
            if success then
                resolve(tableutils.unpack(datum))
            else
                reject(tableutils.unpack(datum))
            end
        end)
    end
end })

return async
end
preload["shared.apierrors"] = function(...)
return {
    SVERR = { code = -1, description = "Internal Server Error" },
    NINGAME = { code = 0, description = "You are not in a game." },
    AINGAME = { code = 1, description = "You are already in a game." },
    INVALIDREQ = { code = 2, description = "Invalid request options." },
    MISSING = function(param)
        return { code = 3, description = "Missing parameter '" .. param .. "'" }
    end,
    WTYPE = function(expected, path)
        return { code = 4, description = "Expected type '" .. expected .. "' for " .. path}
    end,
    BOUND = function(bound, path)
        return { code = 5, description = "Parameter '" .. path .. "' out of bounds, expected " .. bound }
    end,
    NEXISTS = { code = 6, description = "Requested entity does not exist" }
}
end
preload["client.wordbar"] = function(...)
local WordBar = {}

function WordBar.new(width)
    local self = {
        width = width,
        text = "______a_",
        time = 34
    }

    setmetatable(self, {__index = WordBar, __tostring = WordBar.tostring})
    return self
end

function WordBar:render()
    local s_width = term.getSize()
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)

    term.setCursorPos(s_width - self.width + 1, 1)
    term.write((" "):rep(self.width))

    local middle = math.floor((self.width + #self.text)/2)
    term.setCursorPos(s_width - middle, 1)
    term.write(self.text)

    self:renderTime()
end

function WordBar:renderTime()
    local s_width = term.getSize()

    term.setBackgroundColor(colors.gray)
    if self.time <= 10 then
        term.setTextColor(colors.red)
    else
        term.setTextColor(colors.white)
    end

    term.setCursorPos(s_width - self.width + 2, 1)
    term.write(tostring(self.time) .. "s")
end

return WordBar
end
preload["client.uiutil"] = function(...)
local uiutil = {}

function uiutil.centerWrite(y, text)
    local width = term.getSize()
    local maxSize = 0
    for line in text:gmatch("[^\n]+") do
        maxSize = math.max(maxSize, #line)
    end

    local x = math.ceil((width - maxSize)/2)
    for line in text:gmatch("[^\n]+") do
        term.setCursorPos(x, y)
        term.write(line)

        y = y + 1
    end
end

return uiutil
end
preload["client.toolbar"] = function(...)
local ToolBar = {}

ToolBar.Tool = {
    PENCIL = 1, ERASER = 2, FILL = 3
}

local toolIcons = {
    [ToolBar.Tool.PENCIL] = "pen",
    [ToolBar.Tool.ERASER] = "erase",
    [ToolBar.Tool.FILL] = "fill"
}

local toolColors = {
    [ToolBar.Tool.PENCIL] = colors.green,
    [ToolBar.Tool.ERASER] = colors.orange,
    [ToolBar.Tool.FILL] = colors.blue
}

function ToolBar.new(x, y)
    local self = {
        x = x, y = y,
        selected = ToolBar.Tool.PENCIL
    }

    setmetatable(self, {__index = ToolBar, __tostring = ToolBar.tostring})
    return self
end

function ToolBar:render()
    term.setCursorPos(self.x, self.y)

    for i = 1, #toolIcons do
        if self.selected == i then
            term.setBackgroundColor(toolColors[i])
            term.setTextColor(colors.white)
        else
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.lightGray)
        end
        term.write(toolIcons[i])

        local cx, cy = term.getCursorPos()
        term.setCursorPos(cx + 1, cy)
    end
end

return ToolBar
end
preload["client.messages"] = function(...)
local MessageContainer = {}

local uuid = require("vendor.uuid")

local gcm = require("shared.gcm")
local async = require("shared.async")
local logger = require("shared.logger")
local tableutils = require("shared.tableutils")

local connection = require("client.connection")

local function sendMessage(text)
    return connection:request("guess", {text = text})
end

function MessageContainer.new(width)
    local self = {
        width = width,
        textField = {
            content = "",
            cursor  = 0,
            scrollX = 0,
        },
        pendingMessages = {},
        messages = {
            -- {author={name="Lemmmy", color=colors.cyan}, content={color=colors.gray, text="penis"}},
            -- {author={name="Lemmmy", color=colors.cyan}, content={color=colors.gray, text="abc"}},
            -- {author={name="Ema", color=colors.purple}, content={color=colors.gray, text="cat"}},
            -- {author={}, content={color=colors.lightGray, text="Game started ="}}

        }
    }

    setmetatable(self, {__index = MessageContainer, __tostring = MessageContainer.tostring})

    gcm:addRoutine(self.inputThread, self)

    connection:on("message", function(msg)
        logger.info("Message!", msg)
        table.insert(self.messages, 1, msg)
        self:render()
    end)

    return self
end

function MessageContainer:inputThread()
    while true do
        local e, key = coroutine.yield()
        if e == "char" then
            local cursor = self.textField.cursor
            local text = self.textField.content
            text = text:sub(1, cursor) .. key .. text:sub(cursor + 1)

            self.textField.content = text
            self.textField.cursor = cursor + 1

            self:renderTextField()
        elseif e == "key" then
            -- TODO: Movement
            if key == keys.enter then
                local mid = uuid()
                table.insert(self.pendingMessages, 1, {
                    id = mid,
                    author = {
                        name = "Ema",
                        color = colors.lightGray
                    },
                    content = {
                        text = self.textField.content,
                        color = colors.lightGray
                    }
                })

                sendMessage(self.textField.content)
                :next(function()
                    logger.info("is okay")
                end)
                    :catch(function(e)
                        -- TODO: Tell user some how?
                        logger.info(debug.traceback())

                        if type(e) == "table" then
                            e = e.description or e.error or e.err
                        end

                        table.insert(self.messages, 1, {
                            author={
                                name="SERVER",
                                color=colors.orange
                            },
                            content={
                                text=tostring(e),
                                color=colors.red
                            }
                        })
                    end)
                    :finally(function()
                        for i = 1, #self.pendingMessages do
                            if self.pendingMessages[i].id == mid then
                                table.remove(self.pendingMessages, i)
                                break
                            end
                        end

                        self:render()
                    end)

                self.textField.content = ""
                self.textField.cursor = 0

                self:render()
            end
        end
    end
end

function MessageContainer:render()
    local width = self.width
    local s_height = select(2, term.getSize())
    local b_x = width + 1

    -- term.setBackgroundColor(colors.lightGray)

    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(colors.white)
    for row = 1, s_height do
        term.setCursorPos(b_x, row)
        term.write("\149")
    end

    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.lightGray)
    for row = 1, s_height do
        term.setCursorPos(b_x + 1, row)
        term.write("\149") -- Border
    end

    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.gray)
    for row = 1, s_height do
        term.setCursorPos(1, row)
        term.write((" "):rep(width))
    end

    self:printMessages(width, s_height - 3)

    self:renderTextField()
    self:placeCursor()
end

function MessageContainer:renderTextField()
    local s_height = select(2, term.getSize())

    term.setCursorPos(1, s_height - 1)
    term.setBackgroundColor(colors.lightGray)
    term.write((" "):rep(self.width))

    term.setCursorPos(1, s_height - 1)
    term.write(self.textField.content)
end

function MessageContainer:placeCursor()
    local s_height = select(2, term.getSize())
    term.setTextColor(colors.black)
    term.setCursorPos(1, s_height - 1)
    term.setCursorBlink(true)
end

function MessageContainer:printMessages(width, height)
    local message, m_i
    local allMessages = tableutils.proxycat(self.pendingMessages, self.messages)
    message, m_i = allMessages[1], 1

    while message and height >= 1 do
        -- First print the message content
        term.setTextColor(message.content.color)

        local text = message.content.text
        local lineHeight = math.ceil(#text / width)
        for i = 1, lineHeight do
            term.setCursorPos(1, height - lineHeight + i)
            term.write(text:sub(1, width))
            text = text:sub(width + 1)
        end

        height = height - lineHeight

        -- Now the author
        local nextMessage = allMessages[m_i + 1]
        if (not nextMessage) or nextMessage.author.name ~= message.author.name then
            if message.author.name then
                term.setTextColor(message.author.color or colors.black)

                term.setCursorPos(1, height)
                term.write(message.author.name or "")

                height = height - 2
            else
                height = height - 1
            end
        end

        m_i = m_i + 1
        message = allMessages[m_i]
    end
end

return MessageContainer
end
preload["client.main"] = function(...)
-- This has to be done first in order to ensure require semantics
local conn = require("client.connection") -- Make sure connection is setup





local logger = require("shared.logger")
local async = require("shared.async")

-- conn:request("newgame", {
--     color = colors.purple,
--     title = "Lemmmy's Private room",
--     name = "Emma",
--     private = true
-- })

conn:request("joingame", {
    color = colors.brown,
    name = "Lemmmy",
    code = "UOIG"
})

conn:request("games"):next(function(d)
    logger.info(d)
end)

-- logger.init({
--     require("shared.logger.backends.console").new()
-- }, { level = logger.LogLevels.ALL })
-- print("hi")
local s_width, s_height = term.getSize()

local Canvas = require("client.canvas")
local canvas = Canvas.new(17, 1, 35, 19)
canvas:render()

local ColorSelector = require("client.colorselector")
local cselector = ColorSelector.new(50, 2)
cselector:render()

local WordBar = require("client.wordbar")
local wordbar = WordBar.new(35)
wordbar:render()

local ToolBar = require("client.toolbar")
local toolbar = ToolBar.new(18, s_height)
toolbar:render()

local Messages = require("client.messages")
local messages = Messages.new(14)
messages:render()
messages:placeCursor()

while true do
    os.pullEvent()
end

-- local co = require("shared.socket")
-- local sock = async.await { co.connect({service="sccriblio"}) }
-- logger.info(sock)

-- local resp = async.await { sock:request("games") }
-- logger.info(resp)
-- local x = peripheral.wrap("left")

-- x.open(9876)
-- local uid = uuid()
-- x.transmit(14762, 9876, '{"type":"connect","uid":"' .. uid .. '","port":9876}')
-- x.transmit(14762, 9876, '{"type":"data","uid":"' .. uid .. '","port":9876,"data":{"prop": 4}}')

-- print(os.pullEvent("modem_message"))

-- co.loop(function()
--     print("a")
--     -- coroutine.yield()
-- end, function()
--     print("b")
--     -- coroutine.yield()
-- end, function()
--     while true do
--         co.runTimer(0.5)
--         print("hey")
--     end
-- end)

-- logger.debug("I shouldn't appear")
-- logger.info("I did a thing")
-- logger.warn("Yoo123")
-- logger.error("oopsie")
-- logger.fatal("FUCK")

-- logger.destroy()
end
preload["client.gamestate"] = function(...)
local gamestate = {}

function gamestate.reset()

end

-- function gamestate.


gamestate.reset()
return gamestate
end
preload["client.connection"] = function(...)
local co = require("shared.socket")
local gcm = require("shared.gcm")
local async = require("shared.async")

local ui = require("client.uiutil")

local sock
local loadingScreen = async { function()
    term.clear()
    term.setCursorPos(1, 1)
    term.write("Connecting...")
    while not sock do
        os.sleep(0.5)
    end
end }

local connectTimeout = async { function(length)
    os.sleep(length)
    error("Connection timed out")
end }

local function errorScreen(err)
    if type(err) == "table" and err.description then
        err = err.description
    end

    while true do
        term.setBackgroundColor(colors.gray)
        term.clear()

        term.setTextColor(colors.white)
        ui.centerWrite(2, "Error connecting to server")

        term.setTextColor(colors.red)
        ui.centerWrite(4, tostring(err))

        os.sleep(0.5)
    end
end


while not sock do
    sock = async.await { async.Promise.any(
        loadingScreen(),
        connectTimeout(5),
        co.connect({service="sccriblio"})
    ):catch(errorScreen) }
end

return sock
end
preload["client.colorselector"] = function(...)
local ColorSelector = {}

function ColorSelector.new()
    local self = {
        selected = { colors.white, colors.lightBlue }
    }

    setmetatable(self, {__index = ColorSelector, __tostring = ColorSelector.tostring})
    return self
end

function ColorSelector:render()
    local s_width, s_height = term.getSize()
    local y = math.ceil((s_height - 16) / 2)

    for row = 1, 16 do
        term.setCursorPos(s_width, y + row)
        local color = 2^(row - 1)


        if color == self.selected[1] then
            term.setBackgroundColor(color)
            term.setTextColor(colors.lightGray)
            term.write("\149")
        elseif color == self.selected[2] then
            term.setBackgroundColor(color)
            term.setTextColor(colors.gray)
            term.write("\149")
        else
            term.setBackgroundColor(color)
            term.write(" ")
        end

        -- term.setBackgroundColor(colors.gray)
        -- term.setTextColor(color)
        -- term.write("\149")
    end
end

return ColorSelector
end
preload["client.canvas.instructions"] = function(...)
return {
    CLEAR = 1,
    PIXEL = 2,
    FILL = 3,
}
end
preload["client.canvas"] = function(...)
local canvas = {}

local function colorToHex(color)
    return ("%X"):format(math.log(color)/math.log(2))
end

function canvas.new(x, y, width, height)
    local self = {}
    setmetatable(self, { __index = canvas })

    self:reframe(x, y, width, height)

    return self
end

function canvas:reframe(x, y, width, height)
    self.x, self.y = x, y
    self.width, self.height = width, height
    self.origin_x = x + math.floor(width/2)
    self.origin_y = y + math.floor(height/2)

    self.instance = {
        bg = {},
        fg = {},
        tx = {}
    }
    for row = 1, height do
        self.instance.bg[row] = {}
        self.instance.fg[row] = {}
        self.instance.tx[row] = {}
        for col = 1, width do
            self.instance.bg[row][col] = colorToHex(colors.gray)
            self.instance.fg[row][col] = colorToHex(colors.black)
            self.instance.tx[row][col] = "\127"
        end
    end
end

function canvas:canvasToInternal(x, y)
    return
        x + math.floor(self.width/2) + 1,
        y + math.floor(self.height/2) + 1
end

function canvas:scrnToCanvas(x, y)
    return x - self.origin_x, y - self.origin_y
end

function canvas:render()
    for row = 1, self.height do
        local bg = table.concat(self.instance.bg[row], "")
        local fg = table.concat(self.instance.fg[row], "")
        local tx = table.concat(self.instance.tx[row], "")
        term.setCursorPos(self.x, self.y + row - 1)
        term.blit(tx, fg, bg)
    end
end

return canvas
end
preload["client.bootstrap"] = function(...)

local logger = require("shared.logger")
logger.init({
    -- require("shared.logger.backends.console").new(),
    require("shared.logger.backends.file").new("client.log")
}, { level = logger.LogLevels.ALL })

local gcm = require("shared.gcm")


logger.info("Bootstrapping application...")
gcm:run("client.main")





-- co.loop(function()
--     print("a")
--     -- coroutine.yield()
-- end, function()
--     print("b")
--     -- coroutine.yield()
-- end, function()
--     while true do
--         co.runTimer(0.5)
--         print("hey")
--     end
-- end)

-- logger.debug("I shouldn't appear")
-- logger.info("I did a thing")
-- logger.warn("Yoo123")
-- logger.error("oopsie")
-- logger.fatal("FUCK")

logger.destroy()
end
return preload["client.bootstrap"](...)
