package = "lzmq-timer"
version = "0.4.2-1"

source = {
  url = "https://github.com/zeromq/lzmq/archive/v0.4.2.zip",
  dir = "lzmq-0.4.2",
}

description = {
  summary = "Milliseconds timer",
  homepage = "https://github.com/zeromq/lzmq",
  license = "MIT/X11",
}

dependencies = {
  "lua >= 5.1, < 5.4",
}

build = {
  copy_directories = {},

  type = "builtin",

  platforms = {
    linux   = { modules = {
      ["lzmq.timer"] = {
        libraries = {"rt"},
      }
    }},
  },

  modules = {
    ["lzmq.timer"] = {
      sources = {'src/ztimer.c','src/lzutils.c'},
    },
  },
}