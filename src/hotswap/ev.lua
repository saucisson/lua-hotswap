local posix   = require "posix"
local ev      = require "ev"
local xxhash  = require "xxhash"
local Hotswap = getmetatable (require "hotswap")
local Ev      = {}

function Ev.new (t)
  return Hotswap.new {
    new      = Ev.new,
    observe  = Ev.observe,
    loop     = t and t.loop or ev.Loop.default,
    observed = {},
    hashes  = {},
    seed    = 0x5bd1e995,
  }
end

function Ev:observe (name, filename)
  if self.observed [name] then
    return
  end
  do
    local file = assert (io.open (filename, "r"))
    self.hashes [name] = xxhash.xxh32 (file:read "*all", self.seed)
    file:close ()
  end
  local hotswap = self
  local current = filename
  repeat
    local stat = ev.Stat.new (function ()
      local file = assert (io.open (filename, "r"))
      local hash = xxhash.xxh32 (file:read "*all", self.seed)
      file:close ()
      if hash ~= self.hashes [name] then
        hotswap.loaded [name] = nil
        hotswap.try_require (name)
      end
    end, current)
    self.observed [current] = stat
    stat:start (hotswap.loop)
    current = posix.readlink (current)
  until not current

end

return Ev.new ()
