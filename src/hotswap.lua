               require "compat52"
local xxhash = require "xxhash"

local loaded    = {}
local filenames = {}
local hashes    = {}
local preloads  = {}

local seed = 0x5bd1e995

local function hotswap (name, no_error)
  local found = loaded [name]

  local preload = package.preload [name]
  if preload then
    if preloads [name] == preload then
      return found
    else
      local result
      if no_error then
        local ok
        ok, result = pcall (preload, name)
        if not ok then
          return nil, result
        end
      else
        result = preload (name)
      end
      loaded   [name] = result
      preloads [name] = preload
      return result
    end
  end

  local filename = filenames [name]
  if found and not filename then
    return found, false
  end
  
  if found then
    local file = io.open (filename, "r")
    if not file then
      loaded    [name] = nil
      filenames [name] = nil
      hashes    [name] = nil
      return hotswap (name)
    end
    local hash  = hashes [name]
    local check = xxhash.xxh32 (file:read "*all", seed)
    file:close ()
    if hash == check then
      return found, false
    end
    loaded    [name] = nil
    filenames [name] = nil
    hashes    [name] = nil
    local result
    if no_error then
      local ok
      ok, result = pcall (dofile, filename, name)
      if not ok then
        return nil, result
      end
    else
      result = dofile (filename, name)
    end
    loaded    [name] = result
    filenames [name] = filename
    hashes    [name] = check
    return result, true
  end

  for _, path in ipairs {
    package.path,
    package.cpath,
  } do
    filename = package.searchpath (name, path)
    if filename then
      local result
      if no_error then
        local ok
        ok, result = pcall (dofile, filename)
        if not ok then
          return nil, result
        end
      else
        result = dofile (filename)
      end
      local file   = io.open (filename, "r")
      local hash   = xxhash.xxh32 (file:read "*all", seed)
      loaded    [name] = result
      filenames [name] = filename
      hashes    [name] = hash
      return result, true
    end
  end
  if no_error then
    return nil, "module '" .. name .. "' not found"
  else
    error ("module '" .. name .. "' not found")
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

return hotswap