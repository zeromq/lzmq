local zmq = require "lzmq"
local assert = zmq.assert

local ctx = zmq.context()
local skt = ctx:socket(zmq.REQ)
assert(skt:connect("tcp://127.0.0.1:5555"))
assert(skt:send("hello"))
print(assert(skt:recv()))