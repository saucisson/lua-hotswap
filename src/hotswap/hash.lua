local xxhash  = require "xxhash"
local Hotswap = getmetatable (require "hotswap")
local Hash    = {}

function Hash.new ()
  return Hotswap.new {
    new     = Hash.new,
    access  = Hash.access,
    observe = Hash.observe,
    hashes  = {},
    seed    = 0x5bd1e995,
  }
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