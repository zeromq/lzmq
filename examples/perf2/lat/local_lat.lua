local ZMQ_NAME = "lzmq"

local argc = select("#", ...)
local argv = {...}

if (argc < 3) or (argc > 4)then
  print("usage: local_lat <bind-to> <message-size> <roundtrip-count> [ffi]")
  return 1
end

local bind_to         = argv [1]
local message_size    = assert(tonumber(argv [2]))
local roundtrip_count = assert(tonumber(argv [3]))
if argv [4] then
  assert(argv [4] == 'ffi')
  ZMQ_NAME = "lzmq.ffi"
end

local zmq      = require(ZMQ_NAME)
local ztimer   = require(ZMQ_NAME .. ".timer")
local zthreads = require(ZMQ_NAME .. ".threads")
local zassert  = zmq.assert

local ctx = zthreads.context()

local s = zassert(ctx:socket{zmq.REP,
  bind = bind_to;
})

local msg = zassert(zmq.msg_init())

for i = 1, roundtrip_count do
  zassert(msg:recv(s))
  if msg:size() ~= message_size then
    print("message of incorrect size received");
    return -1;
  end
  zassert(msg:send(s))
end

ztimer.sleep(1000)
