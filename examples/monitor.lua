local zmq   = require "lzmq"
local zloop = require "lzmq.loop"

local loop = zloop.new()

local srv, err = loop:create_socket{zmq.REP,
  linger = 0, sndtimeo = 100, rcvtimeo = 100;
  bind = {
    "inproc://test.zmq";
    "tcp://*:9000";
  }
}
loop:add_socket(srv, function(sok)
  print("SERVER:", sok:recv())
  sok:send(", world!");
end)

local mon = loop:create_socket{zmq.PAIR,
  connect = zmq.assert(srv:monitor());
}
loop:add_socket(mon, function(sok)
  local event, data, addr = sok:recv_event()
  print("MONITOR:", event, data, addr)
end)

local cli, err = loop:create_socket{zmq.REQ,
  linger = 0, sndtimeo = 100, rcvtimeo = 100;
  connect = "tcp://127.0.0.1:9000";
}
loop:add_socket(cli, function(sok)
  print("CLIENT:", sok:recv())
  sok:send("Hello");
end)

loop:add_once(100, function()
  loop:interrupt()
end)

loop:add_once(50, function()
  cli:disconnect("tcp://127.0.0.1:9000")
end)

loop:add_once(0, function()
  cli:send("Hello");
end)

loop:start()

