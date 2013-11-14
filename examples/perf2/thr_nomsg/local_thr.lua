local ZMQ_NAME = "lzmq"

local argc = select("#", ...)
local argv = {...}

if (argc < 3) or (argc > 4)then
  print("usage: local_thr <bind-to> <message-size> <message-count> [ffi]");
  return 1
end

local bind_to       = argv [1]
local message_size  = assert(tonumber(argv [2]))
local message_count = assert(tonumber(argv [3]))
if argv [4] then
  assert(argv [4] == 'ffi')
  ZMQ_NAME = "lzmq.ffi"
end

local zmq      = require(ZMQ_NAME)
local ztimer   = require(ZMQ_NAME .. ".timer")
local zthreads = require(ZMQ_NAME .. ".threads")
local zassert  = zmq.assert

local ctx = zthreads.get_parent_ctx() or zassert(zmq.context())
local s = zassert(ctx:socket{zmq.PULL,
  -- Add your socket options here.
  -- For example ZMQ_RATE, ZMQ_RECOVERY_IVL and ZMQ_MCAST_LOOP for PGM.
  rcvhwm = message_count + 1;
  bind   = bind_to;
})

local msg = zassert(s:recv())

if #msg ~= message_size then
  print("message of incorrect size received");
  return -1;
end

-- local watch, per_sec = ztimer.monotonic():start(), 1000
local watch, per_sec = zmq.utils.stopwatch():start(), 1000000

for i = 1, message_count - 1 do
  msg = zassert(s:recv())
  if #msg ~= message_size then
    print("message of incorrect size received");
    return -1;
  end
end

local elapsed = watch:stop() / per_sec
if elapsed == 0 then elapsed = 1 end

local throughput = message_count / elapsed
local megabits   = (throughput * message_size * 8) / 1000000

print(string.format("message size: %d [B]",         message_size))
print(string.format("message count: %d",            message_count))
print(string.format("mean throughput: %d [msg/s]",  throughput))
print(string.format("mean throughput: %.3f [Mb/s]", megabits))

