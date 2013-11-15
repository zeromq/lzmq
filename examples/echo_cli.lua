local zmq = require "lzmq"
require "utils"

print_version(zmq)

local ctx = zmq.context()

local skt = ctx:socket{zmq.REQ,
  linger = 0, rcvtimeo = 1000;
  connect = "tcp://127.0.0.1:5555";
}

skt:send("hello from cli")
print_msg("recv: ",skt:recv())

skt:close()
ctx:destroy()
