pcall(require, "luacov")

local function zversion(zmq)
  local version = zmq.version()
  return string.format("%d.%d.%d", version[1], version[2], version[3])
end

local function iszvereq(zmq, mi, ma, bu)
  local version = zmq.version()
  return (mi == version[1]) and (ma == version[2]) and (bu == version[3])
end

local HAS_RUNNER = not not lunit 

local lunit      = require "lunit"
local TEST_CASE  = assert(lunit.TEST_CASE)
local skip       = lunit.skip or function() end
local SKIP       = function(msg) return function() return skip(msg) end end

local IS_LUA52 = _VERSION >= 'Lua 5.2'
local TEST_FFI = ("ffi" == os.getenv("LZMQ"))

-- value >= expected
local function ge(expected, value)
  return (value >= expected), value .. " less then " .. expected
end

local function weak_ptr(val)
  return setmetatable({value = val},{__mode = 'v'})
end

local function gc_collect()
  collectgarbage("collect")
  collectgarbage("collect")
end

local LZMQ = "lzmq" .. (TEST_FFI and ".ffi" or "")

local zmq    = require (LZMQ)
local ztimer = require (LZMQ .. ".timer" )
local zloop  = require (LZMQ .. ".loop"  )
local zpoller= require (LZMQ .. ".poller")

print("------------------------------------")
print("Lua  version: " .. (_G.jit and _G.jit.version or _G._VERSION))
print("ZQM  version: " .. zversion(zmq))
print("lzmq version: " .. zmq._VERSION .. (TEST_FFI and " (FFI)" or ""))
print("------------------------------------")
print("")


local function is_object(o, ...)
  if o == nil then return o, ... end
  local flag = (type(o) == 'table') or (type(o) == 'userdata')
  if not flag then return nil, '`' .. tostring(o) .. '` is not object' end
  return o, ...
end
local is_zmessage    = is_object
local is_zsocket     = is_object
local is_zcontext    = is_object
local is_zcontext_ud = function(o, ...)
  if o == nil then return o, ... end
  local flag = (type(o) == 'number') or (type(o) == 'userdata') or (type(o) == 'string')
  if not flag then return nil, '`' .. tostring(o) .. '` is not zma.context.userdata' end
  return o, ...
end

local function error_is(err, no)
  local msg = "expected `" .. tostring(zmq.error(no)) .. "` but was `" .. tostring(err) .. "`"
  if type(err) == 'number' then
    return err == no, msg
  end
  if type(err) == 'string' then
    return not not string.find(err, tostring(no), nil, true), msg
  end
  return err:no() == no, msg
end

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

local ENABLE = true

local ECHO_ADDR = "inproc://echo"

local _ENV = TEST_CASE'interface'            if ENABLE then

function setup() end

function teardown() end

function test_constant()
  do -- flags
    assert_number(zmq.SNDMORE                        )
    assert_number(zmq.DONTWAIT                       )
    if zmq.NOBLOCK then assert_number(zmq.NOBLOCK    ) end
  end
  do -- poller
    assert_number(zmq.POLLIN                         )
    assert_number(zmq.POLLOUT                        )
    assert_number(zmq.POLLERR                        )
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
      assert_number( Z.EFSM             )
      assert_number( Z.ENOCOMPATPROTO   )
      assert_number( Z.ETERM            )
      assert_number( Z.EMTHREAD         )
      assert_number( Z.EAGAIN           )
      assert_number( Z.EINVAL           )
      assert_number( Z.EHOSTUNREACH     )
      assert_number( Z.ENOTSOCK         )
      assert_number( Z.ENETDOWN         )
      assert_number( Z.EPROTONOSUPPORT  )
      assert_number( Z.ENOBUFS          )
      assert_number( Z.ENETUNREACH      )
      assert_number( Z.ENOTSUP          )
      assert_number( Z.ETIMEDOUT        )
      assert_number( Z.EADDRNOTAVAIL    )
      assert_number( Z.EADDRINUSE       )
      assert_number( Z.ECONNABORTED     )
      assert_number( Z.EAFNOSUPPORT     )
      assert_number( Z.ECONNREFUSED     )
      assert_number( Z.ENOTCONN         )
      assert_number( Z.EINPROGRESS      )
      assert_number( Z.ECONNRESET       )
      assert_number( Z.EMSGSIZE         )
    end
  end
end

function test_assert()
  local msg = zmq.strerror(zmq.errors.EINVAL)
  local ok1, msg1 = pcall(zmq.assert, false, zmq.error(zmq.errors.EINVAL));    -- object
  local ok2, msg2 = pcall(zmq.assert, false, zmq.errors.EINVAL);               -- number
  local ok3, msg3 = pcall(zmq.assert, false, zmq.strerror(zmq.errors.EINVAL)); -- string
  assert_false(ok1)
  assert_false(ok2)
  assert_false(ok3)
  assert_string(msg1)
  assert_string(msg2)
  assert_string(msg3)
  assert(string.find(msg1, msg, nil, true), "`" .. msg .. "` not found in `" .. msg1 .. "`")
  assert(string.find(msg2, msg, nil, true), "`" .. msg .. "` not found in `" .. msg2 .. "`")
  assert(string.find(msg3, msg, nil, true), "`" .. msg .. "` not found in `" .. msg3 .. "`")
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
  -- assert_function(zmq.poller)
  assert_function(zmq.init)
  assert_function(zmq.init_ctx)
  assert_function(zmq.init_socket)
  assert_function(zmq.msg_init)
  assert_function(zmq.msg_init_size)
  assert_function(zmq.msg_init_data)
  -- assert_function(zmq.msg_init_data_multi)
  -- assert_function(zmq.msg_init_data_array)
  if zmq.proxy then assert_function(zmq.proxy) end
end

