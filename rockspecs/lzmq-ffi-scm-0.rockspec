package = "lzmq-ffi"
version = "scm-0"

source = {
  url = "https://github.com/moteus/lzmq/archive/master.zip",
  dir = "lzmq-master",
}

description = {
  summary = "Lua bindings to ZeroMQ",
  homepage = "https://github.com/moteus/lzmq",
  license = "MIT/X11",
}

dependencies = {
  "lua >= 5.1, < 5.3",
  -- "lua-llthreads >= 1.2"
  -- "lzmq-timer"
}

build = {
  copy_directories = {"test", "examples"},

  type = "builtin",

  platforms = {
    linux   = { modules = {
      ["lzmq.timer"] = {
        libraries = {"rt"},
      },
    }},
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
