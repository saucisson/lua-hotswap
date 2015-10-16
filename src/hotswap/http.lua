local http    = require "socket.http"
local https   = require "ssl.https"
local lfs     = require "lfs"
local ltn12   = require "ltn12"
local serpent = require "serpent"
local Hotswap = getmetatable (require "hotswap")
local Http    = {}

--[[

Send: {
  name = {
    etag = "...", -- optional
  },
}

Receive: {
  name = {},  -- no change
  name = {    -- updated
    etag = "...",
    lua  = "...",
  },
  name = nil, -- not found
}
--]]

local function request (t)
  local result = {}
  if type (t) == "string" then
    t = {
      url = t,
    }
  end
  assert (type (t) == "table")
  t.sink = ltn12.sink.table (result)
  local _, code, headers, status
  if     t.url:match "^http://" then
    _, code, headers, status = http .request (t)
  elseif t.url:match "https://" then
    _, code, headers, status = https.request (t)
  else
    assert (false)
  end
  return {
    body    = table.concat (result),
    code    = code,
    headers = headers,
    status  = status,
    request = t,
  }
end

function Http.new (t)
  local instance = Hotswap.new {
    new     = Http.new,
    preload = Http.preload,
    load    = Http.load,
    save    = Http.save,
    encode  = t and t.encode or assert (false),
    decode  = t and t.decode or assert (false),
    storage = t and t.storage or os.tmpname (),
  }
  os.remove (instance.storage)
  lfs.mkdir (instance.storage)
  instance.downloaded = instance.storage .. "/_list"
  local ok, data = serpent.load (instance.downloaded, {
    safe = true,
  })
  instance.data = ok and data or {}
  local function from_storage (name)
    return loadfile (instance.storage .. "/" .. name)
  end
  local function from_http (name)
    local result = instance.decode (request (instance.encode {
      [name] = instance.data [name] or true,
    }))
    if not result then
      return
    end
    instance:load (name, result [name])
    instance:save ()
    return from_storage (name)
  end
  table.insert (package.searchers, 2, from_storage)
  table.insert (package.searchers, 3, from_http   )
  instance:preload ()
  return instance
end

function Http:preload ()
  if not next (self.data) then
    return
  end
  local encoded = self.encode (self.data)
  local result
  if encoded then
    result = self.decode (request (encoded))
  else
    result = {}
    for key, t in pairs (self.data) do
      local subresult = self.decode (request (self.encode {
        key = t,
      }))
      result [key] = subresult [key]
    end
  end
  assert (type (result) == "table")
  for key, t in pairs (result) do
    self:load (key, t)
  end
  self:save ()
end

function Http:load (key, t)
  assert (type (key) == "string")
  if not t then
    self.data [key] = nil
    os.remove (self.storage .. "/" .. key)
    return
  end
  assert (type (t) == "table")
  if not t.lua then
    return
  end
  local file = io.open (self.storage .. "/" .. key, "w")
  if file then
    file:write (t.lua)
    file:close ()
  end
  self.data [key] = self.data [key] or {}
  for k, v in pairs (t) do
    if k ~= "lua" then
      self.data [key] [k] = v
    end
  end
end

function Http:save ()
  local file = io.open (self.downloaded, "w")
  if file then
    file:write (serpent.dump (self.data, {
      indent   = "  ",
      comment  = false,
      sortkeys = true,
      compact  = false,
      fatal    = true,
      nocode   = true,
    }))
    file:close ()
  end
end

return Http.new
