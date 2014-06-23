--
-- zmq.thread wraps the low-level threads object & a zmq context.
--

local T = string.dump

local run_starter = {
  prelude = T(function(ZMQ_NAME, ctx, ...)
    local zmq      = require(ZMQ_NAME)
    local zthreads = require(ZMQ_NAME .. ".threads")

    if ctx then
      ctx = zmq.init_ctx(ctx)
      zthreads.set_context(ctx)
    end

    return ...
  end)
}

local fork_starter = {
  prelude = T(function(ZMQ_NAME, ctx, endpoint, ...)
    local zmq      = require(ZMQ_NAME)
    local zthreads = require(ZMQ_NAME .. ".threads")

    assert(ctx)
    assert(endpoint)

    ctx = zmq.init_ctx(ctx)
    zthreads.set_context(ctx)

    local pipe = zmq.assert(ctx:socket{zmq.PAIR, connect = endpoint})
    return pipe, ...
  end)
}

local function rand_bytes(n)
  local t = {}
  for i = 1, n do t[i] = string.char( math.random(string.byte('a'), string.byte('z')) ) end
  return table.concat(t)
end

local string  = require"string"
local Threads = require"lzmq.llthreads.ex"
return function(ZMQ_NAME)

local zmq = require(ZMQ_NAME)

local function make_pipe(ctx)
  local pipe = ctx:socket(zmq.PAIR)
  local pipe_endpoint = "inproc://lzmq.pipe." .. pipe:fd() .. "." .. rand_bytes(10);
  local ok, err = pipe:bind(pipe_endpoint)
  if not ok then 
    pipe:close()
    return nil, err
  end
  return pipe, pipe_endpoint
end

local zthreads = {}

function zthreads.run(ctx, code, ...)
  if ctx then ctx = ctx:lightuserdata() end
  run_starter.source = code
  return Threads.new(run_starter, ZMQ_NAME, ctx, ...)
end

function zthreads.fork(ctx, code, ...)
  local pipe, endpoint = make_pipe(ctx)
  if not pipe then return nil, endpoint end

  ctx = ctx:lightuserdata()
  fork_starter.source = code
  local ok, err = Threads.new(fork_starter, ZMQ_NAME, ctx, endpoint, ...)
  if not ok then
    pipe:close()
    return nil, err
  end
  return ok, pipe
end

local parent_ctx = nil
function zthreads.set_parent_ctx(ctx)
  parent_ctx = ctx
end

function zthreads.get_parent_ctx()
  return parent_ctx
end

zthreads.context = zthreads.get_parent_ctx

zthreads.set_context = zthreads.set_parent_ctx

return zthreads

end
