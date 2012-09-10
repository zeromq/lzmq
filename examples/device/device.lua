local zmq = require "lzmq"


local ctx = zmq.context()
local fe = ctx:socket(zmq.ROUTER)
local be = ctx:socket(zmq.DEALER)

fe:bind("tcp://127.0.0.1:5555")
be:bind("tcp://127.0.0.1:5556")

if zmq.proxy then 
  print("use proxy")
  zmq.proxy(fe, be)
else
  print("use device")
  zmq.device(zmq.QUEUE, fe, be)
end
