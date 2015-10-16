local gettime = require "socket".gettime
local n       = require "n"
local hotswap = require "hotswap.http" {
  encode = function (t)
    if next (t) == nil
    or next (t, next (t)) ~= nil then
      return
    end
    local k, v = next (t)
    return {
      url     = "http://127.0.0.1:8080/lua/" .. k,
      method  = "GET",
      headers = {
        ["If-None-Match"] = type (v) == "table" and v.etag or nil,
        ["Lua-Module"   ] = k,
      },
    }
  end,
  decode = function (t)
    local module = t.request.headers ["Lua-Module"]
    if t.code == 200 then
      return {
        [module] = {
          lua  = t.body,
          etag = t.headers.etag,
        },
      }
    elseif t.code == 304 then
      return {
        [module] = {},
      }
    elseif t.code == 404 then
      return {}
    else
      assert (false)
    end
  end,
}

assert (os.execute [[
  rm -rf ./nginx/*.log ./nginx/*.pid
  /usr/sbin/nginx -p ./nginx/ -c nginx.conf 2> /dev/null
]])

local start = gettime ()
for _ = 1, n do
  local _ = hotswap.require "toload"
end
local finish = gettime ()

print (math.floor (n / (finish - start)), "requires/second")
assert (os.execute [[
  kill -QUIT $(cat ./nginx/nginx.pid)
]])
