local zmq = require "lzmq"
local assert = zmq.assert

local ctx = zmq.context()
local skt = ctx:socket(zmq.REP)
skt:connect("tcp://127.0.0.1:5556")
while(true)do
  print(assert(skt:recv()))
  assert(skt:send("world"))
end