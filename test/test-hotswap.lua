require "busted.runner" ()

local assert = require "luassert"

if not package.searchers then
  require "compat52"
end

describe ("the hotswap module", function ()

  it ("can be required", function ()
    assert.has.no.error (function ()
      require "hotswap"
    end)
  end)

  it ("requires preloaded modules", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap"
      Hotswap.require "string"
    end)
  end)

  it ("requires lua modules", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap"
      Hotswap.require "busted"
    end)
  end)

  it ("requires binary modules", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap"
      Hotswap.require "socket"
    end)
  end)

  it ("allows to test require", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap"
      assert.is_truthy (Hotswap.try_require "busted")
      assert.is_falsy  (Hotswap.try_require "nonexisting")
    end)
  end)

end)
