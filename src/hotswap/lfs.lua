local lfs     = require "lfs"
local Hotswap = getmetatable (require "hotswap")
local Lfs     = {}

function Lfs.new ()
  return Hotswap.new {
    new     = Lfs.new,
    access  = Lfs.access,
    observe = Lfs.observe,
    dates   = {},
  }
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