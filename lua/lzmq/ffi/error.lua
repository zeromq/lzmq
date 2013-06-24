local zmq = require "lzmq"

local errors = {}
for n,e in pairs(zmq.errors) do
  if type(n) == 'string' then
    errors[n] = e
  end
end

return errors