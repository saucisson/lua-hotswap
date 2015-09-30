if not package.searchers then
  package.searchers     = {}
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

function Hotswap.new (t)
  assert (t == nil or type (t) == "table")
  local result       = t              or {}
  result.new         = result.new     or Hotswap.new
  result.access      = result.access  or function () end
  result.observe     = result.observe or function () end
  result.sources     = {}
  result.modules     = {}
  result.loaded      = {}
  result.on_change   = {}
  result.require     = function (name)
    return Hotswap.require (result, name, false)
  end
  result.try_require = function (name)
    return Hotswap.require (result, name, true )
  end
  return setmetatable (result, Hotswap)
end

function Hotswap:require (name, no_error)
  if self.sources [name] then
    self:access (name, self.sources [name])
  end
  local loaded = self.loaded [name]
  if loaded then
    return loaded
  end
  local lualoaded = package.loaded [name]
  if lualoaded then
    local wrapper = Hotswap.wrap (self, lualoaded, name)
    self.modules [name] = lualoaded
    self.loaded  [name] = wrapper
    return wrapper
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
      if path then
        self:observe (name, path)
      end
      local wrapper = Hotswap.wrap (self, result, name)
      self.loaded    [name] = wrapper
      for _, f in pairs (self.on_change) do
        f (name, wrapper)
      end
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

function Hotswap:wrap (result, name)
  if type (result) == "function" then
    return function (...)
      return self.modules [name] (...)
    end
  elseif type (result) == "table" then
    return setmetatable ({}, {
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
    return result
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
