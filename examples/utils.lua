local zmq = require "lzmq"

io.stdout:setvbuf"no"

function printf(...) return print(string.format(...)) end

function print_msg(title, data, err, ...)
  print(title)
  if data then -- data
    if type(data) == 'table' then
      for _, msg in ipairs(data) do
        printf("[%.4d] %s", #msg, msg) 
      end
    elseif type(data) == 'userdata'  then
      printf("[%.4d] %s", data:size(), data:data()) 
    else 
      printf("[%.4d] %s", #data, data)
    end
  else  --error
    if type(err) == 'string' then
      printf("Error: %s", err)
    elseif type(err) == 'number' then 
      local msg   = zmq.error(err):msg()
      local mnemo = zmq.errors[err] or 'UNKNOWN'
      printf("Error: [%s] %s (%d)", mnemo, msg, err)
    elseif type(err) == 'userdata' then
      printf("Error: [%s] %s (%d)", err:mnemo(), err:msg(), err:no())
    else
      printf("Error: %s", tostring(err))
    end
  end
  print("-------------------------------------")
  return data, err, ...
end

function print_version(zmq)
  local version = zmq.version()
  printf("zmq version: %d.%d.%d", version[1], version[2], version[3])
end
