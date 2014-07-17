#Lua binding to [ZeroMQ](http://zeromq.org) library.

[![Build Status](https://travis-ci.org/zeromq/lzmq.png?branch=master)](https://travis-ci.org/zeromq/lzmq)
[![Build Status](https://buildhive.cloudbees.com/job/zeromq/job/lzmq/badge/icon)](https://buildhive.cloudbees.com/job/zeromq/job/lzmq/)
[![Coverage Status](https://coveralls.io/repos/zeromq/lzmq/badge.png?branch=master)](https://coveralls.io/r/zeromq/lzmq?branch=master)
[![Licence](http://img.shields.io/badge/Licence-MIT-brightgreen.svg)](LICENCE.txt)

Support ZeroMQ 3.2/4.0.<br/>
This library is not dropin replacement for [lua-zmq](https://github.com/Neopallium/lua-zmq) library.<br/>
This library has C and FFI version of binding.

##Source Code
https://github.com/zeromq/lzmq

##Install
If you plan use `lzmq.threads` module then you should also install [llthreads2](https://github.com/moteus/lua-llthreads2)<br/>

* Using *LuaRocks*:<br/>
`luarocks install lua-llthreads2` or `luarocks install lua-llthreads2-compat`<br/>
`luarocks install lzmq` or install only ffi version `luarocks install lzmq-ffi`<br/>

* Using *LuaDist*:<br/>
`luadist install lua-llthreads2` or `luadist install lua-llthreads2-compat`<br/>
`luadist install lzmq` or `luadist install lzmq-ffi`<br/>

##API
This is short [API](http://moteus.github.io/lzmq/index.html) description.<br/>
See also [exampes](https://github.com/moteus/lzmq-zguide) from [OMQ - The Guide](http://zguide.zeromq.org).<br/>

##Performance
To run same test you should copy original performance tests to `exampes/perf2/libzmq`
and run `runner.lua` from `exampes/perf2`. For now it require LuaJIT and exists 
C and FFI version of `lzmq` library.<br/>
Of course you can run any test manually.

###Inproc Throughput Test:

message size: 30 [B]<br/>
message count: 10000<br/>
mean throughput [Mb/s]:<br/>

| # | libzmq     | str        | str(ffi)   | msg        | msg(ffi)   |
|---|------------|------------|------------|------------|------------|
| 1 |349.396     |307.141     |393.636     |186.162     |239.617     |
| 2 |350.007     |310.398     |412.371     |188.132     |248.011     |
| 3 |377.596     |311.284     |413.010     |205.076     |281.228     |
| 4 |422.535     |308.206     |414.007     |174.406     |248.679     |
| 5 |392.477     |311.324     |411.876     |181.722     |274.946     |
| 6 |382.470     |309.917     |395.127     |177.528     |631.413     |
| 7 |393.636     |324.851     |415.010     |186.437     |282.686     |
| 8 |386.910     |303.298     |379.627     |116.919     |268.908     |
| 9 |397.022     |311.931     |415.945     |187.749     |244.998     |
| 10|438.196     |302.763     |412.229     |189.813     |255.646     |

###Inproc Latency Test:

message size: 1 [B]<br/>
message count: 10000<br/>
average latency [us]:<br/>

| # | libzmq     | str        | str(ffi)   | msg        | msg(ffi)   |
|---|------------|------------|------------|------------|------------|
| 1 |97.356      |97.378      |98.221      |94.274      |96.880      |
| 2 |95.828      |96.736      |95.957      |100.711     |96.992      |
| 3 |99.656      |100.347     |95.672      |97.981      |95.312      |
| 4 |96.649      |99.943      |94.543      |96.198      |94.674      |
| 5 |96.013      |102.196     |94.184      |97.575      |94.990      |
| 6 |96.371      |97.925      |98.377      |95.350      |97.165      |
| 7 |96.253      |93.625      |97.198      |94.856      |94.544      |
| 8 |95.155      |96.371      |94.904      |96.792      |95.507      |
| 9 |94.703      |96.698      |96.924      |97.951      |95.527      |
| 10|95.635      |97.946      |95.684      |96.429      |92.629      |

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


