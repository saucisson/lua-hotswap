require "busted.runner" ()

local assert = require "luassert"
local ev     = require "ev"

if not package.searchers then
  require "compat52"
end

describe ("the hotswap.ev module", function ()

  it ("can be required", function ()
    assert.has.no.error (function ()
      require "hotswap.ev"
    end)
  end)

  it ("requires preloaded modules", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.ev"
      ev.Idle.new (function (loop, idle, _)
        Hotswap.require "string"
        idle:stop (loop)
        loop:unloop ()
      end):start (ev.Loop.default)
      ev.Loop.default:loop ()
    end)
  end)

  it ("requires lua modules", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.ev"
      ev.Idle.new (function (loop, idle, _)
        Hotswap.require "busted"
        idle:stop (loop)
        loop:unloop ()
      end):start (ev.Loop.default)
      ev.Loop.default:loop ()
    end)
  end)

  it ("requires binary modules", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.ev"
      ev.Idle.new (function (loop, idle, _)
        Hotswap.require "socket"
        idle:stop (loop)
        loop:unloop ()
      end):start (ev.Loop.default)
      ev.Loop.default:loop ()
    end)
  end)

  it ("allows to test require", function ()
    assert.has.no.error (function ()
      local Hotswap = require "hotswap.ev"
      ev.Idle.new (function (loop, idle, _)
        assert.is_truthy (Hotswap.try_require "busted")
        assert.is_falsy  (Hotswap.try_require "nonexisting")
        idle:stop (loop)
        loop:unloop ()
      end):start (ev.Loop.default)
      ev.Loop.default:loop ()
    end)
  end)

end)
