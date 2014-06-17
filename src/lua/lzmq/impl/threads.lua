-- Copyright (c) 2011 by Robert G. Jakabosky <bobby@sharedrealm.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

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

function zthreads.get_parent_ctx(ctx)
  return parent_ctx
end

return zthreads

end
