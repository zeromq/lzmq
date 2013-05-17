package = "lzmq-timer"
version = "0.1.2-1"

source = {
  url = "https://github.com/moteus/lzmq/archive/v0.1.2.zip",
  dir = "lzmq-0.1.2",
}

description = {
  summary = "Lua bindings to ZeroMQ 3",
  homepage = "https://github.com/moteus/lzmq",
  license = "MIT/X11",
}

dependencies = {
  "lua >= 5.1",
  -- "lua-llthreads >= 1.2"
}

build = {
  copy_directories = {"test", "examples"},

  type = "builtin",

  platforms = {
    windows = { modules = {
      ["lzmq.timer"] = {
        defines = {'USE_PERF_COUNT'}
      }
    }},
    unix    = { modules = {
      ["lzmq.timer"] = {
        defines = {'USE_CLOCK_MONOTONIC', 'USE_GETTIMEOFDAY'},
        libraries = {"rt"},
      }
    }}
  },

  modules = {
    ["lzmq.timer"] = {
      sources = {'src/ztimer.c','src/lzutils.c'},
    },
  },
}