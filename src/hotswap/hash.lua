local xxhash  = require "xxhash"
local Hotswap = getmetatable (require "hotswap")
local Hash    = {}

Hash.__index = Hash
Hash.__call  = Hotswap.__call

function Hash.new ()
  local result  = Hotswap.new {
    access  = Hash.access,
    observe = Hash.observe,
  }
  result.hashes = {}
  result.seed   = 0x5bd1e995
  return result
end

function Hash:access (name, filename)
  local file = io.open (filename, "r")
  if not file then
    self.hashes [name] = nil
    self.loaded [name] = nil
    return
  end
  local hash = xxhash.xxh32 (file:read "*all", self.seed)
  if hash ~= self.hashes [name] then
    self.loaded [name] = nil
  end
end

function Hash:observe (name, filename)
  local file = io.open (filename, "r")
  local hash = xxhash.xxh32 (file:read "*all", self.seed)
  self.hashes [name] = hash
end

return Hash.new ()