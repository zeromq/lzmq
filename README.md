#Lua binding to [ZeroMQ 3](http:\\zeromq.org) library.

This library use `zmq.poller` and `zmq.threads` from [lua-zmq](https://github.com/Neopallium/lua-zmq) binding.
But this library is not dropin replacement for lua-zmq library.

###Incompatibility list with lua-zmq (this is not full)

|    Feature           |      lua-zmq           |        lzmq              |
|----------------------|------------------------|--------------------------|
|global zmq variable   | create                 | does not create          |
|zmq.init              | io_threads optional    | io_threads require       |
|skt:rcvmore           | return 0/1             | return true/false        |
|create message        | zmq.zmq_msg_t.init_XXX | zmq.msg_init_XXX         |
|message as string     | tostring(msg)          | msg:data()/tostring(msg) |
|message as ud         | msg:data()             | msg:pointer()            |
|msg:close();msg:data()| AV                     | lua error                |
