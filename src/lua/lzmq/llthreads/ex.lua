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

--
-- Note! Define this function prior all `local` definitions
--       to prevent use upvalue by accident
--
local bootstrap_code = require"string".dump(function(lua_init, prelude, code, ...)
  local loadstring = loadstring or load
  local unpack     = table.unpack or unpack

  local function load_src(str)
    local f, n
    if str:sub(1,1) == '@' then
      n = str:sub(2)
      f = assert(loadfile(n))
    else
      n = '=(loadstring)'
      f = assert(loadstring(str))
    end
    return f, n
  end

  local function pack_n(...)
    return { n = select("#", ...), ... }
  end

  local function unpack_n(t)
    return unpack(t, 1, t.n)
  end
  
  if lua_init and #lua_init > 0 then
    local init = load_src(lua_init)
    init()
  end

  local args

  if prelude and #prelude > 0 then
    prelude = load_src(prelude)
    args = pack_n(prelude(...))
  else
    args = pack_n(...)
  end

  local func
  func, args[0] = load_src(code)

  _G.arg = args
     arg = args

  return func(unpack_n(args))
end)

local ok, llthreads = pcall(require, "llthreads2")
if not ok then llthreads = require"llthreads" end

local os        = require"os"
local string    = require"string"
local table     = require"table"

local setmetatable, tonumber, assert = setmetatable, tonumber, assert

-------------------------------------------------------------------------------
local LUA_INIT = "LUA_INIT" do

local lua_version_t
local function lua_version()
  if not lua_version_t then 
    local version = assert(_G._VERSION)
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

local LUA_INIT_VER
if not IS_LUA_51 then
  LUA_INIT_VER = LUA_INIT .. "_" .. LUA_MAJOR .. "_" .. LUA_MINOR
end

LUA_INIT = LUA_INIT_VER and os.getenv( LUA_INIT_VER ) or os.getenv( LUA_INIT ) or ""

end
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
local thread_mt = {} do
thread_mt.__index = thread_mt

function thread_mt:start(...)
  local ok, err = self.thread:start(...)
  if not ok then return nil, err end
  return self
end

function thread_mt:join(...)
  return self.thread:join(...)
end

function thread_mt:alive()
  return self.thread:alive()
end

end
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
local threads = {} do

local function new_thread(prelude, code, ...)
  if type(prelude) == "function" then
    prelude = string.dump(prelude)
  end

  if type(code) == "function" then
    code = string.dump(code)
  end

  local thread = llthreads.new(bootstrap_code, LUA_INIT, prelude, code, ...)
  return setmetatable({
    thread = thread,
  }, thread_mt)
end

threads.run = function (code, ...)
  return new_thread(nil, code, ...)
end

threads.run_ex = function (prelude, code, ...)
  return new_thread(prelude, code, ...)
end

end
-------------------------------------------------------------------------------

return threads