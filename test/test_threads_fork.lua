local TEST_FFI = ("ffi" == os.getenv("LZMQ"))
local LZMQ     = "lzmq" .. (TEST_FFI and ".ffi" or "")

local zmq      = require (LZMQ)
local zthreads = require (LZMQ .. ".threads" )

local ctx = zmq:context()

local thread, skt = zthreads.fork(ctx, [[ 
  local skt = arg[1]
  skt:send("hello")
  print("thread:", (skt:recv()))
]])

thread:start()

print("  main:", (skt:recv()))
skt:send("world")
thread:join()
print("done!")