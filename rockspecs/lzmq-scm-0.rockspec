package = "lzmq"
version = "scm-0"

source = {
  url = "https://github.com/moteus/lzmq/archive/master.zip",
  dir = "lzmq-master",
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
    ["lzmq.loop"         ] = "lua/lzmq/loop.lua";
    ["lzmq.poller"       ] = "lua/lzmq/poller.lua";
    ["lzmq.threads"      ] = "lua/lzmq/threads.lua";
    ["lzmq.ffi"          ] = "lua/lzmq/ffi.lua";
    ["lzmq.ffi.api"      ] = "lua/lzmq/ffi/api.lua";
    ["lzmq.ffi.error"    ] = "lua/lzmq/ffi/error.lua";
    ["lzmq.ffi.loop"     ] = "lua/lzmq/ffi/loop.lua";
    ["lzmq.ffi.poller"   ] = "lua/lzmq/ffi/poller.lua";
    ["lzmq.ffi.timer"    ] = "lua/lzmq/ffi/timer.lua";
    ["lzmq.ffi.threads"  ] = "lua/lzmq/ffi/threads.lua";
    ["lzmq.llthreads.ex" ] = "lua/lzmq/llthreads/ex.lua";
    ["lzmq.impl.threads" ] = "lua/lzmq/impl/threads.lua";
    ["lzmq.impl.loop"    ] = "lua/lzmq/impl/loop.lua";
  },
}
