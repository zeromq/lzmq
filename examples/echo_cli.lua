local zmq = require "lzmq"
require "utils"

print_version(zmq)

local ctx = zmq.init(1)

local skt = ctx:socket(zmq.REQ)
skt:set_linger(0)
skt:set_rcvtimeo(1000)

assert(skt:connect("tcp://127.0.0.1:5555"))
assert(skt:send("hello from cli"))
print_msg("recv: ",skt:recv())

skt:close()
ctx:destroy()
