local TEST_FFI = ("ffi" == os.getenv("LZMQ"))
local LZMQ     = "lzmq" .. (TEST_FFI and ".ffi" or "")

local zmq      = require (LZMQ)
local zthreads = require (LZMQ .. ".threads" )

local thread = zthreads.fork(zmq.context(), [[
  local function assert_equal(name, a, b, ...)
    if a == b then return b, ... end
    print(name .. " Fail! Expected `" .. tostring(a) .. "` got `" .. tostring(b) .. "`")
    os.exit(1)
  end
  local function assert_function(name, a, ...)
    if type(a) == 'function' then return ... end
    print(name .. " Fail! Function expected got `" .. tostring(a) .. "`")
    os.exit(1)
  end

  local pipe, a,b,c,d,e,f = ...
  assert_function("1:", pipe.send)
  assert_equal("2:", 1       , a )
  assert_equal("3:", nil     , b )
  assert_equal("4:", 'hello' , c )
  assert_equal("5:", nil     , d )
  assert_equal("6:", 2       , e )
  assert_equal("7:", nil     , f )
  assert_equal("#:", 7       , select("#", ...))
  
]], 1, nil, 'hello', nil, 2, nil)

thread:start()

thread:join()

print("done!")