J  = J or path.join
IF = IF or lake.choose or choose

function as_bool(v,d)
  if v == nil then return not not d end
  local n = tonumber(v)
  if n == 0 then return false end
  if n then return true end
  return false
end

function spawn_lua(file, dir)
  winapi.shell_exec(nil, LUA_RUNNER, file, dir)
end

function run_lua(file, dir)
  lake.chdir(dir)
  os.execute(LUA_RUNNER .. ' ' .. file)
  lake.chdir('<')
end

function test_perf_r(perf_type, opt)
  return function()
    if not winapi then quit('perf target needs winapi') end

    local path = J(INSTALL_DIR,'examples','perf')
    print("run " .. J(path,'local_'  .. perf_type .. '.lua') .. ' ' .. opt)
    print("run " .. J(path,'remote_' .. perf_type .. '.lua') .. ' ' .. opt)

    if not TESTING then
      spawn_lua(J(path,'local_'   .. perf_type .. '.lua') .. ' ' .. opt, path)
      run_lua  (J(path,'remote_'  .. perf_type .. '.lua') .. ' ' .. opt, path)
    end
  end
end

function test_perf_l(perf_type, opt)
  return function()
    if not winapi then quit('perf target needs winapi') end

    local path = J(INSTALL_DIR,'examples','perf')
    print("run " .. J(path,'local_'  .. perf_type .. '.lua') .. ' ' .. opt)
    print("run " .. J(path,'remote_' .. perf_type .. '.lua') .. ' ' .. opt)

    if not TESTING then
      spawn_lua(J(path,'remote_' .. perf_type .. '.lua') .. ' ' .. opt, path)
      run_lua  (J(path,'local_'  .. perf_type .. '.lua') .. ' ' .. opt, path)
    end
  end
end

function test_perf_t(perf_type, opt)
  return function()
    local path = J(INSTALL_DIR,'examples','perf')
    print("run " .. J(path,'thread_'  .. perf_type .. '.lua') .. ' ' .. opt)

    if not TESTING then
      run_lua  (J(path,'thread_'  .. perf_type .. '.lua') .. ' ' .. opt, path)
    end
  end
end

lake.define_need('lua52', function()
  return {
    incdir = J(ENV.LUA_DIR_5_2, 'include');
    libdir = J(ENV.LUA_DIR_5_2, 'lib');
    libs   = {'lua52'};
  }
end)

lake.define_need('lua51', function()
  return {
    incdir = J(ENV.LUA_DIR, 'include');
    libdir = J(ENV.LUA_DIR, 'lib');
    libs   = {'lua5.1'};
  }
end)

lake.define_need('zmq3', function()
  return {
    incdir = J(ENV.ZMQ3_DIR, 'include');
    libdir = J(ENV.ZMQ3_DIR, 'lib');
    libs   = {'libzmq3'};
  }
end)

lake.define_need('stdint', function()
  if not MSVC then return {} end
  return {
    incdir = J(ENV.CPPLIB_DIR, 'msvc');
  }
end)
