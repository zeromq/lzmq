package = "lzmq"
version = "0.4.2-1"

source = {
  url = "https://github.com/zeromq/lzmq/archive/v0.4.2.zip",
  dir = "lzmq-0.4.2",
}

description = {
  summary = "Lua bindings to ZeroMQ",
  homepage = "https://github.com/zeromq/lzmq",
  license = "MIT/X11",
}

dependencies = {
  "lua >= 5.1, < 5.4",
  -- "lua-llthreads2 >= 0.1.2"
}

external_dependencies = {
  platforms = {
    windows = {
      ZMQ = {
        header  = "zmq.h",
        library = "libzmq",
      }
    };
    unix = {
      ZMQ = {
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
      ["lzmq"] = {
        libraries = {"libzmq"},
      }
    }},
    unix    = { modules = {
      ["lzmq"] = {
        libraries = {"zmq"},
      }
    }},
    linux   = { modules = {
      ["lzmq.timer"] = {
        libraries = {"rt"},
      },
    }},
  },

  modules = {
    ["lzmq"] = {
      sources = {'src/lzmq.c','src/lzutils.c','src/poller.c',
                 'src/zcontext.c','src/zerror.c','src/zmsg.c',
                 'src/zpoller.c','src/zsocket.c'},
      incdirs = {"$(ZMQ_INCDIR)"},
      libdirs = {"$(ZMQ_LIBDIR)"},
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
