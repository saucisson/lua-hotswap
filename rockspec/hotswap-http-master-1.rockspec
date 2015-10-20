package = "hotswap.http"
version = "master-1"

source = {
  url = "git://github.com/saucisson/lua-hotswap",
}

description = {
  summary    = "Hotswap backend using http",
  detailed   = [[]],
  license    = "MIT/X11",
  homepage   = "https://github.com/saucisson/lua-hotswap",
  maintainer = "Alban Linard <alban@linard.fr>",
}

dependencies = {
  "lua           >= 5.1",
  "hotswap       >= 1",
  "luafilesystem >= 1",
  "luasec        >= 0",
  "luasocket     >= 2",
  "serpent       >= 0",
}

build = {
  type    = "builtin",
  modules = {
    ["hotswap.http"] = "src/hotswap/http.lua",
  },
}
