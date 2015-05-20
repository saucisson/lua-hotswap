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
  local stat = ev.Stat.new (function ()
    hotswap.loaded [name] = nil
    hotswap.try_require (name)
  end, filename)
  self.observed [name] = stat
  stat:start (hotswap.loop)
end

return Ev.new ()