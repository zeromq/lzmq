local TEST_FFI = ("ffi" == os.getenv("LZMQ"))
local LZMQ     = "lzmq" .. (TEST_FFI and ".ffi" or "")

local zthreads = require (LZMQ .. ".threads" )

local thread_code = function(...)
  local function assert_equal(name, a, b, ...)
    if a == b then return b, ... end
    print(name .. " Fail! Expected `" .. tostring(a) .. "` got `" .. tostring(b) .. "`")
    os.exit(1)
  end

  local a,b,c,pipe,d,e,f = ...
  assert_equal("1:", 1       , a )
  assert_equal("2:", nil     , b )
  assert_equal("3:", 'hello' , c )
  assert(pipe)
  assert_equal("4:", nil     , d )
  assert_equal("5:", 2       , e )
  assert_equal("6:", nil     , f )
  assert_equal("#:", 7       , select("#", ...))
end

local ctx = zthreads.context()

-- pass `prelude` function that change thread arguments
-- use tcp for thread socket
local thread_opts = {
  thread_code,
  prelude = function(...)
     -- a, b, c
     return 1, nil, 'hello', ...
  end,
  pipe = "tcp://127.0.0.1:*",
}

local thread, skt, endpoint = zthreads.fork(ctx, thread_opts, nil, 2, nil)

local a = {}
for k in string.gmatch(endpoint, "([.%w]+)") do
    table.insert(a, k)
end
assert(a[1] == "tcp")
assert(a[2] == "127.0.0.1")
assert(type(tonumber(a[3])) == "number") -- check the port

assert(thread)
assert(skt)

assert(thread:start())
assert(thread:join())

print("done!")
