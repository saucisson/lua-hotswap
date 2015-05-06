if _VERSION == "Lua 5.1" then
  if not package.searchers then
    require "compat53"
  end
  package.searchers [1] = function (name)
    return package.preload [name]
  end
  package.searchers [2] = function (name)
    local path, err = package.searchpath (name, package.path)
    if not path then
      return nil, err
    end
    return loadfile (path), path
  end
  package.searchers [3] = function (name)
    local path, err = package.searchpath (name, package.cpath)
    if not path then
      return nil, err
    end
    name = name:gsub ("%.", "_")
    name = name:gsub ("[^%-]+%-", "")
    return package.loadlib (path, "luaopen_" .. name), path
  end
  package.searchers [4] = function (name)
    local prefix = name:match "^[^%.]+"
    local path, err = package.searchpath (prefix, package.cpath)
    if not path then
      return nil, err
    end
    name = name:gsub ("%.", "_")
    name = name:gsub ("[^%-]+%-", "")
    return package.loadlib (path, "luaopen_" .. name), path
  end
end

local Hotswap = {}

Hotswap.__index = Hotswap

function Hotswap.new (t)
  if type (t) ~= "table" then
    t = {}
  end
  local result    = {}
  result.access   = t.access  or function () end
  result.observe  = t.observe or function () end
  result.changed  = function (_, name) result.loaded [name] = nil end
  result.sources  = {}
  result.modules  = {}
  result.loaded   = {}
  return setmetatable (result, Hotswap)
end

function Hotswap:__call (name, no_error)
  if self.sources [name] then
    self:access (name, self.sources [name])
  end
  local loaded  = self.loaded [name]
  if loaded then
    return loaded
  end
  local errors = {
    "module '" .. tostring (name) .. "' not found:",
  }
  for i = 1, #package.searchers do
    local searcher = package.searchers [i]
    local factory, path  = searcher (name)
    if type (factory) == "function" then
      local result  = factory (name)
      if  type (result) ~= "function"
      and type (result) ~= "table" then
        error "module is neither a function nor a table"
      end
      self.modules [name] = result
      self.sources [name] = path
      self:observe (name, path)
      local wrapper
      if type (module) == "function" then
        wrapper = function (...)
          return self.modules [name] (...)
        end
      elseif type (module) == "table" then
        local metatable = setmetatable ({
          __index     = function (_, key)
            return self.modules [name] [key]
          end,
          __metatable = getmetatable (module),
        }, {
          __index     = getmetatable (module),
        })
        wrapper = setmetatable ({}, metatable)
      end
      self.loaded [name] = wrapper
      return wrapper
    else
      errors [#errors+1] = path
    end
  end
  if no_error then
    return nil
  else
    error (table.concat (errors, "\n"))
  end
end

--    > hotswap = require "hotswap.hash"

--    > local file = io.open ("example.lua", "w")
--    > file:write [[ return 1 ]]
--    > file:close ()
--    > = hotswap "example"
--    1

--    > local file = io.open ("example.lua", "w")
--    > file:write [[ return 2 ]]
--    > file:close ()
--    > = hotswap "example"
--    2

--    > os.remove "example.lua"
--    > = hotswap "example"
--    error: "module 'example' not found"

--    > os.remove "example.lua"
--    > = hotswap ("example", true)
--    nil

return Hotswap.new ()