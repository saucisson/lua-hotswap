if not package.searchers then
  require "compat52"
end

local gettime = require "socket".gettime
local hotswap = require "hotswap.lfs"
local n       = require "n"

local start = gettime ()
for _ = 1, n do
  local _ = hotswap.require "toload"
end
local finish = gettime ()

print (math.floor (n / (finish - start)), "requires/second")
