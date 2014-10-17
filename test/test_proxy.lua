pcall(require, "luacov")

local function zversion(zmq)
  local version = zmq.version()
  return string.format("%d.%d.%d", version[1], version[2], version[3])
end

local function iszvereq(zmq, mi, ma, bu)
  local version = zmq.version()
  return (mi == version[1]) and (ma == version[2]) and (bu == version[3])
end

-- >=
local is_zmq_ge = function (zmq, major, minor, patch)
  local ZMQ_VERSION_MAJOR, ZMQ_VERSION_MINOR, ZMQ_VERSION_PATCH = zmq.version(true)

  if ZMQ_VERSION_MAJOR < major then return false end
  if ZMQ_VERSION_MAJOR > major then return true  end
  if ZMQ_VERSION_MINOR < minor then return false end
  if ZMQ_VERSION_MINOR > minor then return true  end
  if ZMQ_VERSION_PATCH < patch then return false  end
  return true
end

-- ==
local is_zmq_eq = function (zmq, major, minor, patch)
  local ZMQ_VERSION_MAJOR, ZMQ_VERSION_MINOR, ZMQ_VERSION_PATCH = zmq.version(true)

  return ZMQ_VERSION_MAJOR == major
     and ZMQ_VERSION_MINOR == minor
     and ZMQ_VERSION_PATCH == patch
end

-- <=
local is_zmq_le = function (zmq, major, minor, patch)
  return is_zmq_eq(zmq, major, minor, patch)
    or not is_zmq_ge(zmq, major, minor, patch)
end

local HAS_RUNNER = not not lunit 

local lunit      = require "lunit"
local TEST_CASE  = assert(lunit.TEST_CASE)
local skip       = lunit.skip or function() end
local SKIP       = function(msg) return function() return skip(msg) end end

local IS_LUA52 = _VERSION >= 'Lua 5.2'
local TEST_FFI = ("ffi" == os.getenv("LZMQ"))

local LZMQ = "lzmq" .. (TEST_FFI and ".ffi" or "")

local zmq      = require (LZMQ)
local zthreads = require (LZMQ .. ".threads" )
local ztimer   = require (LZMQ .. ".timer" )

local function wait(ms)
  ztimer.sleep(ms or 100)
end

local include_thread  = [[
  local LZMQ     = ]] .. ("%q"):format(LZMQ) .. [[
  local zmq      = require (LZMQ)
  local zthreads = require (LZMQ .. ".threads" )
  local ctx      = zthreads.get_parent_ctx()

  local function assert(name, ...)
    if ... then return ... end
    local err = tostring((select('2', ...)))

    print(name .. " Fail! Error: `" .. err .. "`")
    os.exit(1)
  end

  local function assert_equal(name, a, b, ...)
    if a == b then return b, ... end
    print(name .. " Fail! Expected `" .. tostring(a) .. "` got `" .. tostring(b) .. "`")
    os.exit(1)
  end
]]

local _ENV = TEST_CASE'proxy' if true then
if not zmq.proxy then test = SKIP"zmq_proxy does not support" else

local cli_endpoint = "inproc://client"
local srv_endpoint = "inproc://server"
local ctx, thread, pipe

function setup()
  ctx = zmq:context()
end

function teardown()
  ctx:destroy(0)  -- close context
  if thread then thread:join() end -- close thread
end