function test_version()
  local version = assert_table(zmq.version())
  local major,minor,patch = assert_number(zmq.version(true))
  assert_equal(major, version[1])
  assert_equal(minor, version[2])
  assert_equal(patch, version[3])
end

end

local _ENV = TEST_CASE'ctx/skt interface'    if ENABLE then

local ctx, skt

function setup()
  ctx = assert(is_zcontext(zmq.context()))
  skt = assert(is_zsocket(ctx:socket(zmq.SUB)))
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
  if ctx.shutdown then
    assert_function(ctx.shutdown)
    assert_function(ctx.shutdowned)
  end
end

function test_socket()
  assert_function(skt.context)
  assert_function(skt.bind)
  assert_function(skt.unbind)
  assert_function(skt.connect)
  assert_function(skt.disconnect)
  assert_function(skt.send)
  assert_function(skt.send_msg)
  assert_function(skt.send_more)
  assert_function(skt.sendx)
  assert_function(skt.sendx_more)
  assert_function(skt.sendv)
  assert_function(skt.sendv_more)
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
  assert_function(skt.lightuserdata)

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

  -- assert_function(skt.fail_unroutable         )
  -- assert_function(skt.set_fail_unroutable     )

  -- assert_function(skt.router_behavior         )
  -- assert_function(skt.set_router_behavior     )

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

function test_socket_options_ctor()
  assert_true(skt:close())
  skt = assert(is_zsocket(ctx:socket(zmq.SUB,{
    subscribe = { "sub 1", "sub 2", "sub 3" };
    linger    = 123;
  })))
  ctx:autoclose(skt)
  assert_true(skt:set_unsubscribe{"sub 1", "sub 2"})
  assert_equal(123, skt:get_linger())
end

function test_socket_options2_ctor()
  assert_true(skt:close())
  skt = assert(is_zsocket(ctx:socket{zmq.SUB,
    subscribe = { "sub 1", "sub 2", "sub 3" };
    linger    = 123;
  }))
  ctx:autoclose(skt)
  assert_true(skt:set_unsubscribe{"sub 1", "sub 2"})
  assert_equal(123, skt:get_linger())
end

function test_socket_ctor_byname()
  assert_true(skt:close())

  skt = assert(is_zsocket(ctx:socket( "PAIR"   )))
  assert_equal(zmq.PAIR, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket( "PUB"    )))
  assert_equal(zmq.PUB, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket( "SUB"    )))
  assert_equal(zmq.SUB, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket( "REQ"    )))
  assert_equal(zmq.REQ, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket( "REP"    )))
  assert_equal(zmq.REP, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket( "DEALER" )))
  assert_equal(zmq.DEALER, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket( "ROUTER" )))
  assert_equal(zmq.ROUTER, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket( "PULL"   )))
  assert_equal(zmq.PULL, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket( "PUSH"   )))
  assert_equal(zmq.PUSH, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket( "XPUB"   )))
  assert_equal(zmq.XPUB, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket( "XSUB"   )))
  assert_equal(zmq.XSUB, skt:type())
  skt:close()
  if zmq.STREAM then
    skt = assert(is_zsocket(ctx:socket( "STREAM" )))
    assert_equal(zmq.STREAM, skt:type())
    skt:close()
  end

  assert_error(function() skt = ctx:socket( "pair" ) end)
end

function test_socket_ctor_byname2()
  assert_true(skt:close())

  skt = assert(is_zsocket(ctx:socket{ "PAIR"   }))
  assert_equal(zmq.PAIR, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket{ "PUB"    }))
  assert_equal(zmq.PUB, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket{ "SUB"    }))
  assert_equal(zmq.SUB, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket{ "REQ"    }))
  assert_equal(zmq.REQ, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket{ "REP"    }))
  assert_equal(zmq.REP, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket{ "DEALER" }))
  assert_equal(zmq.DEALER, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket{ "ROUTER" }))
  assert_equal(zmq.ROUTER, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket{ "PULL"   }))
  assert_equal(zmq.PULL, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket{ "PUSH"   }))
  assert_equal(zmq.PUSH, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket{ "XPUB"   }))
  assert_equal(zmq.XPUB, skt:type())
  skt:close()
  skt = assert(is_zsocket(ctx:socket{ "XSUB"   }))
  assert_equal(zmq.XSUB, skt:type())
  skt:close()
  if zmq.STREAM then
    skt = assert(is_zsocket(ctx:socket{ "STREAM" }))
    assert_equal(zmq.STREAM, skt:type())
    skt:close()
  end

  assert_error(function() skt = ctx:socket{ "pair" } end)
end

function test_socket_on_close()
  skt = assert(is_zsocket(ctx:socket(zmq.SUB)))
  local flag = false
  skt:on_close(function(...)
    flag = true
    assert_equal(0, select('#', ...))
  end)
  assert_false(flag)
  skt:close()
  assert_true(flag)
end

function test_context_options()
  assert_true(ctx:set_io_threads(2))
  assert_equal(2, ctx:get_io_threads())
  assert_true(ctx:set_max_sockets(252))
  assert_equal(252, ctx:get_max_sockets())

  local ptr = assert(is_zcontext_ud(ctx:lightuserdata()))
  local ctx2 = assert(is_zcontext(zmq.init_ctx(ptr)))
  assert_not_equal(ctx, ctx2)
  assert_equal(ptr, ctx2:lightuserdata())
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

function test_context_options_on_ctor()
  assert_true(ctx:destroy())
  ctx = assert(is_zcontext(zmq.context{
    io_threads  = 2;
    max_sockets =252;
  }))
  assert_equal(2, ctx:get_io_threads())
  assert_equal(252, ctx:get_max_sockets())
end

function test_context_options_fail_on_ctor()
  assert_true(ctx:destroy())
  local ctx, err = zmq.context{
    max_sockets = -1;
  }
  assert_nil(ctx, err)
