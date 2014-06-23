local TEST_FFI = ("ffi" == os.getenv("LZMQ"))
local LZMQ     = "lzmq" .. (TEST_FFI and ".ffi" or "")

local zmq      = require (LZMQ)
local zthreads = require (LZMQ .. ".threads" )

local ctx = zmq:context()

local actor = zthreads.fork(ctx, function(pipe)
  pipe:send("hello")
  print("thread:", (pipe:recv()))
end)

local v = actor:start(true, true)
assert(v == actor)

print("  main:", (actor:recv()))
actor:send("world")

actor:join()
print("done!")
