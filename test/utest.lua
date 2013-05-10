local function zversion(zmq)
  local version = zmq.version()
  return string.format("%d.%d.%d", version[1], version[2], version[3])
end

local function iszvereq(zmq, mi, ma, bu)
  local version = zmq.version()
  return (mi == version[1]) and (ma == version[2]) and (bu == version[3])
end

print("------------------------------------")
print("Lua version: " .. (_G.jit and _G.jit.version or _G._VERSION))
print("ZQM version: " .. zversion(require"lzmq"))
print("------------------------------------")
print("")

local HAS_RUNNER = not not lunit 

local lunit    = require "lunit"
-- @fix in lunit:
--  return multiple values from assert_XXX
--  implement assert_ge/le methods 

local skip     = function (msg) return function() lunit.fail("#SKIP: " .. msg) end end
local IS_LUA52 = _VERSION >= 'Lua 5.2'

local TEST_CASE = function (name)
  if not IS_LUA52 then
    module(name, package.seeall, lunit.testcase)
    setfenv(2, _M)
  else
    return lunit.module(name, 'seeall')
  end
end

local function weak_ptr(val)
  return setmetatable({value = val},{__mode = 'v'})
end

local function gc_collect()
  collectgarbage("collect")
  collectgarbage("collect")
end

local zmq    = require "lzmq"
local ztimer = require "lzmq.timer"
local zloop  = require "lzmq.loop"

-- usage assert_equal(socket_count(ctx, 1))
local function socket_count(ctx, hint)
  if ctx.socket_count then -- if compile with debug info
    return hint, ctx:socket_count()
  end
  return hint, hint
end

local function wait(ms)
  ztimer.sleep(ms or 100)
end

local ECHO_ADDR = "inproc://echo"

local _ENV = TEST_CASE'interface'         if true then

function setup() end

function teardown() end

