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

local ctx = zthreads.context()
local s = zassert(ctx:socket{zmq.PUSH,
  -- Add your socket options here.
  -- For example ZMQ_RATE, ZMQ_RECOVERY_IVL and ZMQ_MCAST_LOOP for PGM.
  sndhwm  = message_count + 1;
  connect = connect_to;
})

local function version_1()
  -- here we create two messages.
  -- but zmq_msg_copy does not reallocate 
  -- buffer but just copy reference and increment
  -- couter. So this version is much faseter then
  -- original version.

  local msg = zassert(zmq.msg_init_data(
    ("0"):rep(message_size)
  ))

  local smsg = zassert(zmq.msg_init())

  for i = 1, message_count do
    smsg:copy(msg)
    zassert(smsg:send(s))
  end
end

local function version_2()
  -- here we create one messages.
  -- msg:set_size create internal new zmq_msg_t
  -- each time but does not init memory.
  -- This is what do original version.
  -- The main impact for ffi version is callind 
  -- ffi.gc each time we create new zmq_msg_t struct

  local msg = zmq.msg_init_size(message_size)
  for i = 1, message_count do
    zassert(msg:send(s))
    msg:set_size(message_size)
  end
end

local function version_3()
  -- this is same as version_2 but we also copy data
  -- to message

  local data = ("o"):rep(message_size)
  local msg = zmq.msg_init_data(data)
  for i = 1, message_count do
    zassert(msg:send(s))
    msg:set_data(data)
  end
end

version_2()