end

function test_socket_context()
  assert_equal(ctx, skt:context())
end

end

local _ENV = TEST_CASE'context'              if ENABLE then

local ctx, skt

function setup() end

function teardown()
  if skt then skt:close()   end
  if ctx then ctx:destroy() end
end

function test_context_shutdown()
  ctx = assert(is_zcontext(zmq.context()))
  if not ctx.shutdown then
    return skip("shutdown support since ZMQ 4.0.0")
  end

  local ptr  = assert(is_zcontext_ud(ctx:lightuserdata()))
  local ctx2 = assert(is_zcontext(zmq.init_ctx(ptr)))

  -- to prevent autoclose socket
  skt = assert(is_zsocket(ctx2:socket(zmq.SUB)))
  skt:set_rcvtimeo(1)

  local ok, err = skt:recv()
  assert(not ok, 'EAGAIN expected got: ' .. tostring(ok))
  assert(error_is(err, zmq.errors.EAGAIN))
  assert_false(ctx:shutdowned())
  assert_true(ctx:shutdown())
  assert_true(ctx:shutdowned())
  assert_false(ctx:closed())
  assert_error(function() ctx:socket() end)
  assert_error(function() ctx:shutdown() end)
  assert_false(skt:closed())
  local ok, err = skt:recv()
  assert(not ok, 'ETERM expected got: ' .. tostring(ok))
  assert(error_is(err, zmq.errors.ETERM))
  assert_true(skt:close())
  assert_true(ctx:destroy())
end

function test_context_shutdown_autoclose()
  ctx = assert(is_zcontext(zmq.context()))
  if not ctx.shutdown then
    return skip("shutdown support since ZMQ 4.0.0")
  end

  skt = assert(is_zsocket(ctx:socket(zmq.SUB)))
  ctx:autoclose(skt)
  assert_true(ctx:shutdown())
  assert_true(skt:closed())
end

end

local _ENV = TEST_CASE'socket autoclose'     if ENABLE then

local ctx, skt

function setup() end

function teardown()
  if skt then skt:close()   end
  if ctx then ctx:destroy() end
end

function test_socket_autoclose()
  ctx = assert(is_zcontext(zmq.context()))
  skt = assert(is_zsocket(ctx:socket(zmq.SUB)))
  ctx:autoclose(skt)
  assert_equal(socket_count(ctx, 1))
  assert_true(ctx:destroy())
  assert_true(skt:closed())

  ctx = assert(is_zcontext(zmq.context()))
  local ptr
  do 
    local skt = assert(is_zsocket(ctx:socket(zmq.SUB)))
    assert_equal(socket_count(ctx, 1))
    ptr = weak_ptr(skt)
  end
  gc_collect()
  assert_nil(ptr.value)
  assert_equal(socket_count(ctx, 0))
  assert_true(ctx:destroy())

  ctx = assert(is_zcontext(zmq.context()))
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

function test_socket_autoclose_poller()
  ctx = assert(is_zcontext(zmq.context()))

  local poller = zpoller.new(1)
  local ptr
  do 
    local skt = assert(is_zsocket(ctx:socket(zmq.SUB)))
    assert_equal(socket_count(ctx, 1))

    poller:add(skt, zmq.POLLIN, function() end)
    poller:remove(skt)
    ptr = weak_ptr(skt)
  end
  gc_collect()
  assert_nil(ptr.value)
  assert_equal(socket_count(ctx, 0))
  assert_true(ctx:destroy())
end

end

local _ENV = TEST_CASE'message'              if ENABLE then

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
  msg = assert(is_zmessage(zmq.msg_init()))
  assert_true(msg:close())
  msg = assert(is_zmessage(zmq.msg_init_size(255)))
  assert_true(msg:close())
  msg = assert(is_zmessage(zmq.msg_init_data("Hello world!")))
  assert_true(msg:close())
end

