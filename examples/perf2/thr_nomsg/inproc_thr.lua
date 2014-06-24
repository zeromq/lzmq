local ZMQ_NAME = "lzmq"

math.randomseed(os.time())

local argc = select("#", ...)
local argv = {...}

if (argc < 2) or (argc > 3)then
  print("usage: inproc_thr <message-size> <message-count> [ffi]")
  return 1
end

local message_size  = assert(tonumber(argv [1]))
local message_count = assert(tonumber(argv [2]))
if argv [3] then
  assert(argv [3] == 'ffi')
  ZMQ_NAME = "lzmq.ffi"
end
local addr = "inproc://inproc." .. math.random(10000) .. "-" .. math.random(10000) .. ".thr"

local zmq      = require(ZMQ_NAME)
local ztimer   = require(ZMQ_NAME .. ".timer")
local zthreads = require(ZMQ_NAME .. ".threads")

local local_thr = zthreads.xrun("@./local_thr.lua", addr, message_size, message_count, argv[3])
local_thr:start(true, true)

ztimer.sleep(1000)

local remote_thr = zthreads.xrun("@./remote_thr.lua", addr, message_size, message_count, argv[3])
remote_thr:start(true, true)

remote_thr:join()
local_thr:join()