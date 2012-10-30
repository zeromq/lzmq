J  = J or path.join
IF = IF or lake.choose or choose

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

