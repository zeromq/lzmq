local ffi     = require "ffi"
local IS_WINDOWS = 
  (require "ffi".os:lower() == 'windows')
  or package.config:sub(1,1) == '\\'

local function orequire(...)
  local err = ""
  for _, name in ipairs{...} do
    local ok, mod = pcall(require, name)
    if ok then return mod, name end
    err = err .. "\n" .. mod
  end
  error(err)
end

local function oload(t)
  local err = ""
  for _, name in ipairs(t) do
    local ok, mod = pcall(ffi.load, name)
    if ok then return mod, name end
    err = err .. "\n" .. mod
  end
  error(err)
end

local function IF(cond, true_v, false_v)
  if cond then return true_v end
  return false_v
end

local bit     = orequire("bit32", "bit")

local zlibs ={
  "zmq",
  "libzmq",
  "zmq4",
  "libzmq4",
  "libzmq.so.4",
  "zmq3",
  "libzmq3",
  "libzmq.so.3",
}

local ok, libzmq3 = pcall( oload, zlibs )
if not ok then
  if pcall( require, "lzmq" ) then -- jus to load libzmq3
    libzmq3 = oload( zlibs )
  else error(libzmq3) end
end

ffi.cdef[[
  typedef struct zmq_msg_t {unsigned char _ [32];} zmq_msg_t;

  void zmq_version (int *major, int *minor, int *patch);
  int zmq_errno (void);
  const char *zmq_strerror (int errnum);

  void *zmq_ctx_new (void);
  int zmq_ctx_term (void *context);
  int zmq_ctx_destroy (void *context);
  int zmq_ctx_shutdown (void *context);
  int zmq_ctx_set (void *context, int option, int optval);
  int zmq_ctx_get (void *context, int option);

  void *zmq_socket         (void *, int type);
  int   zmq_close          (void *s);
  int   zmq_setsockopt     (void *s, int option, const void *optval, size_t optvallen); 
  int   zmq_getsockopt     (void *s, int option, void *optval, size_t *optvallen);
  int   zmq_bind           (void *s, const char *addr);
  int   zmq_connect        (void *s, const char *addr);
  int   zmq_unbind         (void *s, const char *addr);
  int   zmq_disconnect     (void *s, const char *addr);
  int   zmq_send           (void *s, const void *buf, size_t len, int flags);
  int   zmq_recv           (void *s, void *buf, size_t len, int flags);
  int   zmq_socket_monitor (void *s, const char *addr, int events);
  int   zmq_sendmsg        (void *s, zmq_msg_t *msg, int flags);
  int   zmq_recvmsg        (void *s, zmq_msg_t *msg, int flags);

  int    zmq_msg_init      (zmq_msg_t *msg);
  int    zmq_msg_init_size (zmq_msg_t *msg, size_t size);
  void  *zmq_msg_data      (zmq_msg_t *msg);
  size_t zmq_msg_size      (zmq_msg_t *msg);
  int    zmq_msg_close     (zmq_msg_t *msg);
  int    zmq_msg_send      (zmq_msg_t *msg, void *s, int flags);
  int    zmq_msg_recv      (zmq_msg_t *msg, void *s, int flags);
  int    zmq_msg_move      (zmq_msg_t *dest, zmq_msg_t *src);
  int    zmq_msg_copy      (zmq_msg_t *dest, zmq_msg_t *src);

  int    zmq_msg_more      (zmq_msg_t *msg);
  int    zmq_msg_get       (zmq_msg_t *msg, int option);
  int    zmq_msg_set       (zmq_msg_t *msg, int option, int optval);
]]

ffi.cdef([[
typedef struct {
  void *socket;
  ]] .. IF(IS_WINDOWS, "uint32_t", "int") .. [[ fd;
  short events;
  short revents;
} zmq_pollitem_t;

int zmq_poll (zmq_pollitem_t *items, int nitems, long timeout);
]])

ffi.cdef[[
  int zmq_proxy  (void *frontend, void *backend, void *capture);
  int zmq_device (int type, void *frontend, void *backend);
]]

