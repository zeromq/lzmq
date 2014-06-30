local TEST_FFI = ("ffi" == os.getenv("LZMQ"))
local LZMQ     = "lzmq" .. (TEST_FFI and ".ffi" or "")

local zmq      = require (LZMQ)
local zthreads = require (LZMQ .. ".threads" )
local poller   = require (LZMQ .. ".poller").new(1)

local actor = zthreads.xactor(function(pipe)
  pipe:send("hello")
  print("thread:", (pipe:recv()))
end):start()

local flag = false

poller:add(actor, zmq.POLLIN, function(a)
  assert(a == actor)
  flag = true
end)

assert(poller:poll(1000))

assert(flag)

print("  main:", (actor:recv()))
actor:send("world")

actor:join()
print("done!")
