local ev      = require "ev"
local Hotswap = getmetatable (require "hotswap")
local Ev      = {}

Ev.__index = Ev
Ev.__call  = Hotswap.__call

function Ev.new (t)
  if type (t) ~= "table" then
    t = {}
  end
  local result = Hotswap.new {
    observe = Ev.observe,
  }
  result.loop  = t.loop or ev.Loop.default
  return result
end

function Ev:observe (name, filename)
  local hotswap = self
  ev.Stat.new (function ()
    hotswap.loaded [name] = nil
  end, filename):start (hotswap.loop)
end

return Ev.new ()