local aint_t          = ffi.typeof("int[1]")
local aint64_t        = ffi.typeof("int64_t[1]")
local auint64_t       = ffi.typeof("uint64_t[1]")
local asize_t         = ffi.typeof("size_t[1]")
local vla_char_t      = ffi.typeof("char[?]")
local pvoid_t         = ffi.typeof("void*")
local pchar_t         = ffi.typeof("char*")
local zmq_msg_t       = ffi.typeof("zmq_msg_t")
local uintptr_t       = ffi.typeof("uintptr_t")
local vla_pollitem_t  = ffi.typeof("zmq_pollitem_t[?]")
local zmq_pollitem_t  = ffi.typeof("zmq_pollitem_t")
local pollitem_size   = ffi.sizeof(zmq_pollitem_t)
local NULL            = ffi.cast(pvoid_t, 0)

local function ptrtoint(ptr)
  return tonumber(ffi.cast(uintptr_t, ptr))
end

local function inttoptr(val)
  return ffi.cast(pvoid_t, ffi.cast(uintptr_t, val))
end

local function pget(lib, elem)
  local ok, err = pcall(function()
    local m = lib[elem]
    if nil ~= m then return m end
    error("not found")
  end)
  if ok then return err end
  return nil, err
end

local _M = {}

-- zmq_version, zmq_errno, zmq_strerror, zmq_poll, zmq_device, zmq_proxy
do

function _M.zmq_version()
  local major, minor, patch = ffi.new(aint_t, 0), ffi.new(aint_t, 0), ffi.new(aint_t, 0)
  libzmq3.zmq_version(major, minor, patch)
  return major[0], minor[0], patch[0]
end

function _M.zmq_errno()
  return libzmq3.zmq_errno()
end

function _M.zmq_strerror(errnum)
  local str = libzmq3.zmq_strerror (errnum);
  return ffi.string(str)
end

function _M.zmq_poll(items, nitems, timeout)
  return libzmq3.zmq_poll(items, nitems, timeout)
end

function _M.zmq_device(dtype, frontend, backend)
  return libzmq3.zmq_device(dtype, frontend, backend)
end

function _M.zmq_proxy(frontend, backend, capture)
  return libzmq3.zmq_proxy(dtype, frontend, backend)
end

end

-- zmq_ctx_new, zmq_ctx_term, zmq_ctx_get, zmq_ctx_set
do

function _M.zmq_ctx_new()
  local ctx = libzmq3.zmq_ctx_new()
  ffi.gc(ctx, _M.zmq_ctx_term)
  return ctx
end

if pget(libzmq3, "zmq_ctx_shutdown") then
function _M.zmq_ctx_shutdown(ctx)
  return libzmq3.zmq_ctx_shutdown(ctx)
end
end

if pget(libzmq3, "zmq_ctx_term") then
function _M.zmq_ctx_term(ctx)
  return libzmq3.zmq_ctx_term(ffi.gc(ctx, nil))
end
else
function _M.zmq_ctx_term(ctx)
  libzmq3.zmq_ctx_destroy(ffi.gc(ctx, nil))
end
end

function _M.zmq_ctx_get(ctx, option)
  return libzmq3.zmq_ctx_get(ctx, option)
end

function _M.zmq_ctx_set(ctx, option, value)
  return libzmq3.zmq_ctx_set(ctx, option, value)
end

end

-- zmq_send, zmq_recv, zmq_sendmsg, zmq_recvmsg,
-- zmq_socket, zmq_close, zmq_connect, zmq_bind, zmq_unbind, zmq_disconnect,
-- zmq_skt_setopt_int, zmq_skt_setopt_i64, zmq_skt_setopt_u64, zmq_skt_setopt_str,
-- zmq_skt_getopt_int, zmq_skt_getopt_i64, zmq_skt_getopt_u64, zmq_skt_getopt_str
do

function _M.zmq_socket(ctx, stype)
  local skt = libzmq3.zmq_socket(ctx, stype)
  if NULL == skt then return nil end
  ffi.gc(skt, _M.zmq_close)
  return skt
