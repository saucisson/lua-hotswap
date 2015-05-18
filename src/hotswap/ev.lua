local ev      = require "ev"
local Hotswap = getmetatable (require "hotswap")
local Ev      = {}

Ev.__index = Ev
Ev.__call  = Hotswap.__call

function Ev.new (t)
  if type (t) ~= "table" then
    t = {}
  end
  local result    = Hotswap.new {
    new     = Ev.new,
    observe = Ev.observe,
  }
  result.loop     = t.loop or ev.Loop.default
  result.observed = {}
  return result
end

function Ev:observe (name, filename)
  if self.observed [name] then
    return
  end
  local hotswap = self
  local stat = ev.Stat.new (function ()
    hotswap.loaded [name] = nil
    hotswap:try_require (name)
  end, filename)
  self.observed [name] = stat
  stat:start (hotswap.loop)
end

return Ev.new ()