function test_constant()
  do -- flags
    assert_number(zmq.SNDMORE                        )
    assert_number(zmq.DONTWAIT                       )
    if zmq.NOBLOCK then assert_number(zmq.NOBLOCK    ) end
  end
  do -- socket opt
    assert_number(zmq.AFFINITY                       )
    assert_number(zmq.IDENTITY                       )
    assert_number(zmq.SUBSCRIBE                      )
    assert_number(zmq.UNSUBSCRIBE                    )
    assert_number(zmq.RATE                           )
    assert_number(zmq.RECOVERY_IVL                   )
    assert_number(zmq.SNDBUF                         )
    assert_number(zmq.RCVBUF                         )
    assert_number(zmq.RCVMORE                        )
    assert_number(zmq.FD                             )
    assert_number(zmq.EVENTS                         )
    assert_number(zmq.TYPE                           )
    assert_number(zmq.LINGER                         )
    assert_number(zmq.RECONNECT_IVL                  )
    assert_number(zmq.BACKLOG                        )
    assert_number(zmq.RECONNECT_IVL_MAX              )
    assert_number(zmq.MAXMSGSIZE                     )
    assert_number(zmq.SNDHWM                         )
    assert_number(zmq.RCVHWM                         )
    assert_number(zmq.MULTICAST_HOPS                 )
    assert_number(zmq.RCVTIMEO                       )
    assert_number(zmq.SNDTIMEO                       )
    assert_number(zmq.IPV4ONLY                       )
    assert_number(zmq.LAST_ENDPOINT                  )
    assert_number(zmq.TCP_KEEPALIVE                  )
    assert_number(zmq.TCP_KEEPALIVE_CNT              )
    assert_number(zmq.TCP_KEEPALIVE_IDLE             )
    assert_number(zmq.TCP_KEEPALIVE_INTVL            )
    assert_number(zmq.TCP_ACCEPT_FILTER              )
    if false then 
      -- @todo optional test
      assert_number(zmq.ROUTER_BEHAVIOR                )
      assert_number(zmq.FAIL_UNROUTABLE                )
      assert_number(zmq.ROUTER_MANDATORY               )
      assert_number(zmq.DELAY_ATTACH_ON_CONNECT        )
      assert_number(zmq.XPUB_VERBOSE                   )
      assert_number(zmq.ROUTER_RAW                     )
    end
  end
  do -- errors
    assert_table(zmq.errors)
    for _, Z in ipairs{zmq, zmq.errors} do
      assert_number( Z.EPERM                )
      assert_number( Z.ENOENT               )
      assert_number( Z.ESRCH                )
      assert_number( Z.EINTR                )
      assert_number( Z.EIO                  )
      assert_number( Z.ENXIO                )
      assert_number( Z.E2BIG                )
      assert_number( Z.ENOEXEC              )
      assert_number( Z.EBADF                )
      assert_number( Z.ECHILD               )
      assert_number( Z.EAGAIN               )
      assert_number( Z.ENOMEM               )
      assert_number( Z.EACCES               )
      assert_number( Z.EFAULT               )
      assert_number( Z.EBUSY                )
      assert_number( Z.EEXIST               )
      assert_number( Z.EXDEV                )
      assert_number( Z.ENODEV               )
      assert_number( Z.ENOTDIR              )
      assert_number( Z.EISDIR               )
      assert_number( Z.ENFILE               )
      assert_number( Z.EMFILE               )
      assert_number( Z.ENOTTY               )
      assert_number( Z.EFBIG                )
      assert_number( Z.ENOSPC               )
      assert_number( Z.ESPIPE               )
      assert_number( Z.EROFS                )
      assert_number( Z.EMLINK               )
      assert_number( Z.EPIPE                )
      assert_number( Z.EDOM                 )
      assert_number( Z.EDEADLK              )
      assert_number( Z.ENAMETOOLONG         )
      assert_number( Z.ENOLCK               )
      assert_number( Z.ENOSYS               )
      assert_number( Z.ENOTEMPTY            )
      assert_number( Z.EINVAL               )
      assert_number( Z.ERANGE               )
      assert_number( Z.EILSEQ               )
      assert_number( Z.ENOTSUP              )
      assert_number( Z.EPROTONOSUPPORT      )
      assert_number( Z.ENOBUFS              )
      assert_number( Z.ENETDOWN             )
      assert_number( Z.EADDRINUSE           )
      assert_number( Z.EADDRNOTAVAIL        )
      assert_number( Z.ECONNREFUSED         )
      assert_number( Z.EINPROGRESS          )
      assert_number( Z.ENOTSOCK             )
      assert_number( Z.EMSGSIZE             )
      assert_number( Z.EAFNOSUPPORT         )
      assert_number( Z.ENETUNREACH          )
      assert_number( Z.ECONNABORTED         )
      assert_number( Z.ECONNRESET           )
      assert_number( Z.ENOTCONN             )
      assert_number( Z.ETIMEDOUT            )
      assert_number( Z.EHOSTUNREACH         )
      assert_number( Z.ENETRESET            )
      assert_number( Z.EFSM                 )
      assert_number( Z.ENOCOMPATPROTO       )
      assert_number( Z.ETERM                )
      assert_number( Z.EMTHREAD             )
    end
  end
end

function test_assert()
  local ok1, msg1 = pcall(zmq.assert, false, zmq.error(zmq.errors.EINVAL));    -- object
  local ok2, msg2 = pcall(zmq.assert, false, zmq.errors.EINVAL);               -- number
  local ok3, msg3 = pcall(zmq.assert, false, zmq.strerror(zmq.errors.EINVAL)); -- string
  assert_false(ok1)
  assert_false(ok2)
  assert_false(ok3)
  assert_string(msg1)
  assert_equal(msg1, msg2)
  assert_equal(msg1, msg3)
end

function test_error()
  for k, v in pairs(zmq.errors) do
    assert_equal(k, zmq.errors[v])
  end

  local zassert = zmq.assert
  local err = zmq.error(zmq.errors.EAGAIN)
  assert_equal(zmq.errors.EAGAIN, err:no())
  assert_equal("EAGAIN", err:mnemo())
  local str_err = tostring(err)
  local ok, msg = pcall( zassert, false, err )
  assert_false(ok)
  assert_equal(str_err, msg)
end

function test_interface()
  assert_function(zmq.version)
  assert_function(zmq.device)
  assert_function(zmq.assert)
  assert_function(zmq.error)
  assert_function(zmq.strerror)
  assert_function(zmq.context)
  assert_function(zmq.poller)
  assert_function(zmq.init)
  assert_function(zmq.init_ctx)
  assert_function(zmq.msg_init)
  assert_function(zmq.msg_init_size)
  assert_function(zmq.msg_init_data)
  assert_function(zmq.msg_init_data_multi)
  assert_function(zmq.msg_init_data_array)
  if zmq.proxy then assert_function(zmq.proxy) end
end

end

local _ENV = TEST_CASE'ctx/skt interface' if true then

