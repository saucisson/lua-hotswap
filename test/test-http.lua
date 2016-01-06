require "busted.runner" ()

local assert = require "luassert"
local socket = require "socket"

if not package.searchers then
  require "compat52"
end

describe ("the hotswap.http module", function ()

  local _package_path  = package.path
  local _package_cpath = package.cpath
  local tmp
  local port
  local options

  setup (function ()
    local server = socket.bind ("*", 0)
    local _, p = server:getsockname ()
    server:close ()
    port = p
    tmp  = os.tmpname ()
    local conf_file = io.open ("test/nginx.conf", "r")
    local conf      = conf_file:read "*all"
    conf_file:close ()
    conf = conf
         :gsub ("{{{TMP}}}"  , tmp)
         :gsub ("{{{PORT}}}" , tostring (port))
         :gsub ("{{{PATH}}}" , string.format ("%q", package.path  .. ";" .. package.path :gsub ("5%.%d", "5.1")))
         :gsub ("{{{CPATH}}}", string.format ("%q", package.cpath .. ";" .. package.cpath:gsub ("5%.%d", "5.1")))
    conf_file = io.open (tmp, "w")
    conf_file:write (conf .. "\n")
    conf_file:close ()
    local command = ([[
      mv    {{{TMP}}} {{{TMP}}}.back
      mkdir -p {{{TMP}}}
      mv    {{{TMP}}}.back {{{TMP}}}/nginx.conf
      nginx -p {{{TMP}}} -c {{{TMP}}}/nginx.conf
    ]]):gsub ("{{{TMP}}}", tmp)
    assert (os.execute (command))
    options = {
      encode = function (t)
        if next (t) == nil
        or next (t, next (t)) ~= nil then
          return
        end
        local k, v = next (t)
        return {
          url     = "http://127.0.0.1:" .. tostring (port) .. "/lua/" .. k,
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
          return nil
        end
      end,
    }
  end)

  teardown (function ()
    local command = ([[
      kill -QUIT $(cat {{{TMP}}}/nginx.pid)
      rm   -rf {{{TMP}}}
    ]]):gsub ("{{{TMP}}}", tmp)
    assert (os.execute (command))
    package.path  = _package_path
    package.cpath = _package_cpath
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

  it ("fails to require preloaded modules through HTTP", function ()
    assert.has.error (function ()
      local Hotswap = require "hotswap.http" (options)
      Hotswap.loaded = {}
      Hotswap.path   = ""
      Hotswap.cpath  = ""
      Hotswap.require "string"
    end)
  end)

  it ("requires preloaded modules locally", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.http" (options)
      Hotswap.require "string"
    end)
  end)

  it ("requires lua modules through HTTP", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.http" (options)
      Hotswap.loaded = {}
      Hotswap.path   = ""
      Hotswap.cpath  = ""
      Hotswap.require "dkjson"
    end)
  end)

  it ("requires lua modules locally", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.http" (options)
      Hotswap.loaded = {}
      Hotswap.require "dkjson"
    end)
  end)

  it ("fails to require binary modules through HTTP", function ()
    assert.has.error (function ()
      local Hotswap = require "hotswap.http" (options)
      Hotswap.loaded = {}
      Hotswap.path   = ""
      Hotswap.cpath  = ""
      Hotswap.require "xxhash"
    end)
  end)

  it ("requires binary modules locally", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.http" (options)
      Hotswap.loaded = {}
      Hotswap.require "xxhash"
    end)
  end)

  it ("fails to require non existing modules through HTTP", function ()
    assert.has.error (function ()
      local Hotswap = require "hotswap.http" (options)
      Hotswap.loaded = {}
      Hotswap.path   = ""
      Hotswap.cpath  = ""
      Hotswap.require "nonexisting"
    end)
  end)

  it ("requires non existing modules locally", function ()
    assert.has.error (function ()
      local Hotswap = require "hotswap.http" (options)
      Hotswap.loaded = {}
      Hotswap.require "nonexisting"
    end)
  end)

  it ("allows to test require", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.http" (options)
      assert.is_truthy (Hotswap.try_require "dkjson")
      assert.is_falsy  (Hotswap.try_require "nonexisting")
    end)
  end)

end)
