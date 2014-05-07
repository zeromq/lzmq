local zmq      = require "lzmq"
local zloop    = require "lzmq.loop"

local function recv_zap(sok)
  local msg, err = sok:recv_all()
  if not msg then return nil, err end
  local req = {
    version    = msg[1]; -- Version number, must be "1.0"
    sequence   = msg[2]; -- Sequence number of request
    domain     = msg[3]; -- Server socket domain
    address    = msg[4]; -- Client IP address
    identity   = msg[5]; -- Server socket idenntity
    mechanism  = msg[6]; -- Security mechansim
  }
  if req.mechanism == "PLAIN" then
    req.username = msg[7];   -- PLAIN user name
    req.password = msg[8];   -- PLAIN password, in clear text
  elseif req.mechanism == "CURVE" then
    req.client_key = msg[7]; -- CURVE client public key
  end
  return req
end

local function send_zap(sok, req, status, text, user, meta)
  return sok:sendx(req.version, req.sequence, status, text, user or "", meta or "")
end

local loop = zloop.new()

-- Setup auth handler
-- http://rfc.zeromq.org/spec:27
zmq.assert(loop:add_new_bind(zmq.REP, "inproc://zeromq.zap.01", function(sok)
  local req = zmq.assert(recv_zap(sok))
  print("Accept :", req.address)
  -- accept all connections
  zmq.assert(send_zap(sok, req, "200", "welcome")) 
end))

-- This is server
local server = zmq.assert(loop:create_socket(zmq.REP,{
  zap_domain = "global";
  bind       = "tcp://*:9000";
}))
loop:add_socket(server, function(sok)
  print("SERVER: ", (zmq.assert(sok:recv())))
  sok:send(", world!")
end)

-- This is client `process`
loop:add_once(0, function()
  -- try connect to server
  local client = zmq.assert(loop:create_socket(zmq.REQ, {
    connect = "tcp://127.0.0.1:9000"
  }))
  loop:add_socket(client, zmq.POLLOUT + zmq.POLLIN, function(sok, ev)
    if ev == zmq.POLLOUT then sok:send("Hello")
    else 
      print("CLIENT: ", (zmq.assert(sok:recv())))
      loop:interrupt()
    end
  end)
end)

loop:add_once(1000, function()
  loop:interrupt()
end)

loop:start()