local ctx, skt

function setup()
  ctx = assert_userdata(zmq.context())
  skt = assert_userdata(ctx:socket(zmq.SUB))
  ctx:autoclose(skt)
end

function teardown()
  if ctx then ctx:destroy()             end
  if skt then assert_true(skt:closed()) end
end

function test_context()
  assert_function(ctx.set)
  assert_function(ctx.get)
  assert_function(ctx.lightuserdata)
  assert_function(ctx.get_io_threads)
  assert_function(ctx.set_io_threads)
  assert_function(ctx.get_max_sockets)
  assert_function(ctx.set_max_sockets)
  assert_function(ctx.closed)
  assert_function(ctx.socket)
  assert_function(ctx.autoclose)
  assert_function(ctx.destroy)
  assert_function(ctx.term)
end

function test_socket()
  assert_function(skt.bind)
  assert_function(skt.unbind)
  assert_function(skt.connect)
  assert_function(skt.disconnect)
  assert_function(skt.send)
  assert_function(skt.send_msg)
  assert_function(skt.send_more)
  assert_function(skt.recv)
  assert_function(skt.recv_msg)
  assert_function(skt.recv_new_msg)
  assert_function(skt.recv_len)
  assert_function(skt.send_all)
  assert_function(skt.recv_all)
  assert_function(skt.more)
  assert_function(skt.on_close)
  assert_function(skt.close)
  assert_function(skt.closed)

  assert_function(skt.getopt_int)
  assert_function(skt.getopt_i64)
  assert_function(skt.getopt_u64)
  assert_function(skt.getopt_str)
  assert_function(skt.setopt_int)
  assert_function(skt.setopt_i64)
  assert_function(skt.setopt_u64)
  assert_function(skt.setopt_str)


  assert_function(skt.get_affinity            )
  assert_function(skt.set_affinity            )
  assert_function(skt.get_identity            )
  assert_function(skt.set_identity            )

  assert_function(skt.subscribe               )
  assert_function(skt.set_subscribe           )
  assert_function(skt.unsubscribe             )
  assert_function(skt.set_unsubscribe         )

  assert_function(skt.get_rate                )
  assert_function(skt.set_rate                )
  assert_function(skt.get_recovery_ivl        )
  assert_function(skt.set_recovery_ivl        )

  assert_function(skt.get_sndbuf              )
  assert_function(skt.set_sndbuf              )
  assert_function(skt.get_rcvbuf              )
  assert_function(skt.set_rcvbuf              )
  assert_function(skt.rcvmore                 )
  assert_function(skt.get_rcvmore             )
  assert_function(skt.fd                      )
  assert_function(skt.get_fd                  )
  assert_function(skt.events                  )
  assert_function(skt.get_events              )
  assert_function(skt.type                    )
  assert_function(skt.get_type                )

  assert_function(skt.get_linger              )
  assert_function(skt.set_linger              )
  assert_function(skt.get_reconnect_ivl       )
  assert_function(skt.set_reconnect_ivl       )
  assert_function(skt.get_backlog             )
  assert_function(skt.set_backlog             )

  assert_function(skt.get_reconnect_ivl_max   )
  assert_function(skt.set_reconnect_ivl_max   )
  assert_function(skt.get_maxmsgsize          )
  assert_function(skt.set_maxmsgsize          )
  assert_function(skt.get_sndhwm              )
  assert_function(skt.set_sndhwm              )
  assert_function(skt.get_rcvhwm              )
  assert_function(skt.set_rcvhwm              )
  assert_function(skt.get_multicast_hops      )
  assert_function(skt.set_multicast_hops      )
  assert_function(skt.get_rcvtimeo            )
  assert_function(skt.set_rcvtimeo            )
  assert_function(skt.get_sndtimeo            )
  assert_function(skt.set_sndtimeo            )
  assert_function(skt.get_ipv4only            )
  assert_function(skt.set_ipv4only            )

  assert_function(skt.last_endpoint           )
  assert_function(skt.get_last_endpoint       )

  assert_function(skt.fail_unroutable         )
  assert_function(skt.set_fail_unroutable     )

  assert_function(skt.router_behavior         )
  assert_function(skt.set_router_behavior     )

  assert_function(skt.router_mandatory        )
  assert_function(skt.set_router_mandatory    )

  assert_function(skt.get_tcp_keepalive       )
  assert_function(skt.set_tcp_keepalive       )
  assert_function(skt.get_tcp_keepalive_cnt   )
  assert_function(skt.set_tcp_keepalive_cnt   )
  assert_function(skt.get_tcp_keepalive_idle  )
  assert_function(skt.set_tcp_keepalive_idle  )
  assert_function(skt.get_tcp_keepalive_intvl )
  assert_function(skt.set_tcp_keepalive_intvl )

  assert_function(skt.tcp_accept_filter       )
  assert_function(skt.set_tcp_accept_filter   )

  if false then -- optional
    -- @todo optional test
    assert_function(skt.get_delay_attach_on_connect )
    assert_function(skt.set_delay_attach_on_connect )
    assert_function(skt.get_xpub_verbose         )
    assert_function(skt.set_xpub_verbose         )
    assert_function(skt.get_router_raw           )
    assert_function(skt.set_router_raw           )
  end
