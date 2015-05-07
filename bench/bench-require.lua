local gettime = require "socket".gettime
local n       = require "n"

local start = gettime ()
for _ = 1, n do
  local _ = require "serpent"
end
local finish = gettime ()

print (math.floor (n / (finish - start)), "requires/second")