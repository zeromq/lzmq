function vc_version()
  local VER = lake.compiler_version()
  MSVC_VER = ({
    [15] = '9';
    [16] = '10';
  })[VER.MAJOR] or ''
  return MSVC_VER
end

local function arkey(t)
  assert(type(t) == 'table')
  local keys = {}
  for k in pairs(t) do
    assert(type(k) == 'number')
    table.insert(keys, k)
  end
  table.sort(keys)
  return keys
end

local function ikeys(t)
  local keys = arkey(t)
  local i = 0
  return function()
    i = i + 1
    local k = keys[i]
    if k == nil then return end
    return k, t[k]
  end
end

local function expand(arr, t)
  if t == nil then return arr end

  if type(t) ~= 'table' then
    table.insert(arr, t)
    return arr
  end

  for _, v in ikeys(t) do
    expand(arr, v)
  end

  return arr
end

function L(...)
  return expand({}, {...})
end

J = J or path.join

IF = IF or lake.choose or choose

function prequire(...)
  local ok, mod = pcall(require, ...)
  if ok then return mod end
end

function each_join(dir, list)
  for i, v in ipairs(list) do
    list[i] = path.join(dir, v)
  end
  return list
end

function run(file, cwd)
  print()
  print("run " .. file)
  if not TESTING then
    if cwd then lake.chdir(cwd) end
    local status, code = utils.execute( LUA_RUNNER .. ' ' .. file )
    if cwd then lake.chdir("<") end
    print()
    return status, code
  end
  return true, 0
end

function run_test(name, params)
  local test_dir = J(ROOT, 'test')
  local cmd = J(test_dir, name)
  if params then cmd = cmd .. ' ' .. params end
  local ok = run(cmd, test_dir)
  print("TEST " .. cmd .. (ok and ' - pass!' or ' - fail!'))
end

function spawn(file, cwd)
  local winapi = prequire "winapi"
  if not winapi then
    print(file, ' error: Test needs winapi!')
    return false
  end
  print("spawn " .. file)
  if not TESTING then
    if cwd then lake.chdir(cwd) end
    assert(winapi.shell_exec(nil, LUA_RUNNER, file, cwd))
    if cwd then lake.chdir("<") end
    print()
  end
  return true
end

function as_bool(v,d)
  if v == nil then return not not d end
  local n = tonumber(v)
  if n == 0 then return false end
  if n then return true end
  return false
end

run_lua = run

spawn_lua = spawn

function test_perf_r(perf_type, opt)
  return function()
    if not winapi then quit('perf target needs winapi') end

    local path = J(ROOT,'examples','perf')
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

    local path = J(ROOT,'examples','perf')
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
    local path = J(ROOT,'examples','perf')
    print("run " .. J(path,'thread_'  .. perf_type .. '.lua') .. ' ' .. opt)

    if not TESTING then
      run_lua  (J(path,'thread_'  .. perf_type .. '.lua') .. ' ' .. opt, path)
    end
  end
end

-----------------------
-- needs --
-----------------------

lake.define_need('lua53', function()
  return {
    incdir = J(ENV.LUA_DIR_5_3, 'include');
    libdir = J(ENV.LUA_DIR_5_3, 'lib');
    libs   = {'lua53'};
  }
end)

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
    libs   = {'libzmq'};
  }
end)

lake.define_need('zmq4', function()
  return {
    incdir = J(ENV.ZMQ4_DIR, 'include');
    libdir = J(ENV.ZMQ4_DIR, 'lib');
    libs   = {'libzmq'};
  }
end)

lake.define_need('stdint', function()
  if not MSVC then return {} end
  return {
    incdir = J(ENV.CPPLIB_DIR, 'msvc');
  }
end)
