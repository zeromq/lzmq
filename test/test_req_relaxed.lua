---
-- Test ZMQ_REQ_RELAXED mode and reconnect socket
-- This test requires [lua-llthreads2](https://github.com/moteus/lua-llthreads2) library


local zmq      = require "lzmq"
local ztimer   = require "lzmq.timer"
local zthreads = require "lzmq.threads"
local zassert  = zmq.assert

local ENDPOINT = "tcp://127.0.0.1:5555"
local CLIENT_SOCKET_TYPE = zmq.REQ

-----------------------------------------------------------------------------
-- START  - start server thread
-- FINISH - stop server thread and wait until it stopped
-- ECHO   - send echo msg to server, wait and check response 
local START, FINISH, ECHO, RECONNECT, WAIT do

local proc

local ctx  = zmq.context()

local pipe 

if CLIENT_SOCKET_TYPE == zmq.REQ then
  pipe = zassert(ctx:socket{zmq.REQ,
    sndtimeo = 1000, rcvtimeo = 1000, linger = 0,
    req_relaxed = 1, req_correlate = 1, 
    connect = ENDPOINT,
  })
else
  assert(zmq.DEALER == CLIENT_SOCKET_TYPE)
  pipe = zassert(ctx:socket{zmq.DEALER,
    sndtimeo = 1000, rcvtimeo = 1000, linger = 0,
    connect = ENDPOINT,
  })
end

local SERVER = string.dump(function(ENDPOINT)
  local zmq      = require "lzmq"
  local ztimer   = require "lzmq.timer"
  local zthreads = require "lzmq.threads"
  local zassert  = zmq.assert

  local ctx = zthreads.get_parent_ctx() or zmq.context()
  local srv = zassert(ctx:socket{zmq.ROUTER, bind = ENDPOINT})

  print("== SERVER START: ")

  local msg, err
  while true do
    msg, err = srv:recv_all()
    if not msg then
      print('== SERVER RECV: ' .. tostring(err))
      if err:mnemo() ~= 'EAGAIN' then
        break
      end
    else
      print('== SERVER RECV: ' .. msg[#msg])
      local ok, err = srv:send_all(msg)
      print('== SERVER SEND: ' .. (ok and msg[#msg] or tostring(err)))
      if msg[#msg] == 'FINISH' then break end
    end
  end

  print("== SERVER FINISH: ")
end)

function START()
  local thread = assert(zthreads.run(ctx, SERVER, ENDPOINT)):start(true, true)
  ztimer.sleep(1000)
  local ok, err = thread:join(0)
  assert(err == 'timeout')
  proc = thread
end

function FINISH()
  zassert(pipe:send('FINISH'))
  zassert(pipe:recvx())
  for i = 1, 100 do
    local ok, err = proc:join(0)
    if ok then return end
    ztimer.sleep(500)
  end
  assert(false)
end

local echo_no = 0
local function ECHO_()
  echo_no = echo_no + 1
  local msg = "hello:" .. echo_no
  local ok, err = pipe:send(msg)
  print("== CLIENT SEND:", (ok and msg or tostring(err)))
  if not ok then return end

  while true do
    ok, err = pipe:recvx()
    print("== CLIENT RECV:", ok or err)
    if zmq.REQ == CLIENT_SOCKET_TYPE then
      if ok then assert(ok == msg) end
      break
    end
    if ok then 
      if(ok == msg) then break end
    else
      break
    end
  end
end

function ECHO(N)
  for i = 1, (N or 1) do ECHO_() end
end

function RECONNECT()
  pipe:disconnect(ENDPOINT)
  zassert(pipe:connect(ENDPOINT))
  print("== CLIENT RECONNECT")
end

function WAIT(n)
  ztimer.sleep(n or 100)
end

end
-----------------------------------------------------------------------------

print("==== ZeroMQ version " .. table.concat(zmq.version(), '.') .. " ===")

START()

ECHO(2)

FINISH()

ECHO(2)

START()

ECHO(2)

-- With reconnect test pass
-- RECONNECT()

ECHO(2)

FINISH()
