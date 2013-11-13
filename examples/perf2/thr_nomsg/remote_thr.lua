local ZMQ_NAME = "lzmq"

local argc = select("#", ...)
local argv = {...}

if (argc < 3) or (argc > 4)then
  print("usage: remote_thr <connect-to> <message-size> <message-count> [ffi]");
  return 1
end

local connect_to    = argv [1]
local message_size  = assert(tonumber(argv [2]))
local message_count = assert(tonumber(argv [3]))
if argv [4] then
  assert(argv [4] == 'ffi')
  ZMQ_NAME = "lzmq.ffi"
end

local zmq      = require(ZMQ_NAME)
local zthreads = require(ZMQ_NAME .. ".threads")
local zassert  = zmq.assert

local ctx = zthreads.get_parent_ctx() or zassert(zmq.context())
local s = zassert(ctx:socket{zmq.PUSH,
  -- Add your socket options here.
  -- For example ZMQ_RATE, ZMQ_RECOVERY_IVL and ZMQ_MCAST_LOOP for PGM.
  sndhwm  = message_count + 1;
  connect = connect_to;
})

local msg = ("0"):rep(message_size)

for i = 1, message_count do
  zassert(s:send(msg))
end
