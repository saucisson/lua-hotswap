local posix   = require "posix"
local ev      = require "ev"
local Hotswap = getmetatable (require "hotswap")
local Ev      = {}

function Ev.new (t)
  return Hotswap.new {
    new      = Ev.new,
    observe  = Ev.observe,
    loop     = t and t.loop or ev.Loop.default,
    observed = {},
  }
end

function Ev:observe (name, filename)
  if self.observed [name] then
    return
  end
  local hotswap = self
  local current = filename
  repeat
    local stat = ev.Stat.new (function ()
      hotswap.loaded [name] = nil
      hotswap.try_require (name)
    end, current)
    self.observed [current] = stat
    stat:start (hotswap.loop)
    current = posix.readlink (current)
  until not current
end

return Ev.new ()
