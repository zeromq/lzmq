cmake_minimum_required ( VERSION 2.8 )

project ( lzmq C )
include ( cmake/dist.cmake )
include ( lua )

find_package ( ZMQ REQUIRED )

include_directories ( ${CMAKE_CURRENT_SOURCE_DIR}/src )
include_directories ( ${ZMQ_INCLUDE_DIR} )

set ( LZMQ_SRC
  src/lzmq.c     src/lzutils.c src/poller.c
  src/zcontext.c src/zerror.c  src/zmsg.c
  src/zpoller.c  src/zsocket.c
)

set ( LZMQ_DEFINE LUAZMQ_USE_SEND_AS_BUF LUAZMQ_USE_TEMP_BUFFERS LUAZMQ_USE_ERR_TYPE_OBJECT )

set ( LZTIMER_SRC src/ztimer.c src/lzutils.c )

install_lua_module ( lzmq ${LZMQ_SRC} LINK ${ZMQ_LIBRARY} )

set_target_properties ( lzmq PROPERTIES COMPILE_DEFINITIONS "${LZMQ_DEFINE}" )

install_lua_module ( lzmq.loop         src/lua/lzmq/loop.lua         )
install_lua_module ( lzmq.poller       src/lua/lzmq/poller.lua       )
install_lua_module ( lzmq.threads      src/lua/lzmq/threads.lua      )
install_lua_module ( lzmq.ffi          src/lua/lzmq/ffi.lua          )
install_lua_module ( lzmq.ffi.api      src/lua/lzmq/ffi/api.lua      )
install_lua_module ( lzmq.ffi.error    src/lua/lzmq/ffi/error.lua    )
install_lua_module ( lzmq.ffi.loop     src/lua/lzmq/ffi/loop.lua     )
install_lua_module ( lzmq.ffi.poller   src/lua/lzmq/ffi/poller.lua   )
install_lua_module ( lzmq.ffi.timer    src/lua/lzmq/ffi/timer.lua    )
install_lua_module ( lzmq.ffi.threads  src/lua/lzmq/ffi/threads.lua  )
install_lua_module ( lzmq.llthreads.ex src/lua/lzmq/llthreads/ex.lua )
install_lua_module ( lzmq.impl.threads src/lua/lzmq/impl/threads.lua )
install_lua_module ( lzmq.impl.loop    src/lua/lzmq/impl/loop.lua    )

if(UNIX AND NOT APPLE)
  set ( RT_LIBRARY rt )
else()
  set ( RT_LIBRARY )
endif()

install_lua_module ( lzmq.timer ${LZTIMER_SRC} LINK ${RT_LIBRARY} )

install_data ( README.md LICENCE.txt )

install_example ( examples/ )

install_test ( test/ examples/utils.lua )
