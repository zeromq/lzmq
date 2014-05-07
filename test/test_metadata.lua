local function zap_handler(pipe)

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

  local function mpair(k, v)
    -- mpair support values shorter than 255
    return string.char(#k) .. k .. "\000\000\000" .. string.char(#v) .. v
  end

  local function zmeta(t)
    if not t then return "" end
    if type(t) == "string" then return t end
    local s = ""
    for k, v in pairs(t) do s = s .. mpair(k,v) end
    return s
  end

  local function send_zap(sok, req, status, text, user, meta)
    return sok:sendx(req.version, req.sequence, status, text, user or "", zmeta(meta))
  end

  --===========================================================================

  local zmq = require "lzmq"

  local ctx = pipe:context()
  local handler, err = ctx:socket{zmq.REP,
    bind = "inproc://zeromq.zap.01",
    linger = 0,
  }
  zmq.assert(handler, err)

  pipe:send("start")

  local metadata = {
    Hello = "World";
    World = "Hello";
  }

  print("Start ZAP handler")

  -- Process ZAP requests forever
  while true do
    local req, err = recv_zap(handler)

    if not req then break end --Terminating

    assert (req.version   == "1.0" )
    assert (req.mechanism == "NULL")

    if req.domain == "DOMAIN" then
      send_zap(handler, req,
        "200", "OK",
        "anonymous", metadata
      )
    else
      send_zap(handler, req.version,
        "400", "BAD DOMAIN",
        "", ""
      )
    end
  end

  print("Stop ZAP handler")
end

local ctx, zap_thread

local function main()

  local zmq      = require "lzmq"
  local zthreads = require "lzmq.threads"
  local zassert  = zmq.assert

  local msg = zmq.msg_init()
  if not msg.gets then
    print("This version does not support zmq_msg_gets version!")
    return
  end

  ctx = zassert(zmq.context())

  local pipe
  zap_thread, pipe = zthreads.fork(ctx, string.dump(zap_handler))
  assert(zap_thread, pipe)
  pipe:set_rcvtimeo(500)
  assert(zap_thread:start())
  assert(pipe:recv() == "start")

  local server, err = ctx:socket{zmq.DEALER,
    zap_domain = "DOMAIN",
    bind  = "tcp://127.0.0.1:9001",
  }
  zassert (server, err)

  local client, err = ctx:socket{zmq.DEALER,
    connect = "tcp://127.0.0.1:9001",
  }
  zassert (client, err)

  client:send("This is a message")

  local msg = zassert(server:recv_new_msg())
  assert(msg:gets("Hello")       == "World")
  assert(msg:gets("World")       == "Hello")
  assert(msg:gets("Socket-Type") == "DEALER")
  assert(msg:gets("User-Id")     == "anonymous")
  msg:close()
end

local ok, err = pcall(main)

if ctx then ctx:shutdown() end
if zap_thread then zap_thread:join() end
if ctx then ctx:destroy() end

if not ok then
  print("Fail:", err)
  os.exit(-1)
end

print("Done!")
