local zmq = require "lzmq"
require "utils"

print_version(zmq)

context  = assert(zmq.context())
frontend = assert(context:socket (zmq.ROUTER))
backend  = assert(context:socket (zmq.DEALER))
assert(frontend:bind("tcp://*:5555"))
assert(backend:bind("tcp://*:5556"))
print(zmq.device(zmq.QUEUE, frontend, backend))