end

function _M.zmq_close(skt)
  return libzmq3.zmq_close(ffi.gc(skt,nil))
end

local function gen_setopt_int(t, ct)
  return function (skt, option, optval) 
    local size = ffi.sizeof(t)
    local val  = ffi.new(ct, optval)
    return libzmq3.zmq_setsockopt(skt, option, val, size)
  end
end

local function gen_getopt_int(t, ct)
  return function (skt, option) 
    local size = ffi.new(asize_t, ffi.sizeof(t))
    local val  = ffi.new(ct, 0)
    if -1 ~= libzmq3.zmq_getsockopt(skt, option, val, size) then
      return val[0]
    end
    return
  end
end

_M.zmq_skt_setopt_int = gen_setopt_int("int",      aint_t   )
_M.zmq_skt_setopt_i64 = gen_setopt_int("int64_t",  aint64_t )
_M.zmq_skt_setopt_u64 = gen_setopt_int("uint64_t", auint64_t)

function _M.zmq_skt_setopt_str(skt, option, optval)
  return libzmq3.zmq_setsockopt(skt, option, optval, #optval)
end

_M.zmq_skt_getopt_int = gen_getopt_int("int",      aint_t   )
_M.zmq_skt_getopt_i64 = gen_getopt_int("int64_t",  aint64_t )
_M.zmq_skt_getopt_u64 = gen_getopt_int("uint64_t", auint64_t)

function _M.zmq_skt_getopt_str(skt, option)
  local len  = 255
  local val  = ffi.new(vla_char_t, len)
  local size = ffi.new(asize_t, len)
  if -1 ~= libzmq3.zmq_getsockopt(skt, option, val, size) then
    if size[0] > 0 then
      return ffi.string(val, size[0] - 1)
    end
    return ""
  end
  return
end

function _M.zmq_connect(skt, addr)
  return libzmq3.zmq_connect(skt, addr)
end

function _M.zmq_bind(skt, addr)
  return libzmq3.zmq_bind(skt, addr)
end

function _M.zmq_unbind(skt, addr)
  return libzmq3.zmq_unbind(skt, addr)
end

function _M.zmq_disconnect(skt, addr)
  return libzmq3.zmq_disconnect(skt, addr)
end

function _M.zmq_send(skt, data, flags)
  return libzmq3.zmq_send(skt, data, #data, flags or 0)
end

function _M.zmq_recv(skt, len, flags)
  local buf = ffi.new(vla_char_t, len)
  local flen = libzmq3.zmq_recv(skt, buf, len, flags or 0)
  if flen < 0 then return end
  if len > flen then len = flen end
  return ffi.string(buf, len), flen
end

function _M.zmq_sendmsg(skt, msg, flags) 
  return libzmq3.zmq_sendmsg(skt, msg, flags)
end

function _M.zmq_recvmsg(skt, msg, flags)
  return libzmq3.zmq_recvmsg(skt, msg, flags)
end

end

-- zmq_msg_init, zmq_msg_init_size, zmq_msg_data, zmq_msg_size, zmq_msg_get, 
-- zmq_msg_set, zmq_msg_move, zmq_msg_copy, zmq_msg_set_data, zmq_msg_get_data, 
-- zmq_msg_init_string, zmq_msg_recv, zmq_msg_send, zmq_msg_more
do -- message

function _M.zmq_msg_init(msg)
  msg = msg or ffi.new(zmq_msg_t)
  if 0 == libzmq3.zmq_msg_init(msg) then
    return msg
  end
  return
end

function _M.zmq_msg_init_size(msg, len)
  if not len then msg, len  = nil, msg end
  local msg = msg or ffi.new(zmq_msg_t)
  if 0 == libzmq3.zmq_msg_init_size(msg, len) then
    return msg
  end
  return
end

function _M.zmq_msg_data(msg, pos)
  local ptr = libzmq3.zmq_msg_data(msg)
  pos = pos or 0
  if pos == 0 then return ptr end
  ptr = ffi.cast(pchar_t, ptr) + pos
  return ffi.cast(pvoid_t, ptr)
end

function _M.zmq_msg_size(msg)
  return libzmq3.zmq_msg_size(msg)
end

function _M.zmq_msg_close(msg)
  libzmq3.zmq_msg_close(msg)
end

local function get_msg_copy(copy)
  return function (dest, src)
    local new = false
    if not src then 
      new, src = true, dest
      dest = _M.zmq_msg_init()
      if not dest then return end
    end
    local ret = copy(dest, src)
    if ret == -1 then
      if new then _M.zmq_msg_close(dest) end
      return
    end
    return dest
  end
end

_M.zmq_msg_move  = get_msg_copy(libzmq3.zmq_msg_move)
_M.zmq_msg_copy  = get_msg_copy(libzmq3.zmq_msg_copy)

function _M.zmq_msg_set_data(msg, str)
  ffi.copy(_M.zmq_msg_data(msg), str)
end

function _M.zmq_msg_get_data(msg)
  return ffi.string(_M.zmq_msg_data(msg), _M.zmq_msg_size(msg))
end

function _M.zmq_msg_init_string(str)
  local msg = _M.zmq_msg_init_size(#str)
  _M.zmq_msg_set_data(msg, str)
  return msg
end

function _M.zmq_msg_recv(msg, skt, flags)
  return libzmq3.zmq_msg_recv(msg, skt, flags or 0)
end

function _M.zmq_msg_send(msg, skt, flags)
  return libzmq3.zmq_msg_send(msg, skt, flags or 0)
end

function _M.zmq_msg_more(msg)
  return libzmq3.zmq_msg_more(msg)
end

function _M.zmq_msg_get(msg, option)
  return libzmq3.zmq_msg_get(msg, option)
end

function _M.zmq_msg_set(msg, option, optval)
  return libzmq3.zmq_msg_set(msg, option, optval)
end

end

_M.ERRORS = require"lzmq.ffi.error"
local ERRORS_MNEMO = {}
for k,v in pairs(_M.ERRORS) do ERRORS_MNEMO[v] = k end

function _M.zmq_mnemoerror(errno)
  return ERRORS_MNEMO[errno] or "UNKNOWN"
end


do -- const

_M.CONTEXT_OPTIONS = {
  ZMQ_IO_THREADS  = 1;
  ZMQ_MAX_SOCKETS = 2;
}

_M.SOCKET_OPTIONS = {
  ZMQ_AFFINITY                = {4 , "RW", "u64"};
  ZMQ_IDENTITY                = {5 , "RW", "str"}; 
  ZMQ_SUBSCRIBE               = {6 , "WO", "str_arr"};
  ZMQ_UNSUBSCRIBE             = {7 , "WO", "str_arr"};
  ZMQ_RATE                    = {8 , "RW", "int"};
  ZMQ_RECOVERY_IVL            = {9 , "RW", "int"};
  ZMQ_SNDBUF                  = {11, "RW", "int"};
  ZMQ_RCVBUF                  = {12, "RW", "int"};
  ZMQ_RCVMORE                 = {13, "RO", "int"};
  ZMQ_FD                      = {14, "RO", "int"};
  ZMQ_EVENTS                  = {15, "RO", "int"};
  ZMQ_TYPE                    = {16, "RO", "int"};
  ZMQ_LINGER                  = {17, "RW", "int"};
  ZMQ_RECONNECT_IVL           = {18, "RW", "int"};
  ZMQ_BACKLOG                 = {19, "RW", "int"};
  ZMQ_RECONNECT_IVL_MAX       = {21, "RW", "int"};
  ZMQ_MAXMSGSIZE              = {22, "RW", "i64"};
  ZMQ_SNDHWM                  = {23, "RW", "int"};
  ZMQ_RCVHWM                  = {24, "RW", "int"};
  ZMQ_MULTICAST_HOPS          = {25, "RW", "int"};
  ZMQ_RCVTIMEO                = {27, "RW", "int"};
  ZMQ_SNDTIMEO                = {28, "RW", "int"};
  ZMQ_IPV4ONLY                = {31, "RW", "int"};
  ZMQ_LAST_ENDPOINT           = {32, "RO", "str"};
  ZMQ_ROUTER_MANDATORY        = {33, "WO", "int"};
  ZMQ_TCP_KEEPALIVE           = {34, "RW", "int"};
  ZMQ_TCP_KEEPALIVE_CNT       = {35, "RW", "int"};
  ZMQ_TCP_KEEPALIVE_IDLE      = {36, "RW", "int"};
  ZMQ_TCP_KEEPALIVE_INTVL     = {37, "RW", "int"};
  ZMQ_TCP_ACCEPT_FILTER       = {38, "WO", "str_arr"};
  ZMQ_DELAY_ATTACH_ON_CONNECT = {39, "RW", "int"};
  ZMQ_IMMEDIATE               = {39, "RW", "int"};
  ZMQ_XPUB_VERBOSE            = {40, "RW", "int"};
  ZMQ_ROUTER_RAW              = {41, "RW", "int"};
  ZMQ_IPV6                    = {42, "RW", "int"},
  ZMQ_MECHANISM               = {43, "RO", "int"},
  ZMQ_PLAIN_SERVER            = {44, "RW", "int"},
  ZMQ_PLAIN_USERNAME          = {45, "RW", "str"},
  ZMQ_PLAIN_PASSWORD          = {46, "RW", "str"},
  ZMQ_CURVE_SERVER            = {47, "RW", "int"},
  ZMQ_CURVE_PUBLICKEY         = {48, "RW", "str"},
  ZMQ_CURVE_SECRETKEY         = {49, "RW", "str"},
  ZMQ_CURVE_SERVERKEY         = {50, "RW", "str"},
  ZMQ_PROBE_ROUTER            = {51, "WO", "int"},
  ZMQ_REQ_CORRELATE           = {52, "WO", "int"},
  ZMQ_REQ_RELAXED             = {53, "WO", "int"},
  ZMQ_CONFLATE                = {54, "WO", "int"},
  ZMQ_ZAP_DOMAIN              = {55, "RW", "str"},
}

_M.SOCKET_TYPES = {
  ZMQ_PAIR   = 0;
  ZMQ_PUB    = 1;
  ZMQ_SUB    = 2;
  ZMQ_REQ    = 3;
  ZMQ_REP    = 4;
  ZMQ_DEALER = 5;
  ZMQ_ROUTER = 6;
  ZMQ_PULL   = 7;
  ZMQ_PUSH   = 8;
  ZMQ_XPUB   = 9;
  ZMQ_XSUB   = 10;
}

_M.FLAGS = {
  ZMQ_DONTWAIT = 1;
  ZMQ_SNDMORE  = 2;
  ZMQ_POLLIN   = 1;
  ZMQ_POLLOUT  = 2;
  ZMQ_POLLERR  = 4;
}

_M.DEVICE = {
  ZMQ_STREAMER  = 1;
  ZMQ_FORWARDER = 2;
  ZMQ_QUEUE     = 3;
}

_M.SECURITY_MECHANISM = {
 ZMQ_NULL  = 0;
 ZMQ_PLAIN = 1;
 ZMQ_CURVE = 2;
}

end

_M.ptrtoint = ptrtoint

_M.inttoptr = inttoptr

_M.vla_pollitem_t = vla_pollitem_t
_M.zmq_pollitem_t = zmq_pollitem_t
_M.NULL           = NULL
_M.bit            = bit

local ZMQ_MAJOR, ZMQ_MINOR, ZMQ_PATCH = _M.zmq_version()
assert(
  ((ZMQ_MAJOR == 3) and (ZMQ_MINOR >= 2)) or (ZMQ_MAJOR == 4),
  "Unsupported ZMQ version: " .. ZMQ_MAJOR .. "." .. ZMQ_MINOR .. "." .. ZMQ_PATCH
)

return _M
