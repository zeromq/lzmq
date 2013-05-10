#Lua binding to [ZeroMQ 3](http:\\zeromq.org) library.

[![Build Status](https://travis-ci.org/moteus/lzmq.png)](https://travis-ci.org/moteus/lzmq)

This library use `zmq.poller` and `zmq.threads` from [lua-zmq](https://github.com/Neopallium/lua-zmq) binding.
But this library is not dropin replacement for lua-zmq library.

##API
This is almost 1:1 binding to ZeromMQ 3.2 library.
###Constant
ZMQ_CONSTANT_NAME in the C API turns into zmq.CONSTANT_NAME in Lua.
###Error codes
EXXX in the C API turns into zmq.EXXX and zmq.errors.EXXX in Lua.
###Options
ZMQ_OPTION_NAME in the C API 
- if this is read/write option then it turns into 2 functions 
`obj:set_option_name(value)` and `obj:get_option_name()`

**For example:**
ZMQ_IO_THREADS => ctx:get_io_threads()/ ctx:set_io_threads(1)
- if this is readonly  option then it turns into 2 functions 
`obj:option_name()` and `obj:get_option_name()`

**For example:**
ZMQ_FD => skt:fd() / skt:get_fd()
- if this is writeonly  option then it turns into 2 functions 
`obj:option_name(value)` and `obj:set_option_name(value)`

**For example:**
ZMQ_SUBSCRIBE => skt:subscribe("") / skt:set_subscribe("")

----
###Incompatibility list with lua-zmq (this is not full)

|    Feature           |      lua-zmq           |        lzmq              |
|----------------------|------------------------|--------------------------|
|global zmq variable   | create                 | does not create          |
|zmq.init              | io_threads optional    | io_threads require       |
|create message        | zmq.zmq_msg_t.init_XXX | zmq.msg_init_XXX         |
|message as string     | tostring(msg)          | msg:data()/tostring(msg) |
|message as ud         | msg:data()             | msg:pointer()            |
|msg:close();msg:data()| AV                     | lua error                |

