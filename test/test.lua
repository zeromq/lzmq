local zmq    = require "lzmq"
local zloop  = require "lzmq.loop" 
local ztimer = require "lzmq.timer"
local assert = zmq.assert

require "utils"

print(_VERSION)
print_version(zmq)

ECHO_ADDR = "inproc://echo"
ECHO_ADDR = "tcp://127.0.0.1:5555"

function Test_Assert()
  print("\n\nTest_Assert ...")
  local ok1, msg1 = pcall(zmq.assert, false, zmq.error(zmq.errors.EINVAL));    -- object
  local ok2, msg2 = pcall(zmq.assert, false, zmq.errors.EINVAL);               -- number
  local ok3, msg3 = pcall(zmq.assert, false, zmq.strerror(zmq.errors.EINVAL)); -- string
  assert(not ok1)
  assert(not ok2)
  assert(not ok3)
  assert(msg1 == msg2)
  assert(msg1 == msg3)
  print("Test_Assert done!")
end

function Test_Message()
  print("\n\nTest_Message ...")

  local msg1 = assert(zmq.msg_init())
  local msg2 = assert(zmq.msg_init_size(255))
  local msg3 = assert(zmq.msg_init_data("Hello world!"))
  assert(not msg1:closed())
  assert(not msg2:closed())
  assert(not msg3:closed())
  assert(msg1:close())
  assert(msg1:closed())
  assert(msg1:close())
  assert(not pcall(msg1.data, msg1)) -- no AV
  assert(msg2:close())
  assert(msg3:close())

  msg1 = assert(zmq.msg_init_size(10))
  assert(msg1:size() == 10)
  assert(msg1:set_data("Hello"))
  assert(msg1:size() == 10)
  local data = assert(msg1:data())
  assert(#data == 10)
  assert(data:sub(1, 5) == 'Hello')

  assert(msg1:set_data(6, ", world!")) -- append and resize buffer
  assert(msg1:size() == 13)
  local data = assert(msg1:data())
  assert(#data == 13)
  assert(data == "Hello, world!")
  
  msg2 = assert(zmq.msg_init())
  assert(msg2 == msg2:move(msg1))

  assert(msg1:size() == 0)
  assert(not msg1:closed())
  assert(msg1:set_data("hi"))
  assert(msg1:size() == 2)
  assert(msg1:data() == "hi")
  assert(msg1:close())


  assert(msg2:size() == #data)
  assert(msg2:data() == data)

  msg3 = assert(zmq.msg_init())
  assert(msg3 == msg3:copy(msg2))

  assert(msg2:size() == #data)
  assert(msg2:data() == data)
  assert(msg3:size() == #data)
  assert(msg3:data() == data)

  assert(msg2:close())
  assert(msg3:close())
  
  msg1 = assert(zmq.msg_init_data("hello world"))
  msg2 = assert(msg1:copy())
  assert(msg1:data() == msg2:data())
  msg3 = assert(msg1:move())
  assert(msg3:data() == msg2:data())
  assert(msg1:data() == "")

  assert(not pcall(msg2.copy, msg, nil))
  assert(not pcall(msg3.move, msg, nil))

  assert(msg1:close())
  assert(msg2:close())
  assert(msg3:close())

  print("Test_Message done!")
end

function Test_Context()
  print("\n\nTest_Context ...")
  local ctx = zmq.context()
  assert(ctx:set_io_threads(2))
  assert(ctx:get_io_threads() == 2)
  assert(ctx:set_max_sockets(252))
  assert(ctx:get_max_sockets() == 252)

  local ctx2 = assert(zmq.init_ctx( assert(ctx:lightuserdata()) ))
  assert(ctx:lightuserdata()   == ctx2:lightuserdata()  )
  assert(ctx:get_io_threads()  == ctx2:get_io_threads()  )
  assert(ctx:get_max_sockets() == ctx2:get_max_sockets() )
  assert(not ctx2:closed())
  assert(ctx2:destroy())
  assert(ctx2:closed())
  assert(not pcall(ctx2.get_io_threads, ctx2))
  assert(ctx:get_io_threads() == 2)

  assert(not ctx:closed())
  assert(ctx:destroy())
  assert(ctx:closed())
  print("Test_Context done!")
end

function Test_Sockopt()
  print("\n\nTest_Sockopt ...")
  
  local ctx = zmq.context()
  assert(ctx:set_io_threads(2))
  local skt = ctx:socket(zmq.SUB)
  assert(skt:set_subscribe("sub 1"))
  assert(skt:set_subscribe("sub 2"))
  assert(skt:set_subscribe{"sub 3"; "sub 3"})

  assert(skt:set_unsubscribe{"sub 1", "sub 2"})
  local ok, err, no = skt:set_unsubscribe{"sub 3", "sub 1"}
  if not ok then assert(no == 2) end

  assert(skt:set_unsubscribe("sub 3"))

  skt:close()
  assert(ctx:destroy())

  print("Test_Sockopt done!")
end

function Test_SockAutoclose()
  local function weak_ptr(val)
    return setmetatable({value = val},{__mode = 'v'})
  end

  local function gc_collect()
    collectgarbage("collect")
    collectgarbage("collect")
  end

  print("\n\nTest_SockAutoclose ...")

  local ctx = zmq.context()
  local skt = ctx:socket(zmq.SUB)
  ctx:autoclose(skt)
  assert(ctx:destroy())

  local ctx = zmq.context()
  do local skt = ctx:socket(zmq.SUB) end
  gc_collect()
  assert(ctx:destroy())

  local ctx = zmq.context()
  local ptr
  do
    local skt = ctx:socket(zmq.SUB)
    ctx:autoclose(skt)
    ptr = weak_ptr(skt)
  end
  gc_collect()
  assert(ptr.value == nil)
  assert(ctx:destroy())

  print("Test_SockAutoclose done!")
end

function Test_Bind_Connect()
  print("\n\nTest_Bind_Connect ...")

  local ctx = zmq.context()
  local pub = ctx:socket(zmq.PUB)
  local ok, err, str = pub:bind{
    ECHO_ADDR;
    "inproc://pub.test.1";
    "inproc://pub.test.2";
    "error address";
    "inproc://pub.test.3";
  }
  assert(not ok)
  assert(str == "error address")
  pub:bind("inproc://pub.test.3")
  
  local sub1 = ctx:socket(zmq.SUB)
  local sub2 = ctx:socket(zmq.SUB)
  local sub3 = ctx:socket(zmq.SUB)
  assert(sub1:set_subscribe(""))
  assert(sub2:set_subscribe(""))
  assert(sub3:set_subscribe(""))
  assert(sub1:set_rcvtimeo(100))
  assert(sub2:set_rcvtimeo(100))
  assert(sub3:set_rcvtimeo(100))
  
  assert(sub1:connect("inproc://pub.test.1"))
  assert(sub2:connect("inproc://pub.test.2"))
  assert(sub3:connect("inproc://pub.test.3"))
  ztimer.sleep(1000)
  assert(pub:send("hello"))
  assert( "hello" == 
  assert(sub1:recv()))
  assert( "hello" == 
  assert(sub2:recv()))
  assert( "hello" == 
  assert(sub3:recv()))

  sub2:close()
  sub3:close()


  assert(sub1:connect(ECHO_ADDR))
  ztimer.sleep(1000)

  assert(pub:send("hello"))
  assert( "hello" == 
  assert(sub1:recv()))
  assert( "hello" == 
  assert(sub1:recv()))

  ok, err, str = sub1:disconnect{
    ECHO_ADDR;
    "inproc://pub.test.3";
  }
  assert(not ok)
  assert(str == "inproc://pub.test.3")
  ztimer.sleep(1000)

  assert(pub:send("hello"))
  assert( "hello" == 
  assert(sub1:recv()))
  assert(not sub1:recv())

  sub1:close()
  pub:close()

  assert(ctx:destroy())

  print("Test_Bind_Connect done!")
end

function Test_Error()
  print("\n\nTest_Error ...")

  for k, v in pairs(zmq.errors) do
    assert(zmq.errors[v] == k)
  end

  local zassert = zmq.assert
  local err = zmq.error(zmq.errors.EAGAIN)
  assert(err:no()    == zmq.errors.EAGAIN)
  assert(err:mnemo() == "EAGAIN")
  local str_err = tostring(err)
  local ok, msg = pcall( zassert, false, err )
  assert(not ok)
  assert(string.find(msg, str_err, 1, true))

  local ctx = zmq.context();
  local ok, err = ctx:set(89, 89)
  assert(ok == nil)
  if type(err) == 'string' then
    assert(err:sub(2,7) == 'EINVAL')
  elseif type(err) == 'number' then
    assert(err == zmq.errors.EINVAL)
  else 
    assert(type(err)   == 'userdata')
    assert(err:mnemo() == 'EINVAL')
    assert(err:no()    == zmq.errors.EINVAL)
  end
  ctx:destroy()
  print("Test_Error done!")
end

local function Test_Timer(timer)
  print("\n\nTest_Timer ...")

  local COUNT    = 100
  local INTERVAL = 100
  local DELTA    = 50

  local name = timer:is_absolute() and 'absolute' or 'monotonic';

  local max_delta, totla_delta, totla_delta2 = 0, 0, 0

  if timer:is_absolute() then
    assert( timer == timer:set(ztimer.absolute_time() + INTERVAL) )
  else
    assert( timer == timer:set(INTERVAL) )
  end

  assert(not timer:started())
  assert(not timer:closed())
  assert(not pcall(timer.elapsed, timer))
  assert(not pcall(timer.rest, timer))
  assert(timer == timer:start())

  for i = 1, COUNT do

    timer:start()
    ztimer.sleep(INTERVAL + DELTA)
    local elapsed = timer:elapsed()
    assert(timer:rest() == 0)

    local delta = math.abs(elapsed - (INTERVAL + DELTA))
    if delta > max_delta then max_delta = delta end
    totla_delta = totla_delta + delta
    totla_delta2 = totla_delta2 + (elapsed - (INTERVAL + DELTA))

    assert(timer:start())
    assert(timer:started())
    assert(timer:setted())
    assert(not pcall(timer.start, start))
    assert(timer:stop())
    assert(not pcall(timer.elapsed, timer))
    assert(not pcall(timer.rest,  timer))
  end

  print("timer: ", name)
  print("Max delta    : ", max_delta)
  print("Avg delta    : ", totla_delta2/1000)
  print("Avg abs delta: ", totla_delta/1000)
  print("----------------------------------")

  assert(timer:close())
  assert(timer:closed())
  assert(timer:close())

  print("Test_Timer done!")
end

local zloop  = require "lzmq.loop"

function Test_loop()
  print("\n\nTest_loop ...")
  local loop = zloop.new()
  local flag1,flag2,flag3
  loop:add_once(10, function() flag1 = true end)
  assert(0 == loop:flush(100)) -- flush only io events
  assert(not flag1)
  assert(1 == loop:sleep_ex(100))
  assert(flag1)
  flag1 = false
  loop:add_once(10, function() flag1 = true end)
  loop.sleep(100)
  assert(not flag1)
  assert(1 == loop:sleep_ex(0))
  assert(flag1)
  loop:destroy()
  print("Test_loop done")
end

function Test_Remove_ev()
  print("\n\nTest_Remove_ev ...")

  local c = 0
  local N = 10
  local T = 100
  local flag1,flag2,flag3

  local loop = zloop.new()

  local ext_ev = loop:add_interval(T, function()
    flag3 = false
  end)

  local function fn2(ev, loop) 
    assert(c < N)
    assert(flag1, "event 1 does not stop")

    c = c + 1
    if c == N then
      ev:reset()     -- remove self
      ext_ev:reset() -- remove ext

      assert(flag3 == false, "ext_ev does not work")

      c, flag2, flag3 = 0, true, true

      loop:add_interval(T, function()
        assert(flag1, "event 1 does not stop")
        assert(flag2, "event 1 does not stop")
        assert(flag3, "event 1 does not stop")
        c = c + 1
        if c == N then
          loop:interrupt()
        end
      end)

    end
  end

  local function fn1(ev, loop) 
    assert(c < N)
    flag3 = true --  ext_ev should set to false

    c = c + 1
    if c == N then
      c = 0
      flag1 = true
      ev:reset()
      loop:add_interval(T, fn2)
    end
  end

  loop:add_interval(T, fn1)

  loop:start()

  assert(flag1 and flag2)

  print("Test_Remove_ev done!")
end

local Test_Skel = { name = 'Test_Empty';
  srv = function(skt) end;

  cli_send = function(skt) end;

  cli_recv = function(skt) end;
}

local function TestServer(t)
  assert(t.name and t.srv and t.cli_send and t.cli_recv)

  print("\n\n" .. t.name .. " ...")
  local main_loop = zloop.new()

  assert(main_loop:add_new_bind(zmq.REP, ECHO_ADDR, t.srv))

  local cli = assert(main_loop:add_new_connect(zmq.REQ, ECHO_ADDR, function(skt)
    t.cli_recv(skt)
    main_loop:interrupt()
  end))

  main_loop:add_once(200, function() t.cli_send(cli) end)

  main_loop:add_once(30000, function() assert(false, "FAIL: TIMEOUT!") end)

  main_loop:start()

  main_loop:destroy()
  
  assert(cli:closed())

  main_loop.sleep(500) -- for TCP time to release IP address
  print(t.name .. " done!");
end

Test_Send_Recv      = { name = 'Test_Send_Recv';
  srv = function(skt)
    local msg, more = assert(print_msg("SRV RECV: ",skt:recv()))
    assert(more       == false)
    assert(skt:more() == false)
    assert(skt:send(msg))
  end;

  cli_send = function(skt)
    assert(skt:send('hello'))
  end;

  cli_recv = function(skt)
    local msg, more = assert(print_msg("CLI RECV: ", skt:recv()))
    assert(more       == false)
    assert(skt:more() == false)
  end;
}

Test_Send_Recv_all  = { name = 'Test_Send_Recv_all';
  srv = function(skt)
    local msg = assert(print_msg("SRV RECV: ",skt:recv_all()))
    assert(skt:send_all(msg))
  end;

  cli_send = function(skt)
    assert(skt:send_all{'hello','world'})
  end;

  cli_recv = function(skt)
    assert(print_msg("CLI RECV: ", skt:recv_all()))
  end;
}

Test_Send_Recv_msg  = { name = 'Test_Send_Recv_msg';
  srv = function(skt)
    local msg = assert(zmq.msg_init())
    local msg2, more = assert(print_msg("SRV RECV: ",skt:recv_msg(msg)))
    assert(msg == msg2)
    assert(more       == false)
    assert(skt:more() == false)
    assert(msg:more() == false)
    assert(skt:send_msg(msg))
    assert(not msg:closed())
    assert(msg:size() == 0)
    assert(msg:close())

    assert(msg:closed())
    assert(not pcall(msg.size, msg))
    assert(not pcall(msg.more, msg))
    assert(msg:close())
  end;

  cli_send = function(skt)
    local msg = assert(zmq.msg_init_data('hello'))
    assert(msg:send(skt))
    assert(not msg:closed())
    assert(msg:size() == 0)
    assert(msg:close())
  end;

  cli_recv = function(skt)
    local msg = assert(zmq.msg_init())
    local msg2, more = assert(print_msg("CLI RECV: ", msg:recv(skt)))
    assert(msg == msg2)
    assert(more       == false)
    assert(skt:more() == false)
    assert(msg:more() == false)
    assert(not msg:closed())
    assert(msg:close())
  end;
}

Test_Send_Recv_more = { name = 'Test_Send_Recv_more';
  srv = function(skt) 
    local msg1, more = assert(skt:recv())
    assert(more == skt:more() and more == true)
    local msg2, more = assert(skt:recv_new_msg())
    assert(more == skt:more() and more == msg2:more() and more == true)
    local msg3, more = assert(zmq.msg_init():recv(skt))
    assert(more == skt:more() and more == msg3:more() and more == true)
    local msgs = {}
    local t = {}
    repeat 
      local msg, more = assert(skt:recv())
      assert(more == skt:more())
      table.insert(msgs, msg)
      table.insert(t, msg)
    until not more

    table.insert(t, 1, msg3:data())
    table.insert(t, 1, msg2:data())
    table.insert(t, 1, msg1)
    print_msg("SRV RECV: ",t)

    for i = 1, #t-1 do assert(skt:send_more(t[i])) end
    assert(skt:send(t[#t]))
  end;

  cli_send = function(skt)
    zmq.msg_init_data('Hello'):send_more(skt)
    skt:send_more(", ")
    zmq.msg_init_data('world'):send(skt, zmq.SNDMORE)
    skt:send("!!!", zmq.SNDMORE)
    skt:send("")
  end;

  cli_recv = function(skt)
    assert(print_msg("CLI RECV: ", skt:recv_all()))
  end;
}

Test_Send_Recv_buf  = { name = 'Test_Send_Recv_buf';
  srv = function(skt)
    local msg, more, len = assert(print_msg("SRV RECV: ", skt:recv_len(16)))
    assert(more       == false)
    assert(skt:more() == false)
    assert(len == 32)
    assert(#msg == 16)
    assert(skt:send(msg))
  end;

  cli_send = function(skt)
    assert(skt:send(('0'):rep(32)))
  end;

  cli_recv = function(skt)
    local msg, more = assert(print_msg("CLI RECV: ", skt:recv()))
    assert(more       == false)
    assert(skt:more() == false)
    assert(skt:send(('0'):rep(8)))
  end;
}



Test_Assert()
Test_Message()
Test_Error()
Test_Context()
Test_Sockopt()
Test_SockAutoclose()
Test_Bind_Connect()
Test_loop()
Test_Remove_ev()
TestServer(Test_Send_Recv)
TestServer(Test_Send_Recv_buf)
TestServer(Test_Send_Recv_all)
TestServer(Test_Send_Recv_msg)
TestServer(Test_Send_Recv_more)
Test_Timer(ztimer.absolute())
Test_Timer(ztimer.monotonic())
