local TEST_FFI = ("ffi" == os.getenv("LZMQ"))
local LZMQ     = "lzmq" .. (TEST_FFI and ".ffi" or "")

local zmq      = require (LZMQ)
local zthreads = require (LZMQ .. ".threads" )

local ctx = zmq:context()

local thread, skt = zthreads.fork(ctx, string.dump(function(skt)
  local ztimer = require "lzmq.timer"

  local function assert_equal(name, a, b, ...)
    if a == b then return b, ... end
    print(name .. " Fail! Expected `" .. tostring(a) .. "` got `" .. tostring(b) .. "`")
    os.exit(1)
  end

  local function assert_not_nil(name, a, ...)
    if a ~= nil then return a, ... end
    print(name .. " Fail! Expected not nil value but got it.")
    os.exit(1)
  end

  skt:send("")
  while true do
    local msg, err = skt:recv()
    if not msg then 
      assert_not_nil("Error", err)
      assert_equal("Error", "ETERM", err:mnemo())
      break
    end
  end

  -- wait to ensure 
  ztimer.sleep(5000)

  print("Done!")
  os.exit(0)
end))

thread:start()

skt:recv()

-- we should wait until socket in thread not closed
ctx:destroy()

print('Sync does not work.')

os.exit(2)
