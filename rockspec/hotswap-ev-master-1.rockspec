package = "hotswap-ev"
version = "master-1"

source = {
  url = "git://github.com/saucisson/lua-hotswap",
}

description = {
  summary    = "Hotswap backend using lua-ev",
  detailed   = [[]],
  license    = "MIT/X11",
  homepage   = "https://github.com/saucisson/lua-hotswap",
  maintainer = "Alban Linard <alban@linard.fr>",
}

dependencies = {
  "lua      >= 5.1",
  "hotswap  >= 1",
  "lua-ev   >= v1",
  "luaposix >= 33",
  "xxhash   >= v1",
}

build = {
  type    = "builtin",
  modules = {
    ["hotswap.ev"] = "src/hotswap/ev.lua",
  },
}
