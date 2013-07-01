package = "lzmq"
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
}

external_dependencies = {
  platforms = {
    windows = {
      ZMQ3 = {
        header  = "zmq.h",
        library = "libzmq3",
      }
    };
    unix = {
      ZMQ3 = {
        header  = "zmq.h",
        -- library = "zmq", -- does not work !?
      }
    };
  }
}

build = {
  copy_directories = {"test", "examples"},

  type = "builtin",

  platforms = {
    windows = { modules = {
      ["lzmq.timer"] = {
        defines = {'USE_PERF_COUNT'}
      },
      ["lzmq"] = {
        libraries = {"libzmq3"},
      }
    }},
    unix    = { modules = {
      ["lzmq.timer"] = {
        defines = {'USE_CLOCK_MONOTONIC', 'USE_GETTIMEOFDAY'},
        libraries = {"rt"},
      },
      ["lzmq"] = {
        libraries = {"zmq"},
      }
    }}
  },

  modules = {
    ["lzmq"] = {
      sources = {'src/lzmq.c','src/lzutils.c','src/poller.c',
                 'src/zcontext.c','src/zerror.c','src/zmsg.c',
                 'src/zpoller.c','src/zsocket.c'},
      incdirs = {"$(ZMQ3_INCDIR)"},
      libdirs = {"$(ZMQ3_LIBDIR)"},
      defines = {
        'LUAZMQ_USE_SEND_AS_BUF',
        'LUAZMQ_USE_TEMP_BUFFERS',
        'LUAZMQ_USE_ERR_TYPE_OBJECT',
        -- 'LUAZMQ_USE_ERR_TYPE_NUMBER'
        -- 'LUAZMQ_USE_ERR_TYPE_STRING'
      },
    },
    ["lzmq.timer"] = {
      sources = {'src/ztimer.c','src/lzutils.c'},
    },
    ["lzmq.loop"         ] = "src/lua/lzmq/loop.lua";
    ["lzmq.poller"       ] = "src/lua/lzmq/poller.lua";
    ["lzmq.threads"      ] = "src/lua/lzmq/threads.lua";
    ["lzmq.ffi"          ] = "src/lua/lzmq/ffi.lua";
    ["lzmq.ffi.api"      ] = "src/lua/lzmq/ffi/api.lua";
    ["lzmq.ffi.error"    ] = "src/lua/lzmq/ffi/error.lua";
    ["lzmq.ffi.loop"     ] = "src/lua/lzmq/ffi/loop.lua";
    ["lzmq.ffi.poller"   ] = "src/lua/lzmq/ffi/poller.lua";
    ["lzmq.ffi.timer"    ] = "src/lua/lzmq/ffi/timer.lua";
    ["lzmq.ffi.threads"  ] = "src/lua/lzmq/ffi/threads.lua";
    ["lzmq.llthreads.ex" ] = "src/lua/lzmq/llthreads/ex.lua";
    ["lzmq.impl.threads" ] = "src/lua/lzmq/impl/threads.lua";
    ["lzmq.impl.loop"    ] = "src/lua/lzmq/impl/loop.lua";
  },
}
