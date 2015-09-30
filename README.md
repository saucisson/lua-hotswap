Require with hotswapping
========================

Sometimes, we would like to reload automatically an updated module
within a long-running program. The `hotswap` module provides such
functionality, using various backends for change detection.

See [Wikipedia](https://en.wikipedia.org/wiki/Hot_swapping#Software)

Install
-------

This module is available as a Lua rock:

````sh
    luarocks install hotswap
````

Example
-------

The easiest way to use this library is as below:

````lua
    local hotswap  = require "hotswap".new ()
    local mymodule = hotswap.require "mymodule"
    ...
````

Note that this is useless, as there is not hotswapping in the default
behavior. Note also that the `.new ()` can be omitted if you need only one
instance of the `hotswap` module.

An easy way to use hotswapping is to require the updated module within
a loop. The following code reloads the module only when its file hash hash
changed:

````lua
    local hotswap = require "hotswap.hash"
    while true do
      local mymodule = hotswap.require "mymodule"
      ...
    end
````

The same applies with file modification date given by `lfs`:

````lua
    local hotswap = require "hotswap.lfs"
    while true do
      local mymodule = hotswap.require "mymodule"
      ...
    end
````

A more advanced use is for instance with `lua-ev` in a idle loop:

````lua
    local ev      = require "ev"
    local hotswap = require "hotswap.ev"
    ev.Idle.new (function ()
      local mymodule = hotswap.require "mymodule"
      ...
    end):start (ev.Loop.default)
    ev.Loop.default:loop ()
````

The `hotswap` can even replace the `require` function easily:

````lua
    require = require "hotswap.xxx".require
````

Backends
--------

Currently, the following backends are supported:

* `hotswap`: the default backend does not perform any change detection,
  see [this example](bench/bench-raw.lua);
* `hotswap.ev`: this backend detects module changes using `lua-ev`,
  see [this example](bench/bench-ev.lua);
* `hotswap.hash`: this backend detects module changes by checking file hashes
  using `xxhah`,
  see [this example](bench/bench-hash.lua);
* `hotswap.lfs`: this backend detects module changes by observing file
  modification date using `luafilesystem`,
  see [this example](bench/bench-lfs.lua).

Notice that the dependencies for each backend are not listed in the rockspec.
Make sure to install them!

Compatibility
-------------

This module makes use of `package.searchers`, available from Lua 5.2. If you
are running under Lua 5.1 or LuaJIT, a fake `package.searchers` will be
automatically created.

Benchmarks
----------

The [bench](bench/) directory contains benchmarks for the backends. They
can be run using:

````sh
    cd bench/
    for bench in bench-*.lua
    do
      echo ${bench}
      luajit ${bench}
    done
    cd ..
````
