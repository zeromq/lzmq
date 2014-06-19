--
-- zmq.thread wraps the low-level threads object & a zmq context.
--

local zthreads_prelude = function(ZMQ_NAME, parent_ctx, ...)
  local table    = require "table"
  local zmq      = require(ZMQ_NAME)
  local zthreads = require(ZMQ_NAME .. ".threads")
  local unpack   = table.unpack or unpack

  if parent_ctx then zthreads.set_parent_ctx(zmq.init_ctx(parent_ctx)) end

  return ...
end

local fork_prelude = function(ZMQ_NAME, parent_ctx, endpoint, ...)
  local table    = require "table"
  local zmq      = require(ZMQ_NAME)
  local zthreads = require(ZMQ_NAME .. ".threads")
  local unpack   = table.unpack or unpack

  assert(parent_ctx)
  assert(endpoint)

  parent_ctx = zmq.init_ctx(parent_ctx)
  zthreads.set_parent_ctx(parent_ctx)

  local pipe = zmq.assert(parent_ctx:socket{zmq.PAIR, connect = endpoint})
  return pipe, ...
end

local function rand_bytes(n)
  local t = {}
  for i = 1, n do t[i] = string.char( math.random(string.byte('a'), string.byte('z')) ) end
  return table.concat(t)
end

local string  = require"string"
local Threads = require"lzmq.llthreads.ex"
return function(ZMQ_NAME)

local zmq = require(ZMQ_NAME)

local prelude = zthreads_prelude

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
  return Threads.run_ex(prelude, code, ZMQ_NAME, ctx, ...)
end

function zthreads.fork(ctx, code, ...)
  local pipe, endpoint = make_pipe(ctx)
  if not pipe then return nil, endpoint end

  ctx = ctx:lightuserdata()
  local ok, err = Threads.run_ex(fork_prelude, code, ZMQ_NAME, ctx, endpoint, ...)
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
