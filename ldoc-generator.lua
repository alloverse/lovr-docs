--- Generates ldoc style comments with method stubs
-- @usage `lua ldoc-generator.lua` with cwd containing the lovr-docs/api folder. It will generate output in ldoc folder in the cwd

local pl = {
  path = require 'pl.path',
  file = require 'pl.file',
}

local root = "./ldoc"
-- local root = "lovr"
file = {
  root = root,
  path = {},
  name = {},
  output = {}
}

pl.path.mkdir(file.root)
function file.write(t)
  print("will create ".. file.filedir())
  print("will write to " .. file.filepath())
  if true then 
    pl.path.mkdir(file.filedir())
    local text = join(file.output[#file.output], "\n")
    pl.file.write(file.filepath(), text)
  end
end
function file.filedir()
  return join({file.root, join(file.path, "/")}, "/")
end
function file.filepath()
  return join({file.root, join(file.path, "/"), file.name[#file.name]}, "/")
end
function file.beginModule(p)
  table.insert(file.path, p)
  table.insert(file.name, "init.lua")
  table.insert(file.output, {})
  print("begin module " .. file.filepath())
end
function file.endModule()
  print("end module " .. file.filepath())
  if #file.path == 0 then 
    error("path is overpopped")
  end
  file.write(file.output[#file.output])
  table.remove(file.name, #file.name)
  table.remove(file.path, #file.path)
  table.remove(file.output, #file.output)
end
function file.beginObject(name)
  table.insert(file.name, name .. ".lua")
  table.insert(file.output, {})
  print("begin object " .. file.filepath())
end
function file.endObject()
  print("end object " .. file.filepath())
  file.write(file.output[#file.output])
  table.remove(file.name, #file.name)
  table.remove(file.output, #file.output)
end
function file.print(text)
  table.insert(file.output[#file.output], text)
end


local function null(...)
   local t, n = {...}, select('#', ...)
   for k = 1, n do
      local v = t[k]
      if     v == null then t[k] = nil
      elseif v == nil  then t[k] = null
      end
   end
   return (table.unpack or unpack)(t, 1, n)
end
_G.null = null

-- https://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-value
function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

local _tostring = tostring
function tostring(o)
   if type(o) == 'table' then
      local s = '{'
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. k .. ' = "' .. tostring(v) .. '", '
      end
      return s .. '}'
   else
      return _tostring(o)
   end
end
local _print = print
function print(x)
  if type(text) == 'table' then
    _print(tostring(x))
  else
    _print(x)
  end
end

function map(t, f)
  if t == nil then return nil end
  local t1 = {}
  local t_len = #t
  for i = 1, t_len do
    t1[i] = f(t[i])
  end
  return t1
end

function compact(t)
  if t == nil then 
    return nil
  end
  local t1 = {}
  local t_len = #t
  for i = 1, t_len do
    t1[#t1 + 1] = t[i]
  end
  return t1
end

function join(t, d)
  if t == nil or #t == 0 then 
    return nil
  end
  return table.concat(compact(t), d)
end

function assert(expr, expected)
  if expr ~= expected then
    print(debug.getinfo(2, "S").source .. ":" .. debug.getinfo(2).currentline)
    print("got: \"" .. tostring(expr and expr or "<nil>") .. "\"")
    print("expected: \"" .. tostring(expected and expected or "<nil>") .. "\"")
    print("")
    return false
  end
  return true
end

function keys(t)
  local r = {}
  for k, _ in pairs(t) do
    table.insert(r, k)
  end
  return r
end

function split(inputstr, sep) 
  sep = sep or '%s' 
  local t={}  
  for field, s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do 
    table.insert(t,field)  
    if s == "" then 
      return t 
    end 
  end 
end


function comment(str, prefix)
  if type(prefix) == "number" then 
    prefix = (prefix == 1 and "--- " or "-- ")
  end
  prefix = prefix or "-- "
  if str == nil then return prefix end
  local r = {}
  for token in string.gmatch(str, "([^\n]*)(\n?)") do
   table.insert(r, prefix .. token)
  end
  return join(r, "\n")
end

assert(comment("hello"), "-- hello")
assert(comment("hello world"), "-- hello world")
assert(comment("hello\nworld"), "-- hello\n-- world")
assert(comment([[Hello

world]]), "-- Hello\n-- \n-- world")


function ldoc(contents)
  local r = {}
  if contents.title ~= nil then
    table.insert(r, "--- " .. contents.title)
  else
    error('LDoc needs a title')
  end
  if contents.body ~= nil then 
    table.insert(r, comment(contents.body))
  end
  if contents.params ~= nil then
    for _, arg in ipairs(contents.params) do
      if arg.name == nil then 
        error("A param needs a name")
      end
      if arg.body == nil then 
        error("A param needs a body")
      end 
      
      if arg.type ~= nil then
        table.insert(r, "-- @tparam " .. arg.type .. " " .. arg.name .. " " .. arg.body)
      else
        table.insert(r, "-- @param " .. arg.name .. " " .. arg.body)
      end
    end
  end
  if contents.returns ~= nil then
    for _, ret in ipairs(contents.returns) do
      if ret.body == nil then 
        error("A return needs a body")
      end 
      
      if ret.type ~= nil then
        table.insert(r, "-- @treturn " .. ret.type .. " " .. ret.body)
      else
        table.insert(r, "-- @return " .. ret.body)
      end
    end
  end
  if contents.see ~= nil then
    table.insert(r, comment(comment(join(contents.see, "\n"), "@see ")))
  end
  if contents.module ~= nil then
    table.insert(r, "-- @module " .. contents.module)
  end  
  if contents.classmod ~= nil then
    table.insert(r, "-- @classmod " .. contents.classmod)
  end
  
  if contents.code ~= nil then
    if type(contents.code) == "table" then 
      table.insert(r, join(contents.code, "\n"))
    else
      table.insert(r, contents.code)
    end
  end
  
  return join(r, "\n")
end

function doc(contents)
  return ldoc(contents)
end

assert(ldoc({
  title = "The first line will have three dashes and should not contain a newline.",
  body = [[The body comes after the title.

It can span several lines too!
]],
code = [[function code_is_printed_as_is(a, b, c) 
  return a + b + c
end]],
params = {
  { name = "anything", body = "Can be any type." },
  { name = "text", type = "string", body = "A text to print." },
},
returns = {
  { type = "number", body = "0 on success, otherwise an error code." },
  { body = "Anything" },
},
see = {"A list of things", "that might also be interesting"},
classmod = "ClassName",
module = "ModuleName",
}), [[--- The first line will have three dashes and should not contain a newline.
-- The body comes after the title.
-- 
-- It can span several lines too!
-- @param anything Can be any type.
-- @tparam string text A text to print.
-- @treturn number 0 on success, otherwise an error code.
-- @return Anything
-- @see A list of things
-- @see that might also be interesting
-- @module ModuleName
-- @classmod ClassName
function code_is_printed_as_is(a, b, c) 
  return a + b + c
end]])

nothing = null()

function func(contents)
  local arglist = ""
  local name = contents.name
  
  if name == nil then 
    error("A function needs a name")
  end
  
  if contents.arguments ~= nil then 
    arglist = join(contents.arguments, ", ") or ""
  end
    
  return "function " .. name .. "(" .. arglist .. ") end"
end

assert(func({
  name = "print",
  arguments = {"a", "b", "c"},
}), "function print(a, b, c) end")

function make(t, f)
  return join(map(t, f), "\n\n")
end

function makeFunction(t)
  function makeVariant(t, arguments, returns)
    return doc({
      title = t.summary,
      body = t.description,
      notes = (t.notes or nothing),
      see = t.related,
      params = map(arguments, function(a)
        return {
          name = a.name,
          type = a.type,
          body = a.description,
        }
      end),
      returns = map(returns, function(a)
        return {
          type = a.type,
          body = a.description,
        }
      end),
      code = func({
        name = t.key, 
        arguments = map(arguments, function(a) return a.name end)
      })
    })
  end
  
  return join(map(t.variants, function(v)
    return makeVariant(t, v.arguments, v.returns)
  end), "\n\n")
end

function makeObject(t)
  file.beginObject(t.name)
  file.print(doc({
    title = t.summary,
    body = t.description,
    classmod = t.key,
    code = {
      "local " .. t.name .. " = {}",
      make(t.methods, makeFunction),
    }
  }))
  file.endObject()
end

function makeModule(t)
  file.beginModule(t.name)
  file.print(doc({
    title = t.summary,
    body = t.description,
    module = t.name,
    code = {
      "local " .. t.key .. " = {}",
      make(t.functions, makeFunction),
    }
  }))
  file.print(make(t.objects, makeObject))
  file.endModule()
end

local api = require("api")
local modules = api.modules

local t = modules[10]



map(api.modules, function(m)
  -- print("filename: " .. m.name .. "/init.lua")
  makeModule(m, path)
end)


-- pl.dump(keys(api))
-- pl.dump(t.objects)


