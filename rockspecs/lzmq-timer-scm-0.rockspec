package = "lzmq-timer"
version = "scm-0"

source = {
  url = "https://github.com/moteus/lzmq/archive/master.zip",
  dir = "lzmq-master",
}

description = {
  summary = "Milliseconds timer",
  homepage = "https://github.com/moteus/lzmq",
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