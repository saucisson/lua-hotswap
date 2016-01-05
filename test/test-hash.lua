require "busted.runner" ()

local assert = require "luassert"

if not package.searchers then
  require "compat52"
end

describe ("the hotswap.hash module", function ()

  it ("can be required", function ()
    assert.has.no.error (function ()
      require "hotswap.hash"
    end)
  end)

  it ("requires preloaded modules", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.hash"
      Hotswap.require "string"
    end)
  end)

  it ("requires lua modules", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.hash"
      Hotswap.require "coroutine.make"
    end)
  end)

  it ("requires binary modules", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.hash"
      Hotswap.require "socket"
    end)
  end)

  it ("allows to test require", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.hash"
      assert.is_truthy (Hotswap.try_require "coroutine.make")
      assert.is_falsy  (Hotswap.try_require "nonexisting")
    end)
  end)

end)
