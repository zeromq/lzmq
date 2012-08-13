-- Copyright (c) 2010 Aleksey Yeschenko <aleksey@yeschenko.com>
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

if not arg[3] then
    print("usage: lua remote_lat.lua <connect-to> <message-size> <roundtrip-count>")
    os.exit()
end

local connect_to = arg[1]
local message_size = tonumber(arg[2])
local roundtrip_count = tonumber(arg[3])

local zmq = require"lzmq"
local assert = zmq.assert


local ctx = zmq.init(1)
local s = ctx:socket(zmq.REQ)
assert(s:set_sndhwm(roundtrip_count + 1))
assert(s:set_rcvhwm(roundtrip_count + 1))
assert(s:connect(connect_to))

local data = ("0"):rep(message_size)
local msg = zmq.msg_init_size(message_size)

zmq.utils.sleep(1)

local timer = zmq.utils.stopwatch():start()

for i = 1, roundtrip_count do
	assert(s:send_msg(msg))
	assert(s:recv_msg(msg))
	assert(msg:size() == message_size, "Invalid message size")
end

local elapsed = timer:stop()

s:close()
ctx:term()

local latency = elapsed / roundtrip_count / 2

print(string.format("message size: %i [B]", message_size))
print(string.format("roundtrip count: %i", roundtrip_count))
print(string.format("mean latency: %.3f [us]", latency))
