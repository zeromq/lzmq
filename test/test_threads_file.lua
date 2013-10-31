local TEST_FFI = ("ffi" == os.getenv("LZMQ"))
local LZMQ     = "lzmq" .. (TEST_FFI and ".ffi" or "")

local zmq      = require (LZMQ)
local zthreads = require (LZMQ .. ".threads" )

local ctx = zmq:context()
local thread = zthreads.run(ctx, "@thread.lua")
thread:start()
thread:join()

local thread = zthreads.fork(ctx, "@thread.lua")
thread:start()
thread:join()

ctx:term()
print("done!")