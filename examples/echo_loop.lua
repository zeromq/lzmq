local zmq = require "lzmq"
local zloop = require "lzmq.loop" 
require "utils"

print_version(zmq)

main_loop = zloop.new()

ECHO_ADDR = {
  "inproc://echo";
  "tcp://127.0.0.1:5555";
}

main_loop:add_new_bind(zmq.REP, ECHO_ADDR, function(skt)
  local msg = assert(print_msg("SRV RECV: ",skt:recv()))
  assert(skt:send(msg))
end)

local cli = main_loop:create_connect(zmq.REQ, ECHO_ADDR)

main_loop:add_interval(2000, function(ev) 
  assert(cli:send('hello from timer'))
  main_loop:add_socket(cli, function(skt,events,loop)
    print_msg("CLI RECV: ", skt:recv())
    loop:remove_socket(skt)
  end)
end)

main_loop:start()