function test_operations()
  local msg1
  local msg2
  local msg3

  msg1 = assert(is_zmessage(zmq.msg_init_size(10)))
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
  
  msg2 = assert(is_zmessage(zmq.msg_init()))
  assert_equal(msg2, msg2:move(msg1))

  assert_equal(0, msg1:size())
  assert_false(msg1:closed())
  assert_true(msg1:set_data('hi'))
  assert_equal(2, msg1:size())
  assert_equal('hi', msg1:data())
  assert_true(msg1:close())

  assert_equal(#data, msg2:size())
  assert_equal(data,  msg2:data())

  msg3 = assert(is_zmessage(zmq.msg_init()))
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
  
  msg1 = assert(is_zmessage(zmq.msg_init_data("hello world")))
  msg2 = assert(is_zmessage(msg1:copy())) -- copy to new object
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
  local msg = assert(is_zmessage(zmq.msg_init_data("Hello world!")))
  assert_equal("Hello world!", tostring(msg))
end

function test_pointer()
  local msg = assert(is_zmessage(zmq.msg_init_data("Hello world!")))
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
  local msg = assert(is_zmessage(zmq.msg_init_data("Hello world!")))
  assert_true(msg:set_size(5)) -- shrink
  assert_equal(5, msg:size())
  assert_equal("Hello", msg:data())
  assert_true(msg:set_size(10)) -- extend
  assert_equal(10, msg:size())
  local str = assert_string(msg:data())
  assert_equal("Hello", str:sub(1,5))
end

function test_setdata()
  local msg = assert(is_zmessage(zmq.msg_init_data("Hello world!")))
  assert_true(msg:set_data("Privet")) -- this is do not shrink message
  assert_equal(12, msg:size())
  assert_equal("Privetworld!", msg:data())
  assert_true(msg:set_data(7, " world!!!")) -- extend message
  assert_equal(15, msg:size())
  assert_equal("Privet world!!!", msg:data())
end

end

local _ENV = TEST_CASE'bind/connect'         if ENABLE then

local ctx, pub, sub1, sub2, sub3, msg

function setup()
  ctx = assert(is_zcontext(zmq.context()))
  pub = assert(is_zsocket(ctx:socket(zmq.PUB)))
  ctx:autoclose(pub)
  sub1 = assert(is_zsocket(ctx:socket(zmq.SUB)))
  ctx:autoclose(sub1)
  sub2 = assert(is_zsocket(ctx:socket(zmq.SUB)))
  ctx:autoclose(sub2)
  sub3 = assert(is_zsocket(ctx:socket(zmq.SUB)))
  ctx:autoclose(sub3)
  
  sub1:set_rcvtimeo(1000)
  sub2:set_rcvtimeo(1000)
  sub3:set_rcvtimeo(1000)
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

  -- do return end

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

function test_bind_random_port()
  local port1 = assert_number(pub:bind_to_random_port("tcp://127.0.0.1"))
  local port2 = assert_number(pub:bind_to_random_port("tcp://127.0.0.1"))
  assert_not_equal(port1, port2)
  wait()
  sub1:subscribe("")
  sub2:subscribe("")
  assert(sub1:connect("tcp://127.0.0.1:" .. port1))
  assert(sub2:connect("tcp://127.0.0.1:" .. port2))
  wait()
  
  assert(pub:send("HELLO"))
  assert_equal("HELLO", sub1:recv())
  assert_equal("HELLO", sub2:recv())
end

function test_bind_random_port_fail()
  assert_nil(pub:bind_to_random_port("tcp//127.0.0.1"))
  local port1 = assert_number(pub:bind_to_random_port("tcp://127.0.0.1"))
  assert_nil(pub:bind_to_random_port("tcp://127.0.0.1", port1, 1))
end

function test_bind_random_port_error()
  assert_error(function() pub:bind_to_random_port("tcp://127.0.0.1", 0) end)
  assert_error(function() pub:bind_to_random_port("tcp://127.0.0.1", 1, 0) end)
end

end

local _ENV = TEST_CASE'bind/connect on ctor' if ENABLE then

local ctx, pub, sub, msg

function setup()
  ctx = assert(is_zcontext(zmq.context()))
end

function teardown()
  if pub then pub:close()   end
  if sub then sub:close()   end
  if ctx then ctx:destroy() end
end

function test_connect()
  pub = assert(is_zsocket(ctx:socket(zmq.PUB,{
    bind = {
      "inproc://pub.test.1";
      "inproc://pub.test.2";
      "inproc://pub.test.3";
    };
  })))
  ctx:autoclose(pub)

  sub = assert(is_zsocket(ctx:socket(zmq.SUB,{
    subscribe = "", rcvtimeo = 100;
    connect = "inproc://pub.test.1";
  })))
  ctx:autoclose(sub)

  wait()

  assert_true(pub:send("hello"))
  assert_equal( "hello", assert_string(sub:recv()))
end

function test_fail_bind()
  local err, str
  pub, err, str = ctx:socket(zmq.PUB,{
    bind = {
      "inproc://pub.test.1";
      "inproc://pub.test.2";
      "inproc://pub.test.3";
      "error address"
    };
  })
  assert_nil(pub)
  assert_equal("error address", str)
  assert_equal(socket_count(ctx, 0))
end

end

local _ENV = TEST_CASE'Send Recv'            if ENABLE then

local ctx, pub, sub, msg

function setup()
  ctx = assert(is_zcontext(zmq.context()))
  pub = assert(is_zsocket(ctx:socket(zmq.PUB)))
  ctx:autoclose(pub)
  sub = assert(is_zsocket(ctx:socket(zmq.SUB)))
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

function test_recv_len_0()
  assert_true(pub:send(("0"):rep(32)))

  local str, more, len = assert_equal("", sub:recv_len(0))
  assert_false(more)
  assert_equal(32, len)
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
    msg = assert(is_zmessage(zmq.msg_init()))
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
    msg = assert(is_zmessage(zmq.msg_init_data('hello')))
    assert_true(msg:send_more(pub))
    assert_equal(0, msg:size())
    assert_false(msg:closed())
    assert_true(msg:close())
    assert_true(pub:send_more(", "))
    msg = assert(is_zmessage(zmq.msg_init_data('world')))
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
    assert(is_zmessage(msg2))
    assert_equal(', ', msg2:data())
    assert_true(more)
    assert_equal(more, sub:more())
    assert_equal(more, msg2:more())
    assert_equal(1, sub:rcvmore())

    local msg3 = assert(is_zmessage(zmq.msg_init()))
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

function test_recv_flags()
  sub:set_rcvtimeo(10000)
  local timer = assert(ztimer.monotonic():start())
  local ok, err = sub:recv(zmq.DONTWAIT)
  local elapsed = timer:stop()
  assert_nil(ok)
  assert(error_is(err, zmq.errors.EAGAIN))
  assert(elapsed < 100)
end

function test_recv_all_flags()
  sub:set_rcvtimeo(10000)
  local timer = assert(ztimer.monotonic():start())
  local ok, err = sub:recv_all(zmq.DONTWAIT)
  local elapsed = timer:stop()
  assert_nil(ok)
  assert(error_is(err, zmq.errors.EAGAIN))
  assert(elapsed < 100)
end

function test_sendx()
  assert_true(pub:sendx('hello', ', ', 'world'))
  local a,b,c = assert_string(sub:recvx())
  assert_string(b)
  assert_string(c)
  assert_equal('hello, world', a .. b .. c)
end

function test_sendv()
  assert_true(pub:sendv('hello', ', ', 'world'))
  local msg = assert_string(sub:recv())
  assert_equal('hello, world', msg)
end

function test_sendx_more()
  assert_true(pub:sendx_more('hello', ', '))
  assert_true(pub:send('world'))
  local a,b,c = assert_string(sub:recvx())
  assert_string(b)
  assert_string(c)
  assert_equal('hello, world', a .. b .. c)
end

function test_send_all_wrong_flag()
  local ok, err = pub:send_all({'hello', ', ', 'world'}, zmq.DONTWAIT)
  assert_nil(ok)
  assert(error_is(err, zmq.errors.ENOTSUP))
end

function test_send_all_more()
  assert_true(pub:send_all({'hello', ', '},zmq.SNDMORE))
  assert_true(pub:send('world'))
  local t = assert_table(sub:recv_all())
  assert_equal(3, #t)
  assert_equal('hello, world', table.concat(t))
end

function test_send_all_position()
  local msg = {
    [-1] = 'hello';
    [ 0] = ', ';
    [ 1] = 'world';
  }
  
  local ok, err = pub:send_all(msg, 0, -1, 1)
  local t = assert_table(sub:recv_all())
  assert_equal(3, #t)
  assert_equal('hello, world', table.concat(t))
end

function test_send_all_hole()
  assert_error(function()
    pub:send_all({"1", nil, "2"}, 0, 1, 3)
  end)
end

function test_sendx_hole()
  assert_error(function()
    pub:sendx("1", nil, "2")
  end)
end

end

local _ENV = TEST_CASE'socket poll'          if ENABLE then

local ctx, req, rep, timer

function setup()
  ctx   = assert(zmq.context())
  rep   = assert(ctx:socket{zmq.REP, bind = ECHO_ADDR, rcvtimeo = 100})
  req   = assert(ctx:socket{zmq.REQ, connect = ECHO_ADDR})
  timer = ztimer.monotonic()
end

function teardown()
  if ctx then ctx:destroy() end
  timer:close()
end

function test_timeout()
  timer:start()
  assert_false(rep:poll(2000))
  assert_true(ge(1900, timer:stop()))
end

function test_recv()
  req:send("HELLO")
  assert_true(rep:poll(2000))
  assert_equal("HELLO", rep:recv())
end

end

local _ENV = TEST_CASE'loop'                 if ENABLE then

local ctx, loop, timer

function setup()
  ctx   = assert(zmq.context())
  loop  = assert(zloop.new(ctx))
  timer = ztimer.monotonic()
end

function teardown()
  loop:destroy()
  assert_equal(socket_count(ctx, 0))
  ctx:destroy()
  timer:close()
  wait(500) -- for TCP time to release IP address
end

function test_context()
  assert_equal(ctx, loop:context())
end

function test_sleep()
  local flag1 = false
  loop:add_once(10, function() assert_false(flag1) flag1 = true end)
  assert_equal(0, loop:flush(100)) -- only flush io events and no wait
  assert_false(flag1)

  timer:start()
  assert_equal(1, loop:sleep_ex(100)) -- run event
  assert_true(ge(100, timer:stop()))  -- wait full interval
  assert_true(flag1)                  -- ensure event was emit

  flag1 = false
  loop:add_once(10, function() assert_false(flag1) flag1 = true end)
  timer:start()
  loop.sleep(100)                     -- do not run event
  assert_true(ge(100, timer:stop()))  -- wait full interval
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
  assert_true(ge(1990, timer:stop()))
  assert_true(counter > 3)

  loop:destroy()

  assert_true(cli:closed())
end

function test_autoclose_true()
  local cli = assert(loop:add_new_socket(zmq.REQ, function() end))
  loop:destroy(false)
  assert_true(cli:closed())
end

function test_autoclose_false()
  local cli = assert(loop:add_new_socket(zmq.REQ, function() end))
  loop:destroy(true)
  assert_false(cli:closed())
  cli:close()
end

end

local _ENV = TEST_CASE'timer'                if ENABLE then

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

local _ENV = TEST_CASE'poller'               if ENABLE then
local ctx, pub, sub1, sub2, sub3, msg
local poller
local names

function setup()
  ctx = assert(is_zcontext(zmq.context()))
  pub = assert(is_zsocket(ctx:socket(zmq.PUB)))
  ctx:autoclose(pub)
  sub1 = assert(is_zsocket(ctx:socket(zmq.SUB)))
  ctx:autoclose(sub1)
  sub2 = assert(is_zsocket(ctx:socket(zmq.SUB)))
  ctx:autoclose(sub2)
  sub3 = assert(is_zsocket(ctx:socket(zmq.SUB)))
  ctx:autoclose(sub3)
  poller = zpoller.new()

  names = {}
  names[sub1] = "sub1"
  names[sub2] = "sub2"
  names[sub3] = "sub3"

  assert_true(pub:bind("inproc://pub.test.1"))

  assert_true(sub1:subscribe(""))
  assert_true(sub2:subscribe(""))
  assert_true(sub3:subscribe(""))

  wait()

  assert_true(sub1:connect("inproc://pub.test.1"))
  assert_true(sub2:connect("inproc://pub.test.1"))
  assert_true(sub3:connect("inproc://pub.test.1"))

  wait()
end

function teardown()
  if msg then msg:close()               end
  if ctx then ctx:destroy()             end
  if pub then assert_true(pub:closed()) end
  if sub1 then assert_true(sub1:closed()) end
  if sub2 then assert_true(sub2:closed()) end
  if sub3 then assert_true(sub3:closed()) end
end

function test_poll_withot_timeout()
  poller:add(sub1, zmq.POLLIN, function() end)
  assert_error(function() poller:poll() end)
end

function test_add_error()
  assert_error(function() poller:add(sub1, zmq.POLLIN) end)
  assert_error(function() poller:add(sub1) end)
  assert_error(function() poller:add() end)
end

function test_create()
  local t = {}
  poller:add(sub1, zmq.POLLIN, function(skt) assert_equal(sub1, skt, " expect socket `sub1` got `" .. (names[skt] or tostring(skt))) t[skt] = {skt:recv()} end)
  poller:add(sub2, zmq.POLLIN, function(skt) assert_equal(sub2, skt, " expect socket `sub2` got `" .. (names[skt] or tostring(skt))) t[skt] = {skt:recv()} end)
  poller:add(sub3, zmq.POLLIN, function(skt) assert_equal(sub3, skt, " expect socket `sub3` got `" .. (names[skt] or tostring(skt))) t[skt] = {skt:recv()} end)

  assert_true(pub:send("hello"))

  assert_equal(3, poller:poll(100))
  local ret
  ret = t[sub1] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])
  ret = t[sub2] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])
  ret = t[sub3] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])
