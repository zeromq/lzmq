package = "lzmq"
version = "scm-0"

source = {
  url = "https://github.com/moteus/lzmq/archive/master.zip",
  dir = "lzmq-master",
}

description = {
  summary = "Lua bindings to ZeroMQ 3",
  homepage = "https://github.com/moteus/lzmq",
  -- license = "",
}

dependencies = {
  "lua >= 5.1",
  "lake >= 1.2",
}

build = {
  type = "command",
  build_command = "lake install ROOT=$(PREFIX) LUADIR=$(LUADIR) LIBDIR=$(LIBDIR)",
}
