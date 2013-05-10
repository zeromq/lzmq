package = "lzmq"
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

external_dependencies = {
  ZMQ3 = {
    header  = "zmq.h",
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
    ["lzmq.loop"   ] = "lua/lzmq/loop.lua";
    ["lzmq.poller" ] = "lua/lzmq/poller.lua";
    ["lzmq.threads"] = "lua/lzmq/threads.lua";
  },
}