local xxhash = require "xxhash"

if not package
or not package.searchpath then
  require "compat52"
end

local Hotswap = {}

Hotswap.__index = Hotswap

function Hotswap.new (options)
  if type (options) ~= "table" then
    options = nil
  end
  options = options or {}
  options.register   = options.register or nil
  options.seed       = options.seed     or 0x5bd1e995
  options.hashes     = {}
  options.loaded     = {}
  options.preloads   = {}
  options.registered = {}
  options.sources    = {}
  return setmetatable (options, Hotswap)
end

function Hotswap.on_change (hotswap, name)
  local filename = hotswap.sources [name]
  if type (filename) ~= "string" then
    return true
  end
  local file = io.open (filename, "r")
  if not file then
    hotswap.hashes  [name] = nil
    hotswap.loaded  [name] = nil
    hotswap.sources [name] = nil
    return true
  end
  local hash = xxhash.xxh32 (file:read "*all", hotswap.seed)
  file:close ()
  if hash ~= hotswap.hashes [name] then
    hotswap.hashes  [name] = nil
    hotswap.loaded  [name] = nil
    hotswap.sources [name] = nil
    return true
  end
end

function Hotswap.preload (hotswap, name)
  local current  = hotswap.preloads [name]
  local required = package.preload  [name]
  if current and not required then
    hotswap.loaded   [name] = nil
    hotswap.preloads [name] = nil
    hotswap.sources  [name] = nil
  end
  if not required then
    return Hotswap.module (hotswap, name)
  elseif current == required then
    return hotswap.loaded [name], false
  else
    local result = required (name)
    hotswap.loaded   [name] = result
    hotswap.preloads [name] = required
    hotswap.sources  [name] = package.preload
    return result, true
  end
end

function Hotswap.module (hotswap, name)
  if not hotswap.registered [name] then
    Hotswap.on_change (hotswap, name)
  end
  local filename = hotswap.sources [name]
  if filename then
    return hotswap.loaded [name]
  end
  for i, path in ipairs {
    package.path,
    package.cpath,
  } do
    local filename = package.searchpath (name, path)
    if filename then
      local load, target
      if i == 1 then
        load, target = loadfile, nil
      else
        load, target = package.loadlib, "luaopen_" .. name
      end
      local f, err = load (filename, target)
      if not f then
        error (err)
      end
      local result = f (name)
      local file   = io.open (filename, "r")
      local hash   = xxhash.xxh32 (file:read "*all", hotswap.seed)
      file:close ()
      hotswap.hashes  [name] = hash
      hotswap.loaded  [name] = result
      hotswap.sources [name] = filename
      if  hotswap.register
      and hotswap.register ~= hotswap.registered [name] then
        hotswap.register (filename, function ()
          return Hotswap.on_change (hotswap, name)
        end)
        hotswap.registered [name] = hotswap.register
      end
      return result, true
    end
  end
  do
    local filename = name
    local file     = io.open (filename, "r")
    if file then
      local result = file:read "*all"
      local hash   = xxhash.xxh32 (result, hotswap.seed)
      file:close ()
      hotswap.hashes  [name] = hash
      hotswap.loaded  [name] = result
      hotswap.sources [name] = filename
      if  hotswap.register
      and hotswap.register ~= hotswap.registered [name] then
        hotswap.register (filename, function ()
          return Hotswap.on_change (hotswap, name)
        end)
        hotswap.registered [name] = hotswap.register
      end
      return result, true
    end
  end
  error ("module '" .. name .. "' not found")
end

local unpack = table.unpack or unpack

function Hotswap.__call (hotswap, name, no_error)
  if no_error then
    local result = { pcall (Hotswap.preload, hotswap, name) }
    if result [1] then
      return select (2, unpack (result))
    else
      return nil, result [2]
    end
  else
    return Hotswap.preload (hotswap, name)
  end
end

--    > hotswap = require "hotswap"

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