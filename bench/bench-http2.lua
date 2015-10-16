local json    = require "cjson"
local ltn12   = require "ltn12"
local gettime = require "socket".gettime
local n       = require "n"
local hotswap = require "hotswap.http" {
  encode = function (t)
    local data = json.encode (t)
    return {
      url     = "http://127.0.0.1:8080/luaset",
      method  = "POST",
      headers = {
        ["If-None-Match" ] = type (v) == "table" and v.etag or nil,
        ["Content-Length"] = #data,
      },
      source  = ltn12.source.string (data),
    }
  end,
  decode = function (t)
    return json.decode (t.body)
  end,
}

assert (os.execute [[
  rm -rf ./nginx/*.log ./nginx/*.pid
  /usr/sbin/nginx -p ./nginx/ -c nginx.conf 2> /dev/null
]])

local start = gettime ()
for _ = 1, n do
  local _ = hotswap.require "cosy.string"
end
local finish = gettime ()

print (math.floor (n / (finish - start)), "requires/second")
assert (os.execute [[
  kill -QUIT $(cat ./nginx/nginx.pid)
]])
