local lfs     = require "lfs"
local Hotswap = getmetatable (require "hotswap")
local Lfs     = {}

Lfs.__index = Lfs
Lfs.__call  = Hotswap.__call

function Lfs.new ()
  local result  = Hotswap.new {
    access  = Lfs.access,
    observe = Lfs.observe,
  }
  result.dates = {}
  return result
end

function Lfs:access (name, filename)
  if self.dates [name] ~= lfs.attributes (filename, "modification") then
    self.loaded [name] = nil
  end
end

function Lfs:observe (name, filename)
  self.dates [name] = lfs.attributes (filename, "modification")
end

return Lfs.new ()