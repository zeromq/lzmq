#Lua binding to [ZeroMQ](http://zeromq.org) library.

[![Build Status](https://travis-ci.org/moteus/lzmq.png?branch=master)](https://travis-ci.org/moteus/lzmq)

Support ZeromMQ 3.2/4.0

This library use `zmq.poller` and `zmq.threads` from [lua-zmq](https://github.com/Neopallium/lua-zmq) binding.
But this library is not dropin replacement for lua-zmq library.

----
##API
This is almost 1:1 binding to ZeromMQ 3.2 library.
This is short [API](http://moteus.github.io/lzmq/index.html) description.
See also [exampes](https://github.com/moteus/lzmq-zguide) form [OMQ - The Guide](http://zguide.zeromq.org).
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
##Performance
To run same test you should copy original performance tests to `exampes/perf2/libzmq`
and run `runner.lua` from `exampes/perf2`. For now it require LuaJIT and exists 
C and FFI version of `lzmq` library.
Of course you can run any test manually.

###Inproc Throughput Test:

message size: 30 [B]<br/>
message count: 10000<br/>
mean throughput [Mb/s]:<br/>

| # | libzmq     | str        | str(ffi)   | msg        | msg(ffi)   |
|---|------------|------------|------------|------------|------------|
| 1 |386.972     |307.338     |414.794     |173.875     |265.928     |
| 2 |361.663     |311.567     |412.584     |168.327     |323.799     |
| 3 |344.927     |307.890     |395.062     |159.511     |320.299     |
| 4 |437.079     |192.864     |414.222     |156.108     |324.368     |
| 5 |400.668     |309.598     |398.142     |168.161     |317.502     |
| 6 |101.613     |302.229     |393.185     |171.932     |315.126     |
| 7 |378.847     |310.238     |398.473     |165.551     |315.748     |
| 8 |381.679     |309.797     |417.246     |167.096     |330.761     |
| 9 |309.517     |309.997     |412.442     |156.914     |331.858     |
| 10|294.804     |306.083     |392.029     |163.310     |324.763     |

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

