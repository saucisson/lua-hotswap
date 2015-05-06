local gettime = require "socket".gettime
local hotswap = require "hotswap.hash"
local n       = require "n"

local start = gettime ()
for _ = 1, n do
  local _ = hotswap "serpent"
end
local finish = gettime ()

print (math.floor (n / (finish - start)), "requires/second")