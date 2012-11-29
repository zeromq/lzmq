local zmq     = require "lzmq"
local zloop   = require "lzmq.loop" 
local zassert = zmq.assert
require "utils"

print_version(zmq)

main_loop = zloop.new()

local ECHO_ADDR = {
  "inproc://echo";
  "tcp://127.0.0.1:5555";
}
local ECHO_TIME = 1000

local ctx = zmq.init(1)
local skt = ctx:socket(zmq.ROUTER)
skt:set_router_raw(1)
skt:bind('tcp://127.0.0.1:5555')

main_loop:add_socket(skt, function(skt)
  local msg = zassert(print_msg("SRV RECV: ",skt:recv_all()))
  zassert(skt:send_all(msg))
end)

main_loop:start()
