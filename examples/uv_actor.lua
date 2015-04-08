-- Use LibUV event loop in actor thread
--
-- !NOTE! I can not figure out why this does not work
--  with `inproc` transport so I use `tcp` to communicate
--  with actor thread

local function thread(pipe)
  local uv  = require "lluv"
  local zmq = require "lzmq"

  local function uv_poll_zmq(sock, cb)
    uv.poll_socket(sock:fd()):start(function(handle, err, event)
      if err then cb(sock, err) else
        while handle:active() and not sock:closed() do
          local ok, err = sock:has_event(zmq.POLLIN) 
          if ok == nil then cb(sock, err) break end
          if ok then cb(sock) else break end
        end
      end
      if sock:closed() then handle:close() end
    end)
  end

  uv_poll_zmq(pipe, function(pipe, err)
    if err then
      print("Poll error:", err)
      return pipe:close()
    end

    print(pipe:recv())
  end)

  uv.timer():start(1000, function()
    print("LibUV timer")
  end)

  uv.run()
end

local zth = require "lzmq.threads"
local ztm = require "lzmq.timer"

local actor = zth.xactor{thread, pipe = 'tcp'}:start()

for i = 1, 5 do
  actor:send("Hello #" .. i)
  ztm.sleep(500)
end
