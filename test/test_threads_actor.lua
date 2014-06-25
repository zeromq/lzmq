local TEST_FFI = ("ffi" == os.getenv("LZMQ"))
local LZMQ     = "lzmq" .. (TEST_FFI and ".ffi" or "")

local zthreads = require (LZMQ .. ".threads" )

local actor = zthreads.xactor(function(pipe)
  pipe:send("hello")
  print("thread:", (pipe:recv()))
end):start()

print("  main:", (actor:recv()))
actor:send("world")

actor:join()
print("done!")