function test_capture()
  thread, pipe = zthreads.fork(ctx, include_thread .. [[
    local pipe, cli_endpoint, srv_endpoint = ...

    local fe = assert('ROUTER:', ctx:socket{zmq.ROUTER, connect = cli_endpoint})
    local be = assert('DEALER:', ctx:socket{zmq.DEALER, connect = srv_endpoint})

    local ok, err = zmq.proxy(fe, be, pipe)

    ctx:destroy(0)
  --]], cli_endpoint, srv_endpoint)

  assert(thread, pipe)

  local cli = assert(ctx:socket{zmq.REQ, bind = cli_endpoint, rcvtimeo=1000})
  local srv = assert(ctx:socket{zmq.REP, bind = srv_endpoint, rcvtimeo=1000})

  assert_equal(thread, thread:start())

  assert(cli:send("hello"))

  local msg = assert_table(pipe:recv_all())
  assert_equal(3, #msg) -- id, empty, message
  assert_equal('', msg[2])
  assert_equal('hello',  msg[3])

  assert_equal('hello', srv:recv())

  ----------------------------
  assert(srv:send("world"))

  local msg = assert_table(pipe:recv_all())
  assert_equal(3, #msg) -- id, empty, message
  assert_equal('', msg[2])
  assert_equal('world',  msg[3])

  assert_equal('world', cli:recv())

end

function test_basic()
  thread, pipe = zthreads.run(ctx, include_thread .. [[
    local cli_endpoint, srv_endpoint = ...

    local fe = assert('ROUTER:', ctx:socket{zmq.ROUTER, connect = cli_endpoint})
    local be = assert('DEALER:', ctx:socket{zmq.DEALER, connect = srv_endpoint})

    local ok, err = zmq.proxy(fe, be)

    ctx:destroy(0)
  --]], cli_endpoint, srv_endpoint)

  local cli = assert(ctx:socket{zmq.REQ, bind = cli_endpoint, rcvtimeo=1000})
  local srv = assert(ctx:socket{zmq.REP, bind = srv_endpoint, rcvtimeo=1000})

  thread:start()

  assert(cli:send("hello"))
  assert_equal('hello', srv:recv())

  ----------------------------
  assert(srv:send("world"))
  assert_equal('world', cli:recv())

end

end
end

local _ENV = TEST_CASE'proxy_steerable' if true then
if not zmq.proxy_steerable then test = SKIP"zmq_proxy_steerable does not support"
elseif is_zmq_le(zmq, 4,0,6) then test = SKIP"ZeroMQ 4.0.6 invalid implementation"
else

local cli_endpoint = "inproc://client"
local srv_endpoint = "inproc://server"
local ctx, thread, pipe

function setup()
  ctx = zmq:context()
end

function teardown()
  ctx:destroy(0)  -- close context
  if thread then thread:join() end -- close thread
end

function test_control()
  thread, pipe = zthreads.fork(ctx, include_thread .. [[
    local pipe, cli_endpoint, srv_endpoint = ...

    local fe = assert('ROUTER:', ctx:socket{zmq.ROUTER, connect = cli_endpoint})
    local be = assert('DEALER:', ctx:socket{zmq.DEALER, connect = srv_endpoint})

    local ok, err = zmq.proxy_steerable(fe, be, nil, pipe)

    pipe:send("DONE")

    ctx:destroy(100)
  --]], cli_endpoint, srv_endpoint)

  local cli = assert(ctx:socket{zmq.REQ, bind = cli_endpoint, rcvtimeo=1000})
  local srv = assert(ctx:socket{zmq.REP, bind = srv_endpoint, rcvtimeo=1000})
  pipe:set_rcvtimeo(1000)

  thread:start()

  pipe:send("PAUSE")
  assert(cli:send("hello"))

  local _, err = assert_nil(srv:recv())
  assert_equal('EAGAIN', err:mnemo())

  pipe:send("RESUME")
  assert_equal("hello", srv:recv())

  pipe:send("TERMINATE")
  assert_equal("DONE", pipe:recv())

  assert(thread:join())
end

function test_basic()
  thread, pipe = zthreads.run(ctx, include_thread .. [[
    local cli_endpoint, srv_endpoint = ...

    local fe = assert('ROUTER:', ctx:socket{zmq.ROUTER, connect = cli_endpoint})
    local be = assert('DEALER:', ctx:socket{zmq.DEALER, connect = srv_endpoint})

    local ok, err = zmq.proxy_steerable(fe, be)

    ctx:destroy(0)
  --]], cli_endpoint, srv_endpoint)

  local cli = assert(ctx:socket{zmq.REQ, bind = cli_endpoint, rcvtimeo=1000})
  local srv = assert(ctx:socket{zmq.REP, bind = srv_endpoint, rcvtimeo=1000})

  thread:start()

  assert(cli:send("hello"))
  assert_equal('hello', srv:recv())

  ----------------------------
  assert(srv:send("world"))
  assert_equal('world', cli:recv())

end

end
end

if not HAS_RUNNER then lunit.run() end