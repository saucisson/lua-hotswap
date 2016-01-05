require "busted.runner" ()

local assert = require "luassert"

if not package.searchers then
  require "compat52"
end

describe ("the hotswap.http module", function ()

  local tmp
  local options = {
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

  setup (function ()
    tmp = os.tmpname ()
    local command = ([[
      rm    -f {{{TMP}}}
      mkdir -p {{{TMP}}}
      cp bench/nginx/nginx.conf {{{TMP}}}/nginx.conf
      nginx -p {{{TMP}}} -c {{{TMP}}}/nginx.conf
    ]]):gsub ("{{{TMP}}}", tmp)
    print (command)
    assert (os.execute (command))
  end)

  teardown (function ()
    local command = ([[
      kill -QUIT $(cat {{{TMP}}}/nginx.pid)
      rm   -rf {{{TMP}}}
    ]]):gsub ("{{{TMP}}}", tmp)
    assert (os.execute (command))
  end)

  it ("can be required", function ()
    assert.has.no.error (function ()
      require "hotswap.http"
    end)
  end)

  it ("can be instantiated", function ()
    assert.has.no.error (function ()
      require "hotswap.http" (options)
    end)
  end)

  it ("requires preloaded modules", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.http" (options)
      Hotswap.require "string"
    end)
  end)

  it ("requires lua modules", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.http" (options)
      Hotswap.require "busted"
    end)
  end)

  it ("requires binary modules", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.http" (options)
      Hotswap.require "socket"
    end)
  end)

  it ("allows to test require", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.http" (options)
      assert.is_truthy (Hotswap.try_require "busted")
      assert.is_falsy  (Hotswap.try_require "nonexisting")
    end)
  end)

end)
