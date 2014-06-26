local TEST_FFI = ("ffi" == os.getenv("LZMQ"))
local LZMQ     = "lzmq" .. (TEST_FFI and ".ffi" or "")

local zmq      = require (LZMQ)
local zthreads = require (LZMQ .. ".threads" )

local ctx = zmq:context()
local skt = ctx:socket(zmq.REP)
zmq.assert(skt:bind("inproc://test.inproc"))

local thread = zthreads.run(ctx, function(LZMQ)
  local zmq      = require (LZMQ)
  local zthreads = require (LZMQ .. ".threads" )

  local ctx = zthreads.get_parent_ctx()
  local skt = ctx:socket(zmq.REQ)
  zmq.assert(skt:connect("inproc://test.inproc"))
  skt:send("hello")
  print("thread:", (skt:recv()))
  skt:close()
  ctx:term()
end, LZMQ)

thread:start()

assert(true == thread:detached())
assert(true == thread:joinable())

print("  main:", (skt:recv()))
skt:send("world")
thread:join()
skt:close()
ctx:term()
print("done!")