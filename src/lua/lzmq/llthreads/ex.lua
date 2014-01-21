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
-- wraps the low-level threads object.
--

local ok, llthreads = pcall(require, "llthreads2")
if not ok then llthreads = require"llthreads" end

local os        = require"os"
local string    = require"string"
local table     = require"table"

local setmetatable = setmetatable
local tonumber = tonumber
local assert = assert

local lua_version_t
local function lua_version()
  if not lua_version_t then 
    local version = rawget(_G,"_VERSION")
    local maj,min = version:match("^Lua (%d+)%.(%d+)$")
    if maj then                         lua_version_t = {tonumber(maj),tonumber(min)}
    elseif not math.mod then            lua_version_t = {5,2}
    elseif table.pack and not pack then lua_version_t = {5,2}
    else                                lua_version_t = {5,2} end
  end
  return lua_version_t[1], lua_version_t[2]
end

local LUA_MAJOR, LUA_MINOR = lua_version()
local IS_LUA_51 = (LUA_MAJOR == 5) and (LUA_MINOR == 1)
local IS_LUA_52 = (LUA_MAJOR == 5) and (LUA_MINOR == 2)

local LUA_INIT = "LUA_INIT"
local LUA_INIT_VER
if not IS_LUA_51 then
  LUA_INIT_VER = LUA_INIT .. "_" .. LUA_MAJOR .. "_" .. LUA_MINOR
end

LUA_INIT = LUA_INIT_VER and os.getenv( LUA_INIT_VER ) or os.getenv( LUA_INIT ) or ""

local thread_mt = {}
thread_mt.__index = thread_mt

function thread_mt:start(...)
	return self.thread:start(...)
end

function thread_mt:join(...)
	return self.thread:join(...)
end

function thread_mt:kill()
	return self.thread:kill()
end

local bootstrap_pre = [[
local action, action_arg = ...
local lua_init = ]] .. ("%q"):format(LUA_INIT) .. [[
if lua_init and #lua_init > 0 then
	if lua_init:sub(1,1) == '@' then
		dofile(lua_init:sub(2))
	else
		assert((loadstring or load)(lua_init))()
	end
end

-- create global 'arg'
local argc = select("#", ...)
arg = { n = argc - 2, select(3, ...) }
]]

local bootstrap_post = [[
local loadstring = loadstring or load
local unpack = table.unpack or unpack

local func
-- load Lua code.
if action == 'runfile' then
	func = assert(loadfile(action_arg))
	-- script name
	arg[0] = action_arg
elseif action == 'runstring' then
	func = assert(loadstring(action_arg))
	-- fake script name
	arg[0] = '=(loadstring)'
end

argc = arg.n or #arg
-- run loaded code.
return func(unpack(arg, 1, argc))
]]

local bootstrap_code = bootstrap_pre..bootstrap_post

local function new_thread(bootstrap_code, action, action_arg, ...)
	local thread = llthreads.new(bootstrap_code, action, action_arg, ...)
	return setmetatable({
		thread = thread,
	}, thread_mt)
end

local M = {}

M.set_bootstrap_prelude = function (code)
	bootstrap_code = bootstrap_pre .. code .. bootstrap_post
end;

M.runfile = function (file, ...)
	return new_thread(bootstrap_code, 'runfile', file, ...)
end;

M.runstring = function (code, ...)
	return new_thread(bootstrap_code, 'runstring', code, ...)
end;

M.runfile_ex = function (prelude, file, ...)
	local bootstrap_code = bootstrap_pre .. prelude .. bootstrap_post
	return new_thread(bootstrap_code, 'runfile', file, ...)
end;

M.runstring_ex = function (prelude, code, ...)
	local bootstrap_code = bootstrap_pre .. prelude .. bootstrap_post
	return new_thread(bootstrap_code, 'runstring', code, ...)
end;

return M