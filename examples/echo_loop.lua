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

main_loop:add_new_bind(zmq.REP, ECHO_ADDR, function(skt)
  local msg = zassert(print_msg("SRV RECV: ",skt:recv_all()))
  zassert(skt:send_all(msg))
end)

local cli = main_loop:add_new_connect(zmq.REQ, ECHO_ADDR, function(skt,events,loop)
  local msg = zassert(print_msg("CLI RECV: ", skt:recv_all()))
  loop:add_once(ECHO_TIME, function(ev,loop) 
    zassert(skt:send_all(msg))
  end)
end)

main_loop:add_once(2000, function(ev, loop) 
  zassert(cli:send_all{'hello', 'world'})
end)

main_loop:start()