end

function test_remove()
  local t  = {}

  poller:add(sub1, zmq.POLLIN, function(skt) assert_equal(sub1, skt, " expect socket `sub1` got `" .. (names[skt] or tostring(skt))) t[skt] = {skt:recv()} end)
  poller:add(sub2, zmq.POLLIN, function(skt) fail("poller remove fail") end)
  poller:add(sub3, zmq.POLLIN, function(skt) fail("poller modify fail") end)

  poller:remove(sub2)
  poller:modify(sub3, zmq.POLLIN, function(skt) assert_equal(sub3, skt, " expect socket `sub3` got `" .. (names[skt] or tostring(skt))) t[skt] = {skt:recv()} end)

  assert_true(pub:send("hello"))

  assert_equal(2, poller:poll(100))
  local ret
  ret = t[sub1] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])
  ret = t[sub3] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])
end

function test_remove_on_poll()
  local t  = {}

  poller:add(sub1, zmq.POLLIN, function(skt) assert_equal(sub1, skt, " expect socket `sub1` got `" .. (names[skt] or tostring(skt)) .. "`") t[skt] = {skt:recv()} end)
  poller:add(sub2, zmq.POLLIN, function(skt) assert_equal(sub2, skt, " expect socket `sub2` got `" .. (names[skt] or tostring(skt)) .. "`") t[skt] = {skt:recv()} poller:remove(skt) end)
  poller:add(sub3, zmq.POLLIN, function(skt) assert_equal(sub3, skt, " expect socket `sub3` got `" .. (names[skt] or tostring(skt)) .. "`") t[skt] = {skt:recv()} end)

  assert_true(pub:send("hello"))

  assert_equal(3, poller:poll(100))
  local ret
  ret = t[sub1] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])
  ret = t[sub2] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])
  ret = t[sub3] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])
