local ok, zmq = pcall(require, "lzmq")
if not ok then zmq = nil end

local errors

if zmq then

  errors = {}
  for n,e in pairs(zmq.errors) do
    if type(n) == 'string' then
      errors[n] = e
    end
  end

else -- WARNING this is not best way

  local IS_WINDOWS = 
    (require "ffi".os:lower() == 'windows')
    or package.config:sub(1,1) == '\\'

  local ZMQ_HAUSNUMERO = 156384712

  errors = {
    EFSM            = ZMQ_HAUSNUMERO + 51;
    ENOCOMPATPROTO  = ZMQ_HAUSNUMERO + 52;
    ETERM           = ZMQ_HAUSNUMERO + 53;
    EMTHREAD        = ZMQ_HAUSNUMERO + 54;
    ENOMEM          = 12;
    EACCES          = 13;
    EFAULT          = 14;
    EINVAL          = 22;
    EAGAIN          = 35;
    EHOSTUNREACH    = 65,
    ENOTSOCK        = 38;
    ENETDOWN        = 50;
    EPROTONOSUPPORT = 43;
    ENOBUFS         = 55;
    ENETUNREACH     = 51;
    ENOTSUP         = 45;
    ETIMEDOUT       = 60;
    EADDRNOTAVAIL   = 49;
    EADDRINUSE      = 48;
    ECONNABORTED    = 53;
    EAFNOSUPPORT    = 47;
    ECONNREFUSED    = 61;
    ENOTCONN        = 57;
    EINPROGRESS     = 36;
    ECONNRESET      = 54;
    EMSGSIZE        = 40;
  }

  if IS_WINDOWS then
    local winerr = {
      EAGAIN          = 11;
      EHOSTUNREACH    = 110;
      ENOTSOCK        = 128;
      ENETDOWN        = 116;
      EPROTONOSUPPORT = 135;
      ENOBUFS         = 119;
      ENETUNREACH     = 118;
      ENOTSUP         = 129;
      ETIMEDOUT       = 138;
      EADDRNOTAVAIL   = 101;
      EADDRINUSE      = 100;
      ECONNABORTED    = 106;
      EAFNOSUPPORT    = 102;
      ECONNREFUSED    = 107;
      ENOTCONN        = 126;
      EINPROGRESS     = 112;
      ECONNRESET      = 108;
      EMSGSIZE        = 115;
    }
    for e, v in pairs(winerr) do errors[e]=v end
  end

end

return errors
