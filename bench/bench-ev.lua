if not package.searchers then
  require "compat52"
end

local gettime = require "socket".gettime
local hotswap = require "hotswap.ev"
local ev      = require "ev"
local n       = require "n"

local start = gettime ()
local i     = 1
ev.Idle.new (function (loop, idle, _)
    local _ = hotswap.require "toload"
    if i == n then
      idle:stop (loop)
      loop:unloop ()
    end
    i = i+1
  end):start (ev.Loop.default)
ev.Loop.default:loop ()
local finish = gettime ()

print (math.floor (n / (finish - start)), "requires/second")