end

function test_socket_error()
  -- skt:send()
  -- skt:send(nil)
end

function test_socket_options()
  assert_true(skt:set_subscribe("sub 1"))
  assert_true(skt:set_subscribe("sub 2"))
  assert_true(skt:set_subscribe{"sub 3"; "sub 3"})

  assert_true(skt:set_unsubscribe{"sub 1", "sub 2"})
  local ok, err, no = skt:set_unsubscribe{"sub 3", "sub 1"}
  if not ok then assert_equal(2, no) end

  assert_true(skt:set_unsubscribe("sub 3"))
end

function test_context_options()
  assert_true(ctx:set_io_threads(2))
  assert_equal(2, ctx:get_io_threads())
  assert_true(ctx:set_max_sockets(252))
  assert_equal(252, ctx:get_max_sockets())

  local ptr = assert_userdata(ctx:lightuserdata())
  local ctx2 = assert_userdata(zmq.init_ctx(ptr))
  assert_not_equal(ctx, ctx2)
  assert_not_equal(ptr, ctx2:lightuserdata())
  assert_equal(ctx:get_io_threads(),  ctx2:get_io_threads() )
  assert_equal(ctx:get_max_sockets(), ctx2:get_max_sockets())

  assert_false(ctx2:closed())
  assert_true(ctx2:destroy())
  assert_true(ctx2:closed())

  assert_error(function() ctx2:get_io_threads() end)
  assert_equal(2, ctx:get_io_threads())

  assert_false(ctx:closed())
  assert_true(ctx:destroy())
  assert_true(ctx:closed())
end

end

local _ENV = TEST_CASE'socket autoclose'  if true then

local ctx, skt

function setup() end

function teardown()
  if skt then skt:close()   end
  if ctx then ctx:destroy() end
end

function test_socket_autoclose()
  ctx = assert_userdata(zmq.context())
  skt = assert_userdata(ctx:socket(zmq.SUB))
  assert_equal(socket_count(ctx, 1))
  ctx:autoclose(skt)
  assert_true(ctx:destroy())
  assert_true(skt:closed())

  ctx = assert_userdata(zmq.context())
  local ptr
  do 
    local skt = ctx:socket(zmq.SUB)
    assert_equal(socket_count(ctx, 1))
    ptr = weak_ptr(skt)
  end
  gc_collect()
  assert_nil(ptr.value)
  assert_equal(socket_count(ctx, 0))
  assert_true(ctx:destroy())

  ctx = assert_userdata(zmq.context())
  local ptr
  do
    local skt = ctx:socket(zmq.SUB)
    ctx:autoclose(skt) -- do not prevent clean socket by gc
    ptr = weak_ptr(skt)
  end
  gc_collect()
  assert_nil(ptr.value)
  assert_equal(socket_count(ctx, 0))
  assert_true(ctx:destroy())
end

end

local _ENV = TEST_CASE'message interface' if true then

local msg

function setup()end

function teardown()
  if msg then msg:close() end
end

function test_interface()
  msg = zmq.msg_init()
  assert_function(msg.more)
  assert_function(msg.close)
  assert_function(msg.closed)
  assert_function(msg.move)
  assert_function(msg.copy)
  assert_function(msg.size)
  assert_function(msg.set_size)
  assert_function(msg.pointer)
  assert_function(msg.data)
  assert_function(msg.set_data)
  assert_function(msg.more)
  assert_function(msg.get)
  assert_function(msg.set)
  assert_function(msg.send)
  assert_function(msg.send_more)
  assert_function(msg.recv)
end