end

function test_pollable_interface()
  local function wrap(s)
    return {
      socket = function (self) return s        end;
      recv   = function (self) return s:recv() end;
    }
  end

  local sub1 = wrap(sub1)
  local sub2 = wrap(sub2)
  local sub3 = wrap(sub3)

  local t = {}
  poller:add(sub1, zmq.POLLIN, function(skt) assert_equal(sub1, skt, " expect socket `sub1` got `" .. (names[skt] or tostring(skt))) t[skt] = {skt:recv()} end)
  poller:add(sub2, zmq.POLLIN, function(skt) assert_equal(sub2, skt, " expect socket `sub2` got `" .. (names[skt] or tostring(skt))) t[skt] = {skt:recv()} end)
  poller:add(sub3, zmq.POLLIN, function(skt) assert_equal(sub3, skt, " expect socket `sub3` got `" .. (names[skt] or tostring(skt))) t[skt] = {skt:recv()} end)

  assert_true(pub:send("hello"))

  assert_equal(3, poller:poll(100))
  local ret
  ret = t[sub1] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])
  ret = t[sub2] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])
  ret = t[sub3] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])

  poller:remove(sub2)

  assert_true(pub:send("hello"))

  assert_equal(2, poller:poll(100))

  ret = t[sub1] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])
  ret = t[sub3] assert_table(ret) assert_equal("hello", ret[1]) assert_equal(false, ret[2])
end

end

local _ENV = TEST_CASE'z85 encode'           if ENABLE then
if not zmq.z85_encode then test = SKIP"zmq_z85_encode does not support" else

local key_bin = "\084\252\186\036\233\050\073\150\147\022\251\097\124\135\043\176" ..
                "\193\209\255\020\128\004\039\197\148\203\250\207\027\194\214\082"

local key_txt = "rq:rM>}U?@Lns47E1%kR.o@n%FcmmsL/@{H8]yf7";

local function dump(str)
  return (string.gsub(str,".", function(ch)
    return (string.format("\\%.3d", string.byte(ch)))
  end))
end

function test_encode()
  local encoded = assert_string(zmq.z85_encode(key_bin))
  assert_equal(key_txt, encoded)
end

local function encoden(str, n) return zmq.z85_encode(str:rep(n)) end

local function decoden(str, n) return zmq.z85_decode(str:rep(n)) end

function test_encodeN()
  local encoded = assert_string(encoden(key_bin, 100))
  assert_equal(key_txt:rep(100), encoded)

  local encoded = assert_string(encoden(key_bin, 1000))
  assert_equal(key_txt:rep(1000), encoded)
end

function test_decode()
  local decoded = assert_string(zmq.z85_decode(key_txt))
  assert_equal(dump(key_bin), dump(decoded))
end

function test_decodeN()
  local decoded = assert_string(decoden(key_txt, 100))
  assert_equal(dump(key_bin:rep(100)), dump(decoded))

  local decoded = assert_string(decoden(key_txt, 1000))
  assert_equal(dump(key_bin:rep(1000)), dump(decoded))
end

function test_encode_wrong_size()
  assert_error(function() zmq.z85_encode(key_bin .. "1") end)
end

function test_decode_wrong_size()
  assert_error(function() zmq.z85_decode(key_txt .. "2") end)
end

end
end

