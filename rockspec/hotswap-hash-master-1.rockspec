package = "hotswap-hash"
version = "master-1"

source = {
  url = "git://github.com/saucisson/lua-hotswap",
}

description = {
  summary    = "Hotswap backend using file hashes",
  detailed   = [[]],
  license    = "MIT/X11",
  homepage   = "https://github.com/saucisson/lua-hotswap",
  maintainer = "Alban Linard <alban@linard.fr>",
}

dependencies = {
  "lua     >= 5.1",
  "hotswap >= 1",
  "xxhash  >= v1",
}

build = {
  type    = "builtin",
  modules = {
    ["hotswap.hash"] = "src/hotswap/hash.lua",
  },
}
