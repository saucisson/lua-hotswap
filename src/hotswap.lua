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
      local result
      if no_error then
        local ok
        ok, result = pcall (factory, name)
        if not ok then
          return nil, result
        end
      else
        result = factory (name)
      end
      self.modules [name] = result
      self.sources [name] = path
      self:observe (name, path)
      local wrapper
      if     type (result) == "function" then
        wrapper = function (...)
          return self.modules [name] (...)
        end
      elseif type (result) == "table" then
        wrapper = setmetatable ({}, {
          __index     = function (_, key)
            return self.modules [name] [key]
          end,
          __newindex  = function (_, key, value)
            self.modules [name] [key] = value
          end,
          __mode      = nil,
          __call      = function (_, ...)
            return self.modules [name] (...)
          end,
          __metatable = getmetatable (result),
          __tostring  = function (_)
            return tostring (self.modules [name])
          end,
          __len       = function (_)
            return # (self.modules [name])
          end,
          __gc        = nil,
          __unm       = function (_)
            return - (self.modules [name])
          end,
          __add       = function (_, rhs)
            return self.modules [name] + rhs
          end,
          __mul= function (_, rhs)
            return self.modules [name] * rhs
          end,
          __div       = function (_, rhs)
            return self.modules [name] / rhs
          end,
          __mod       = function (_, rhs)
            return self.modules [name] % rhs
          end,
          __pow       = function (_, rhs)
            return self.modules [name] ^ rhs
          end,
          __concat    = function (_, rhs)
            return self.modules [name] .. rhs
          end,
          __eq        = function (_, rhs)
            return self.modules [name] == rhs
          end,
          __lt        = function (_, rhs)
            return self.modules [name] <  rhs
          end,
          __le        = function (_, rhs)
            return self.modules [name] <= rhs
          end,
          __pairs     = function (_)
            return pairs (self.modules [name])
          end,
          __ipairs    = function (_)
            return ipairs (self.modules [name])
          end,
        })
      else
        wrapper = result
      end
      self.loaded [name] = wrapper
      return wrapper
    else
      errors [#errors+1] = path
    end
  end
  errors = table.concat (errors, "\n")
  if no_error then
    return nil, errors
  else
    error (errors)
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