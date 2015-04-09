-- Use LibUV event loop in actor thread

local function thread(pipe)
  local uv  = require "lluv"
  local ut  = require "lluv.utils"
  local zmq = require "lzmq"

  local uv_poll_zmq = ut.class() do

  function uv_poll_zmq:__init(s)
    self._s = s
    self._h = uv.poll_socket(s:fd())
    return self
  end

  local function on_poll(self, err, cb)
    if err then cb(self, err, self._s) else
      while self._h:active() and not self._s:closed() do
        local ok, err = self._s:has_event(zmq.POLLIN)
        if ok == nil then cb(self, err, self._s) break end
        if ok then cb(self, nil, self._s) else break end
      end
    end
    if self._s:closed() then self._h:close() end
  end

  function uv_poll_zmq:start(cb)
    self._h:start(function(handle, err) on_poll(self, err, cb) end)

    -- For `inproc` socket without this call socket never get in signal state.
    local ok, err = self._s:has_event(zmq.POLLIN)
    if ok == nil then
      -- context already terminated
      uv.defer(on_poll, self, err, cb)
    elseif ok then
      -- socket already has events
      uv.defer(on_poll, self, nil, cb)
    end

    return self
  end

  function uv_poll_zmq:stop()
    self._h:stop()
    return self
  end

  function uv_poll_zmq:close(...)
    self._h:close(...)
    return self
  end

  end

  uv_poll_zmq.new(pipe):start(function(handle, err, pipe)
    if err then
      print("Poll error:", err)
      return handle:close()
    end

    print("Pipe recv:", pipe:recvx())
  end)

  uv.timer():start(1000, function()
    print("LibUV timer")
  end)

  uv.run()
end

local zth = require "lzmq.threads"
local ztm = require "lzmq.timer"

local actor = zth.xactor(thread):start()

for i = 1, 5 do
  actor:send("Hello #" .. i)
  ztm.sleep(500)
end
