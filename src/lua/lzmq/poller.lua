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
-- zmq.poller wraps the low-level zmq.ZMQ_Poller object.
--
-- This wrapper simplifies the event polling loop.
--

local zmq = require"lzmq"

local setmetatable = setmetatable
local tonumber = tonumber
local assert = assert
local Poller = zmq.poller2 or zmq.poller

local poller_mt = {}
poller_mt.__index = poller_mt

local function raw_socket(sock)
	return (type(sock) == 'table') and (sock.socket) and sock:socket() or sock
end

-- add
if Poller == zmq.poller2 then

function poller_mt:add(sock, events, cb)
	assert(cb ~= nil)
	local s = raw_socket(sock)
	if self.poller:add(s, events) then
		self.callbacks[s] = function(revents) return cb(sock, revents) end
	end
end

else

function poller_mt:add(sock, events, cb)
	assert(cb ~= nil)
	local s = raw_socket(sock)
	local id = self.poller:add(s, events)
	self.callbacks[id] = function(revents) return cb(sock, revents) end
end

end

-- modify
if Poller == zmq.poller2 then

function poller_mt:modify(sock, events, cb)
	if events ~= 0 and cb then
		local s = raw_socket(sock)
		self.poller:modify(s, events)
		self.callbacks[s] = function(revents) return cb(sock, revents) end
	else
		self:remove(sock)
	end
end

else

function poller_mt:modify(sock, events, cb)
	if events ~= 0 and cb then
		local id = self.poller:modify(raw_socket(sock), events)
		self.callbacks[id] = function(revents) return cb(sock, revents) end
	else
		self:remove(sock)
	end
end

end

-- remove
if Poller == zmq.poller2 then

function poller_mt:remove(sock)
	local s = raw_socket(sock)
	self.poller:remove(s)
	self.callbacks[s] = nil
end

else

function poller_mt:remove(sock)
	local id = self.poller:remove(raw_socket(sock))
	assert(id <= #self.callbacks)
	for i = id, #self.callbacks do
		self.callbacks[i] = self.callbacks[i+1]
	end
end

end

-- poll
if Poller == zmq.poller2 then

-- based on poll
function poller_mt:poll(timeout)
	local poller, callbacks, count = self.poller, self.callbacks, 0
	local n = poller:count()
	for i = 1, n do
		local socket, revents = poller:poll(timeout)
		if socket == nil then
			return nil, revents
		end
		if false == socket then
			break
		end
		count, timeout = count + 1, 0
		local cb = callbacks[socket]
		if cb then callbacks[socket](revents) end
	end
	return count
end

-- based on poll_all
function poller_mt:poll(timeout)
	local poller, callbacks, events, n = self.poller, self.callbacks, self.events
	local n, ret = poller:poll_all(timeout, events)
	if not n then return nil, ret end
	-- assert(2*n == #events)
	-- assert((ret == nil) or (ret == events))
	for i = 1, n do
		local socket, revents = events[2*i-1], events[2*i]
		events[2*i-1], events[2*i] = nil
		local cb = callbacks[socket]
		-- some callback may remove socket from poller
		if cb then callbacks[socket](revents) end
	end
	-- assert(not next(events))
	return n
end

else

function poller_mt:poll(timeout)
	local poller = self.poller
	local count, err = poller:poll(timeout)
	if not count then
		return nil, err
	end
	local callbacks = self.callbacks
	for i=1,count do
		local id, revents = poller:next_revents_idx()
		callbacks[id](revents)
	end
	return count
end

end

function poller_mt:start()
	self.is_running = true
	while self.is_running do
		local status, err = self:poll(-1)
		if not status then
			return false, err
		end
	end
	return true
end

function poller_mt:stop()
	self.is_running = false
end

local M = {}

function M.new(pre_alloc)
	return setmetatable({
		poller = Poller(pre_alloc),
		callbacks = {},
		events    = (Poller == zmq.poller2) and {} or nil,
	}, poller_mt)
end

return setmetatable(M, {__call = function(tab, ...) return M.new(...) end})