local _ENV = TEST_CASE'curve keypair'        if ENABLE then
if not zmq.curve_keypair then test = SKIP"zmq_curve_keypair does not support" else

function test_generate_z85()
  local pub, sec = zmq.curve_keypair()
  if not pub then
    assert(error_is(sec, zmq.errors.ENOTSUP))
    return skip("you need build libzmq with libsodium")
  end
  assert_string(pub)
  assert_string(sec)
  assert_equal(40, #pub)
  assert_equal(40, #sec)
end

function test_generate_bin()
  local pub, sec = zmq.curve_keypair(true)
  if not pub then
    assert(error_is(sec, zmq.errors.ENOTSUP))
    return skip("you need build libzmq with libsodium")
  end
  assert_string(pub)
  assert_string(sec)
  assert_equal(32, #pub)
  assert_equal(32, #sec)
end

end
end

local _ENV = TEST_CASE'monitor'              if ENABLE then

local ctx, loop, timer, srv, mon

function setup()
  ctx   = assert(zmq.context())
  loop  = assert(zloop.new(ctx))
  timer = ztimer.monotonic()
end

function teardown()
  if srv then srv:close() end
  if mon then mon:close() end
  loop:destroy()
  assert_equal(socket_count(ctx, 0))
  ctx:destroy()
  wait(500) -- for TCP time to release IP address
end

function test_monitor()
  local counter = 0
  local monitor_called = false
  local address = "<NOT ACCEPTED>"

  local function echo(skt)
    local msg = assert_table(skt:recv_all())
    assert_true(skt:send_all(msg))
    counter = counter + 1
  end

  local srv = assert(is_zsocket(loop:create_socket(zmq.REP, {
    linger = 0, sndtimeo = 100, rcvtimeo = 100;
    bind = {
      "inproc://test.zmq";
      "tcp://*:9000";
    }
  })))
  loop:add_socket(srv, echo)

  if not srv.monitor then
    return skip("this version of LZMQ does not support socket monitor")
  end

  if not srv.recv_event then
    return skip("this version of LZMQ does not support receive event")
  end

  local monitor_endpoint = assert_string(srv:monitor())

  assert(is_zsocket(loop:add_new_connect(zmq.PAIR, monitor_endpoint, function(sok)
    monitor_called = true
    local event, data, addr = sok:recv_event()
    assert_number(event, data)
    assert_number(data)
    if addr then assert_string(addr) end

    if event == zmq.EVENT_ACCEPTED then
      address = addr
    end
  end)))

  wait()

  local cli = assert(is_zsocket(loop:create_socket(zmq.REQ, {
    linger = 0, sndtimeo = 100, rcvtimeo = 100;
    connect = "tcp://127.0.0.1:9000";
  })))
  loop:add_socket(cli, echo)

  -- run ball
  loop:add_once(10, function() cli:send_all{'hello', 'world'} end)

  -- time to play
  loop:add_once(500, function() loop:interrupt() end)

  loop:start()

  loop:destroy()

  assert_true(monitor_called)
  assert_string(address)
  assert_match("^tcp://%d+%.%d+%.%d+%.%d+:%d+$", address)
end

function test_monitor_with_addr()
  srv = assert(is_zsocket(loop:create_socket(zmq.REP)))
  if not srv.monitor then
    return skip("this version of LZMQ does not support socket monitor")
  end

  local addr = "inproc://lzmq.monitor.test"
  assert_equal(addr, srv:monitor(addr))
end

function test_monitor_with_wrong_addr()
  srv = assert(is_zsocket(loop:create_socket(zmq.REP)))
  if not srv.monitor then
    return skip("this version of LZMQ does not support socket monitor")
  end

  local addr = "lzmq.monitor.test"
  local ok, err = srv:monitor(addr)
  assert_nil(ok)
  assert(error_is(err, zmq.errors.EINVAL))
end

function test_monitor_without_addr()
  srv = assert(is_zsocket(loop:create_socket(zmq.REP)))
  if not srv.monitor then
    return skip("this version of LZMQ does not support socket monitor")
  end

  assert_match("^inproc://lzmq%.monitor%.[0-9a-fA-FxX]+$", srv:monitor())
end

function test_monitor_without_addr_with_event()
  srv = assert(is_zsocket(loop:create_socket(zmq.REP)))
  if not srv.monitor then
    return skip("this version of LZMQ does not support socket monitor")
  end

  assert_match("^inproc://lzmq%.monitor%.[0-9a-fA-FxX]+$", srv:monitor(1))
end

function test_reset_monitor()
  srv = assert(is_zsocket(loop:create_socket{zmq.REP,
    linger = 0, sndtimeo = 100, rcvtimeo = 100;
    bind = {
      "inproc://test.zmq";
      "tcp://*:9000";
    }
  }))

  if not srv.reset_monitor then
    return skip("this version of LZMQ does not support socket reset_monitor")
  end

  mon = assert(is_zsocket(loop:create_socket{zmq.PAIR, 
    linger = 0, sndtimeo = 100, rcvtimeo = 100;
    connect = assert(srv:monitor());
  }))

  srv:bind_to_random_port("tcp://127.0.0.1")
  ztimer.sleep(500)

  local ev, info = assert_number(mon:recv_event())
  assert_equal(zmq.EVENT_LISTENING, ev)

  assert(srv:reset_monitor())
  if zmq.version(true) >= 4 then
    local ev = assert_number(mon:recv_event())
    assert_equal(zmq.EVENT_MONITOR_STOPPED, ev)
  else
    local ev, err = assert_nil(mon:recv_event())
    assert(error_is(err, zmq.errors.EAGAIN))
  end

  srv:bind_to_random_port("tcp://127.0.0.1")
  ztimer.sleep(500)

  local ev, err = assert_nil(mon:recv_event())
  assert(error_is(err, zmq.errors.EAGAIN))
end

end

local _ENV = TEST_CASE'Clone socket'         if ENABLE then

local ctx, rep, s1, s2

function setup()
  ctx = assert(is_zcontext(zmq.context()))
  rep = assert(is_zsocket(ctx:socket{zmq.REP, bind    = ECHO_ADDR}))
  s1  = assert(is_zsocket(ctx:socket{zmq.REQ, connect = ECHO_ADDR}))
  wait()
end

function teardown()
  if rep then rep:close() end
  if ctx then ctx:destroy() end
end

function test_lightuserdata()
  local h = assert(s1:lightuserdata())
end

function test_wrap_socket()
  local h = assert(s1:lightuserdata())
  s2 =  assert(is_zsocket(zmq.init_socket(h)))
  assert_nil(s2:context())
  assert_equal(socket_count(ctx, 2))
end

function test_send_recv()
  local h = assert(s1:lightuserdata())
  s2 =  assert(is_zsocket(zmq.init_socket(h)))
  assert_true(s1:send("hello"))
  assert_equal("hello", rep:recv())
  assert_true(rep:send("world"))
  assert_equal("world", s2:recv())
end

function test_swap()
  local h1 = assert(s1:lightuserdata())
  local h2 = assert(rep:reset_handle(h1))
  assert_equal(h1, s1:reset_handle(h2))

  assert_true(rep:send("hello"))
  assert_equal("hello", s1:recv())
  assert_true(s1:send("world"))
  assert_equal("world", rep:recv())
end

function test_reset_handle()
  local h1 = assert(s1:lightuserdata())
  assert_error(function() rep:reset_handle() end)
  assert_true(rep:reset_handle(h1, false, true)) -- close handle
end

function test_reset_handle_own()
  local h1 = assert(s1:lightuserdata())
  local h2 = assert(rep:reset_handle(h1, false)) -- do not close h1 after rep:close()
  assert_true(rep:close())

  -- anchor h2 to socket
  rep = zmq.init_socket(h2)
  rep:reset_handle(h2, true)

  assert_true(s1:bind("inproc://test"))
end

function test_reset_handle_nochange_own()
  local h1 = assert(s1:lightuserdata())
  local h2 = assert(rep:reset_handle(h1)) -- by default rep close handle on `close` method
  assert_true(rep:close())

  assert_nil(s1:bind("inproc://test"))

  -- close h2
  s1:reset_handle(h2, true)
end

function test_reset_handle_nochange2_own()
  local h1 = assert(s1:lightuserdata())
  local h2 = assert(rep:reset_handle(h1, false)) -- do not close h1 after rep:close()
  assert(rep:reset_handle(h1))                   -- do not change on_close bihavior

  assert_true(rep:close())

  -- anchor h2 to socket
  rep = zmq.init_socket(h2)
  rep:reset_handle(h2, true)

  assert_true(s1:bind("inproc://test"))
end

end

local _ENV = TEST_CASE'Recv event'           if ENABLE then

local ctx, skt, mon
local timeout, epselon = 1500, 490

function setup()
  ctx = assert(is_zcontext(zmq.context()))
  skt = assert(is_zsocket(ctx:socket(zmq.PUB)))
  local monitor_endpoint = assert_string(skt:monitor())
  mon = assert(is_zsocket(ctx:socket{zmq.PAIR,
    rcvtimeo = timeout, connect = monitor_endpoint
  }))
end

function teardown()
  if ctx then ctx:destroy()             end
end

function test()
  local timer = ztimer.monotonic():start()
  assert_nil( mon:recv_event() )
  local elapsed = timer:stop()
  assert(elapsed > (timeout-epselon), "Expeted " .. timeout .. "(+/-" .. epselon .. ") got: " .. elapsed)
  assert(elapsed < (timeout+epselon), "Expeted " .. timeout .. "(+/-" .. epselon .. ") got: " .. elapsed)

  timer:start()
  assert_nil( mon:recv_event(zmq.DONTWAIT) )
  elapsed = timer:stop()
  assert(elapsed < (epselon), "Expeted less then " .. epselon .. " got: " .. elapsed)
end

end

local _ENV = TEST_CASE'Socket optinos'       if ENABLE then

local ctx, srv, cli

function setup()
  ctx = assert(is_zcontext(zmq.context()))
  srv = assert(is_zsocket(ctx:socket{zmq.ROUTER, linger = 0}))
  local port = assert_number(srv:bind_to_random_port("tcp://127.0.0.1"))
  cli = assert(is_zsocket(ctx:socket{zmq.REQ, connect = "tcp://127.0.0.1:" .. port, linger = 0}))
end

function teardown()
  ctx:destroy()
end

function test_identity_fd()
  if not srv.identity_fd then
    return skip("ZMQ_IDENTITY_FD support since ZMQ 4.1.0")
  end

  assert_number(cli:fd())
  assert_error(function() srv:identity_fd() end)

  cli:send("hello")
  local id, empty, msg = assert_string(srv:recvx())

  assert_equal("", empty)
  assert_equal("hello", msg)

  assert_number(srv:identity_fd(id))
end

function test_has_event()
  assert_false(cli:has_event(zmq.POLLIN))
  assert_true(cli:has_event(zmq.POLLOUT))
  local _, event = assert_false(cli:has_event(zmq.POLLIN, zmq.POLLOUT))
  assert_true(event)

  assert_true(cli:send("hello"))

  wait(100)

  assert_false(cli:has_event(zmq.POLLIN))
  assert_false(cli:has_event(zmq.POLLOUT))

  local msg = assert_table(srv:recv_all())
  assert_true(srv:send_all(msg))

  wait(100)

  assert_true(cli:has_event(zmq.POLLIN))
  assert_false(cli:has_event(zmq.POLLOUT))
end

end

if not HAS_RUNNER then lunit.run() end