local ZMQ_NAME = "lzmq"

math.randomseed(os.time())

local argc = select("#", ...)
local argv = {...}

if (argc < 2) or (argc > 3)then
  print("usage: inproc_lat <message-size> <roundtrip-count> [ffi]")
  return 1
end

local message_size  = assert(tonumber(argv [1]))
local message_count = assert(tonumber(argv [2]))
if argv [3] then
  assert(argv [3] == 'ffi')
  ZMQ_NAME = "lzmq.ffi"
end
local addr = "inproc://inproc." .. math.random(10000) .. "-" .. math.random(10000) .. ".lat"

local zmq      = require(ZMQ_NAME)
local ztimer   = require(ZMQ_NAME .. ".timer")
local zthreads = require(ZMQ_NAME .. ".threads")

local local_lat = zthreads.xrun("@./local_lat.lua", addr, message_size, message_count, argv[3])
local_lat:start()

ztimer.sleep(1000)

local remote_lat = zthreads.xrun("@./remote_lat.lua", addr, message_size, message_count, argv[3])
remote_lat:start()

remote_lat:join()
local_lat:join()