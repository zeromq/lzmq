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

local function rand_bytes(n)
	local t = {}
	for i = 1, n do table.insert(t, string.char(math.random(256)-1)) end
	return table.concat(t)
end

local string  = require"string"
local Threads = require"lzmq.llthreads.ex"
return function(ZMQ_NAME)

local zmq = require(ZMQ_NAME)

local zthreads_prelude = [[
local zmq = require(]] .. ("%q"):format(ZMQ_NAME) .. [[)
local zthreads = require(]] .. ("%q"):format(ZMQ_NAME) .. [[ .. ".threads")
local parent_ctx = arg[1]
if parent_ctx then zthreads.set_parent_ctx(zmq.init_ctx(parent_ctx)) end
local unpack = table.unpack or unpack
arg = {n = arg.n - 1, unpack(arg, 2, arg.n) }
]]

local fork_prelude = [[
arg[1] = zmq.assert(zthreads.get_parent_ctx():socket(zmq.PAIR,{
	connect = assert(arg[1]);
}))
]]

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

local M = {}

function M.set_bootstrap_prelude (code)
	prelude = code .. zthreads_prelude
end;

function M.runfile(ctx, file, ...)
	if ctx then ctx = ctx:lightuserdata() end
	return Threads.runfile_ex(prelude, file, ctx, ...)
end

function M.runstring(ctx, code, ...)
	if ctx then ctx = ctx:lightuserdata() end
	return Threads.runstring_ex(prelude, code, ctx, ...)
end

function M.run(ctx, code, ...)
	if string.sub(code, 1, 1) == '@' then
		return M.runfile(ctx, string.sub(code, 2), ...)
	end
	return M.runstring(ctx, code, ...)
end

function M.forkstring(ctx, code, ...)
	local pipe, endpoint = make_pipe(ctx)
	if not pipe then return nil, endpoint end
	ctx = ctx:lightuserdata()
	local ok, err = Threads.runstring_ex(prelude .. fork_prelude, code, ctx, endpoint, ...)
	if not ok then
		pipe:close()
		return nil, err
	end
	return ok, pipe
end

function M.forkfile(ctx, file, ...)
	local pipe, endpoint = make_pipe(ctx)
	if not pipe then return nil, endpoint end
	ctx = ctx:lightuserdata()
	local ok, err = Threads.runfile_ex(prelude .. fork_prelude, file, ctx, endpoint, ...)
	if not ok then
		pipe:close()
		return nil, err
	end
	return ok, pipe
end

function M.fork(ctx, code, ...)
	if string.sub(code, 1, 1) == '@' then
		return M.forkfile(ctx, string.sub(code, 2), ...)
	end
	return M.forkstring(ctx, code, ...)
end

local parent_ctx = nil
function M.set_parent_ctx(ctx)
	parent_ctx = ctx
end

function M.get_parent_ctx(ctx)
	return parent_ctx
end

return M

end