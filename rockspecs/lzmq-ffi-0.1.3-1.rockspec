package = "lzmq-ffi"
version = "0.1.3-1"

source = {
  url = "https://github.com/moteus/lzmq/archive/v0.1.3.zip",
  dir = "lzmq-0.1.3",
}

description = {
  summary = "Lua bindings to ZeroMQ 3",
  homepage = "https://github.com/moteus/lzmq",
  license = "MIT/X11",
}

dependencies = {
  "lua >= 5.1",
  -- "lua-llthreads >= 1.2"
  -- "lzmq-timer"
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
    ["lzmq"              ] = "src/lua/lzmq/ffi/lzmq.lua";
    ["lzmq.ffi"          ] = "src/lua/lzmq/ffi.lua";

    ["lzmq.loop"         ] = "src/lua/lzmq/loop.lua";
    ["lzmq.poller"       ] = "src/lua/lzmq/ffi/poller.lua";
    ["lzmq.threads"      ] = "src/lua/lzmq/threads.lua";

    ["lzmq.ffi.api"      ] = "src/lua/lzmq/ffi/api.lua";
    ["lzmq.ffi.error"    ] = "src/lua/lzmq/ffi/error.lua";

    ["lzmq.llthreads.ex" ] = "src/lua/lzmq/llthreads/ex.lua";
    ["lzmq.impl.threads" ] = "src/lua/lzmq/impl/threads.lua";
    ["lzmq.impl.loop"    ] = "src/lua/lzmq/impl/loop.lua";
  },
}
