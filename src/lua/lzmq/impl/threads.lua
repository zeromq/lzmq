--
--  Author: Alexey Melnichuk <mimir@newmail.ru>
--
--  Copyright (C) 2013-2014 Alexey Melnichuk <mimir@newmail.ru>
--
--  Licensed according to the included 'LICENCE' document
--
--  This file is part of lua-lzqm library.
--

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

local actor_mt = {} do

actor_mt.__index = function(self, k)
  local v = actor_mt[k]
  if v ~= nil then
    return v
  end

  v = self._thread[k]
  if v ~= nil then
    local f = function(self, ...) return self._thread[k](self._thread, ...) end
    self[k] = f
    return f
  end

  v = self._pipe[k]
  if v ~= nil then
    local f = function(self, ...) return self._pipe[k](self._pipe, ...) end
    self[k] = f
    return f
  end
end

function actor_mt:start(...)
  local ok, err = self._thread:start(...)
  if not ok then return nil, err end
  return self, err
end

function actor_mt:socket()
  return self._pipe
end

function actor_mt:close()
  self._pipe:close()
  self._thread:join()
end

end

local function actor_new(thread, pipe)
  local o = setmetatable({
    _thread = thread;
    _pipe   = pipe;
  }, actor_mt)

  return o
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

function zthreads.actor(...)
  local thread, pipe = zthreads.fork(...)
  if not thread then return nil, pipe end

  return actor_new(thread, pipe)
end

function zthreads.xrun(...)
  return zthreads.run(zthreads.context(), ...)
end

function zthreads.xfork(...)
  return zthreads.fork(zthreads.context(), ...)
end

function zthreads.xactor(...)
  return zthreads.actor(zthreads.context(), ...)
end

local global_context = nil
function zthreads.set_context(ctx)
  assert(ctx)

  if global_context == ctx then return end

  assert(global_context == nil, 'global_context already setted')

  global_context = ctx
end

function zthreads.context()
  if not global_context then global_context = zmq.assert(zmq.context()) end
  return global_context
end

-- compatibility functions

zthreads.get_parent_ctx = zthreads.context

zthreads.set_parent_ctx = zthreads.set_context

return zthreads

end