function test_close()
  msg = zmq.msg_init()
  assert_false(msg:closed())
  assert_equal(0, msg:size())
  assert_true(msg:close())
  assert_true(msg:closed())
  assert_error(function() msg:size() end)
  assert_error(function() msg:more() end)
  assert_error(function() msg:data() end)
  assert_true(msg:close())
end

function test_access_after_close()
  local msg = zmq.msg_init()
  assert_true(msg:close())
  assert_error(function() msg:data() end) -- no AV
end

function test_create()
  msg = assert_userdata(zmq.msg_init())
  assert_true(msg:close())
  msg = assert_userdata(zmq.msg_init_size(255))
  assert_true(msg:close())
  msg = assert_userdata(zmq.msg_init_data("Hello world!"))
  assert_true(msg:close())
end

function test_operations()
  local msg1
  local msg2
  local msg3

  msg1 = assert_userdata(zmq.msg_init_size(10))
  assert_equal(10, msg1:size())
  assert_true(msg1:set_data("Hello"))
  assert_equal(10, msg1:size())
  local data = assert_string(msg1:data())
  assert_equal(10, #data)
  assert_equal('Hello', (data:sub(1, 5)))

  assert_true(msg1:set_data(6, ", world!")) -- append and resize buffer
  assert_equal(13, msg1:size())
  local data = assert_string(msg1:data())
  assert_equal(13, #data)
  assert_equal('Hello, world!', data)
  
  msg2 = assert_userdata(zmq.msg_init())
  assert_equal(msg2, msg2:move(msg1))

  assert_equal(0, msg1:size())
  assert_false(msg1:closed())
  assert_true(msg1:set_data('hi'))
  assert_equal(2, msg1:size())
  assert_equal('hi', msg1:data())
  assert_true(msg1:close())

  assert_equal(#data, msg2:size())
  assert_equal(data,  msg2:data())

  msg3 = assert_userdata(zmq.msg_init())
  assert_equal(msg3, msg3:copy(msg2)) -- copy to exists object

  assert_equal(#data, msg2:size())
  assert_equal(data,  msg2:data())
  assert_equal(#data, msg3:size())
  assert_equal(data,  msg3:data())
  assert_true(msg2:set_data(("0"):rep(#data)))
  assert_equal(#data, msg3:size())
  assert_equal(data,  msg3:data())

  assert_true(msg2:close())
  assert_true(msg3:close())
  
  msg1 = assert_userdata(zmq.msg_init_data("hello world"))
  msg2 = assert_userdata(msg1:copy()) -- copy to new object
  assert_not_equal(msg1, msg2)
  assert_equal(msg1:data(), msg2:data())

  msg3 = assert(msg1:move())
  assert_not_equal(msg1, msg3)
  assert_equal(msg2:data(), msg3:data())
  assert_equal("", msg1:data())

  assert_error(function() msg2:copy(nil) end) -- nil params do not create new object
  assert_error(function() msg3:move(nil) end) -- nil params do not create new object

  assert_true(msg1:close())
  assert_true(msg2:close())
  assert_true(msg3:close())
end

function test_tostring()
  local msg = assert_userdata(zmq.msg_init_data("Hello world!"))
  assert_equal("Hello world!", tostring(msg))
end

function test_pointer()
  local msg = assert_userdata(zmq.msg_init_data("Hello world!"))
  local ptr = msg:pointer()
  assert_true(msg:set_data("Privet"))
  assert_equal("Privetworld!", msg:data())
  assert_equal(ptr, msg:pointer())
  assert_true(msg:set_size(100))
  assert_not_equal(ptr, msg:pointer())
  ptr = msg:pointer()
  assert_true(msg:set_size(100))
  assert_equal(ptr, msg:pointer())
end

function test_resize()
  local msg = assert_userdata(zmq.msg_init_data("Hello world!"))
  assert_true(msg:set_size(5)) -- shrink
  assert_equal(5, msg:size())
  assert_equal("Hello", msg:data())
  assert_true(msg:set_size(10)) -- extend
  assert_equal(10, msg:size())
  local str = assert_string(msg:data())
  assert_equal("Hello", str:sub(1,5))
end

function test_setdata()
  local msg = assert_userdata(zmq.msg_init_data("Hello world!"))
  assert_true(msg:set_data("Privet")) -- this is do not shrink message
  assert_equal(12, msg:size())
  assert_equal("Privetworld!", msg:data())
  assert_true(msg:set_data(7, " world!!!")) -- extend message
  assert_equal(15, msg:size())
  assert_equal("Privet world!!!", msg:data())
end

end

local _ENV = TEST_CASE'bind/connect'      if true then

local ctx, pub, sub1, sub2, sub3, msg

function setup()
  ctx = assert_userdata(zmq.context())
  pub = assert_userdata(ctx:socket(zmq.PUB))
  ctx:autoclose(pub)
  sub1 = assert_userdata(ctx:socket(zmq.SUB))
  sub2 = assert_userdata(ctx:socket(zmq.SUB))
  sub3 = assert_userdata(ctx:socket(zmq.SUB))
  ctx:autoclose(sub1)
  ctx:autoclose(sub2)
  ctx:autoclose(sub3)
end

function teardown()
  if msg then msg:close()               end
  if ctx then ctx:destroy()             end
  if pub then assert_true(pub:closed()) end
  if sub1 then assert_true(sub1:closed()) end
  if sub2 then assert_true(sub2:closed()) end
  if sub3 then assert_true(sub3:closed()) end
end

function test_connect()
  local ok, err, str = pub:bind{
    ECHO_ADDR;
    "inproc://pub.test.1";
    "inproc://pub.test.2";
    "error address";
    "inproc://pub.test.3";
  }

  assert_nil(ok)
  assert_equal("error address", str)
  assert_true(pub:bind("inproc://pub.test.3"))

  assert_true(sub1:subscribe(""))
  assert_true(sub2:subscribe(""))
  assert_true(sub3:subscribe(""))

  assert_true(sub1:set_rcvtimeo(100))
  assert_true(sub2:set_rcvtimeo(100))
  assert_true(sub3:set_rcvtimeo(100))

  wait()

  assert_true(sub1:connect("inproc://pub.test.1"))
  assert_true(sub2:connect("inproc://pub.test.2"))
  assert_true(sub3:connect("inproc://pub.test.3"))

  wait()

  assert_true(pub:send("hello"))
  assert_equal( "hello", assert_string(sub1:recv()))
  assert_equal( "hello", assert_string(sub2:recv()))
  assert_equal( "hello", assert_string(sub3:recv()))

  assert_true(sub1:connect(ECHO_ADDR))

  wait()

  assert_true(pub:send("hello"))
  assert_equal( "hello", assert_string(sub1:recv()))
  assert_equal( "hello", assert_string(sub1:recv()))

  if not iszvereq(zmq, 3, 2, 2) then -- fix in 3.2.3
    -- disconnect from first and get error from second
    ok, err, str = sub1:disconnect{
      ECHO_ADDR;
      "inproc://pub.test.3";
    }
    assert_nil(ok)
    assert_equal("inproc://pub.test.3", str)

    wait()

    assert_true(pub:send("hello"))
    assert_equal( "hello", assert_string(sub1:recv()))
    assert_nil(sub1:recv())
  end
end

end

local _ENV = TEST_CASE'Send Recv'         if true then

local ctx, pub, sub, msg

function setup()
  ctx = assert_userdata(zmq.context())
  pub = assert_userdata(ctx:socket(zmq.PUB))
  ctx:autoclose(pub)
  sub = assert_userdata(ctx:socket(zmq.SUB))
  ctx:autoclose(sub)
  assert_true(pub:bind("inproc://test"))
  wait()
  assert_true(sub:connect("inproc://test"))
  assert_true(sub:subscribe(""))
  wait()
end

function teardown()
  if msg then msg:close()               end
  if ctx then ctx:destroy()             end
  if pub then assert_true(pub:closed()) end
  if sub then assert_true(sub:closed()) end
end

function test_recv()
  assert_true(pub:send(("0"):rep(32)))

  local str, more = sub:recv()
  assert_equal(("0"):rep(32), str, more)
  assert_false(more)
end

function test_recv_len()
  assert_true(pub:send(("0"):rep(32)))
  assert_true(pub:send(("0"):rep(8)))

  local str, more, len = sub:recv_len(16)
  assert_equal(("0"):rep(16), str, more)
  assert_false(more)
  assert_equal(32, len)

  local str, more, len = sub:recv_len(16)
  assert_equal(("0"):rep(8), str, more)
  assert_false(more)
  assert_equal(8, len)
end

function test_recv_msg()
  do -- send
    msg = assert(zmq.msg_init_data('hello'))
    assert_equal('hello', msg:data())
    assert_equal(5, msg:size())

    assert_true(msg:send(pub))
    assert_false(msg:closed())
    assert_equal(0, msg:size())
    assert_true(msg:close())
  end

  do -- recv
    msg = assert_userdata(zmq.msg_init())
    local msg2, more = sub:recv_msg(msg)
    assert_equal(msg, msg2, more)
    assert_false(more)
    assert_false(sub:more())
    assert_false(msg:more())
    assert_equal('hello', msg:data())
    assert_equal(5, msg:size())
    assert_true(msg:close())
  end
end

function test_recv_msg_more()
  do -- send
    msg = assert_userdata(zmq.msg_init_data('hello'))
    assert_true(msg:send_more(pub))
    assert_equal(0, msg:size())
    assert_false(msg:closed())
    assert_true(msg:close())
    assert_true(pub:send_more(", "))
    msg = assert_userdata(zmq.msg_init_data('world'))
    assert_true(msg:send(pub, zmq.SNDMORE))
    assert_true(pub:send("!!!", zmq.SNDMORE))
    assert_true(pub:send(""))
  end

  do -- recv
    local msg1, more = sub:recv()
    assert_equal('hello', msg1, more)
    assert_true(more)
    assert_equal(more, sub:more())
    assert_equal(1, sub:rcvmore())

    local msg2, more = sub:recv_new_msg()
    assert_userdata(msg2)
    assert_equal(', ', msg2:data())
    assert_true(more)
    assert_equal(more, sub:more())
    assert_equal(more, msg2:more())
    assert_equal(1, sub:rcvmore())

    local msg3 = assert_userdata(zmq.msg_init())
    local msg3_, more = msg3:recv(sub)
    assert_equal(msg3, msg3_, more)
    assert_equal('world', msg3:data())
    assert_true(more)
    assert_equal(more, sub:more())
    assert_equal(more, msg3:more())
    assert_equal(1, sub:rcvmore())

    local msgs = {}
    repeat 
      local msg, more = sub:recv()
      assert_string(msg, more)
      assert_equal(more, sub:more())
      assert_equal(more and 1 or 0, sub:rcvmore())
      table.insert(msgs, msg)
    until not more
    assert_equal(2, #msgs)
  end
end

function test_recv_all()
  assert_true(pub:send_all{'hello', ', ', 'world'})
  local t = assert_table(sub:recv_all())
  assert_equal(3, #t)
  assert_equal('hello, world', table.concat(t))
end

end

local _ENV = TEST_CASE'loop'              if true then

local loop, timer

function setup()
  loop  = assert(zloop.new())
  timer = ztimer.monotonic()
end

function teardown()
  loop:destroy()
  wait(500) -- for TCP time to release IP address
end

function test_sleep()
  local flag1 = false
  loop:add_once(10, function() assert_false(flag1) flag1 = true end)
  assert_equal(0, loop:flush(100)) -- only flush io events and no wait
  assert_false(flag1)

  timer:start()
  assert_equal(1, loop:sleep_ex(100)) -- run event
  assert_true(timer:stop() >= 100)    -- wait full interval
  assert_true(flag1)                  -- ensure event was emit

  flag1 = false
  loop:add_once(10, function() assert_false(flag1) flag1 = true end)
  timer:start()
  loop.sleep(100)                     -- do not run event
  assert_true(timer:stop() >= 100)    -- wait full interval
  assert_false(flag1)

  assert_equal(0, loop:flush(100))    -- only flush io events and no wait
  assert_false(flag1)

  assert_equal(1, loop:sleep_ex(0))   -- run event
  assert_true(flag1)                  -- ensure event was emit
end

function test_remove_event()
  local c = 0
  local N = 10
  local T = 100
  local flag1, flag2, flag3

  local ext_ev = loop:add_interval(T, function() flag3 = false end)

  local function fn2(ev, loop) 
    assert_true(c < N)
    assert_true(flag1, "event 1 does not stop")

    c = c + 1
    if c == N then
      ev:reset()     -- remove self
      ext_ev:reset() -- remove ext

      assert_false(flag3, "ext_ev does not work")

      c, flag2, flag3 = 0, true, true

      loop:add_interval(T, function()
        assert_true(flag1, "event 1 does not stop")
        assert_true(flag2, "event 1 does not stop")
        assert_true(flag3, "event 1 does not stop")
        c = c + 1
        if c == N then
          loop:interrupt()
        end
      end)

    end
  end

  local function fn1(ev, loop) 
    assert_true(c < N)
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

  assert_true(flag1)
  assert_true(flag2)
end

function test_interface()
  assert_function(loop.destroy)
  assert_function(loop.context)
  assert_function(loop.flush)
  assert_function(loop.sleep)
  assert_function(loop.sleep_ex)
  assert_function(loop.interrupt)
  assert_function(loop.add_socket)
  assert_function(loop.remove_socket)
  assert_function(loop.start)
  assert_function(loop.add_once)
  assert_function(loop.add_interval)
  assert_function(loop.add_time)
end

function test_echo()
  local counter = 0

  local function echo(skt)
    local msg = assert_table(skt:recv_all())
    assert_true(skt:send_all(msg))
    counter = counter + 1
  end

  assert(loop:add_new_bind(zmq.REP, ECHO_ADDR, echo))

  local cli = assert(loop:add_new_connect(zmq.REQ, ECHO_ADDR, echo))

  -- run ball
  loop:add_once(10, function() cli:send_all{'hello', 'world'} end)

  -- time to play
  loop:add_once(2000, function() loop:interrupt() end)

  timer:start()
  loop:start()
  assert_true(timer:stop() >= 2000)
  assert_true(counter > 3)

  loop:destroy()

  assert_true(cli:closed())
end

end

local _ENV = TEST_CASE'timer'             if true then

local timer

function teardown()
  if timer then timer:close() end
end

function test_interface()
  assert_function(ztimer.monotonic)
  assert_function(ztimer.absolute)

  assert_function(ztimer.absolute_time)
  assert_function(ztimer.absolute_delta)
  assert_function(ztimer.absolute_elapsed)

  assert_function(ztimer.monotonic_time)
  assert_function(ztimer.monotonic_delta)
  assert_function(ztimer.monotonic_elapsed)
end

local function test_timer_interface(timer)
  assert_function(timer.close)
  assert_function(timer.closed)
  assert_function(timer.set)
  assert_function(timer.get)
  assert_function(timer.reset)
  assert_function(timer.setted)
  assert_function(timer.start)
  assert_function(timer.started)
  assert_function(timer.elapsed)
  assert_function(timer.rest)
  assert_function(timer.stop)
  assert_function(timer.is_absolute)
  assert_function(timer.is_monotonic)
end

function test_monotonic_interface()
  timer = ztimer.monotonic()
  test_timer_interface(timer)
end

function test_absolute_interface()
  timer = ztimer.absolute()
  test_timer_interface(timer)
end

local function test_timer(timer)
  local COUNT    = 100
  local INTERVAL = 100
  local DELTA    = 50  -- to ensure

  local name = timer:is_absolute() and 'absolute' or 'monotonic';

  local max_delta, totla_delta, totla_delta2 = 0, 0, 0

  assert_false(timer:setted())
  assert_equal(timer, timer:start())
  assert_error (function() timer:rest() end)
  assert_true(timer:reset())
  assert_number(timer:elapsed())
  assert_number(timer:stop())

  if timer:is_absolute() then
    assert_equal( timer, timer:set(ztimer.absolute_time() + INTERVAL) )
  else
    assert_equal( timer, timer:set(INTERVAL) )
  end

  assert_false(timer:started())
  assert_false(timer:closed())

  assert_error(function() timer:elapsed() end)
  assert_error(function() timer:rest() end)
  assert_equal(timer, timer:start())
  assert_true(timer:started())
  assert_true(timer:setted())
  wait(100)
  local e = timer:elapsed()
  assert_true((e >= 50)and(e <= 150), "expected value >=50,<=150 got: " .. tostring(e)) -- wait is not realy correct
  assert_equal(timer, timer:start())
  assert_true(timer:elapsed() < 50)
  assert_number(timer:elapsed())
  assert_number(timer:rest())
  assert_number(timer:stop())
  assert_error(function() timer:elapsed() end)
  assert_error(function() timer:rest()    end)

  for i = 1, COUNT do
    assert_equal(timer, timer:start())
    wait(INTERVAL + DELTA)
    local elapsed = timer:elapsed()
    assert_equal(0, timer:rest())
    assert_true(elapsed <= timer:stop())
  end

  assert_true(timer:close())
  assert_true(timer:closed())
  assert_true(timer:close())
end

function test_monotonic()
  timer = ztimer.monotonic()
  test_timer(timer)
end

function test_absolute()
  timer = ztimer.absolute()
  test_timer(timer)
end

end

if not HAS_RUNNER then lunit.run() end