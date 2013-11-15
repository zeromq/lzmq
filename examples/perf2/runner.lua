local DIR_SEP = package.config:sub(1,1)

local msg_size
local msg_count
local N

local function exec(cmd)
  local f, err = io.popen(cmd, "r")
  if not f then return err end
  local data, err = f:read("*all")
  f:close()
  return data, err
end

local function parse_thr(result)
  local msgps = assert(
    tonumber((result:match("mean throughput: (%S+) %[msg/s%]")))
  , result)
  local mbps = assert(
    tonumber((result:match("mean throughput: (%S+) %[Mb/s%]")))
  , result)
  return msgps, mbps
end

local function parse_lat(result)
  return assert(
    tonumber((result:match("average latency: (%S+) %[us%]")))
  , result)
end

local function exec_thr(cmd)
  local msg = assert(exec(cmd))
  return parse_thr(msg)
end

local function exec_lat(cmd)
  local msg = assert(exec(cmd))
  return parse_lat(msg)
end

local function field(wdt, fmt, value)
  local str = string.format(fmt, value)
  if wdt > #str then str = str .. (' '):rep(wdt - #str) end
  return str
end

local function print_row(row)
  print('|' .. table.concat(row, '|') .. '|')
end

function luajit_thr(result, dir, ffi)
  local cmd = 
    "cd " .. dir .. " && " ..
      "luajit ." .. DIR_SEP .."inproc_thr.lua " .. msg_size .. " " .. msg_count .. " " .. ffi ..
    " && cd .."

  for i = 1, N do
    table.insert(result, {exec_thr(cmd)})
  end

end

function bin_thr(result, dir)
  local cmd = 
    "cd " .. dir .. " && " ..
      "." .. DIR_SEP .."inproc_thr " .. msg_size .. " " .. msg_count .. 
    " && cd .."

  for i = 1, N do
    table.insert(result, {exec_thr(cmd)})
  end

end

function luajit_lat(result, dir, ffi)
  local cmd = 
    "cd " .. dir .. " && " ..
      "luajit ." .. DIR_SEP .."inproc_lat.lua " .. msg_size .. " " .. msg_count .. " " .. ffi ..
    " && cd .."

  for i = 1, N do
    table.insert(result, {exec_lat(cmd)})
  end

end

function bin_lat(result, dir)
  local cmd = 
    "cd " .. dir .. " && " ..
      "." .. DIR_SEP .."inproc_lat " .. msg_size .. " " .. msg_count .. 
    " && cd .."

  for i = 1, N do
    table.insert(result, {exec_lat(cmd)})
  end

end

msg_size  = 30
msg_count = 10000
N         = 10

local libzmq_thr    = {}
local nomsg_thr     = {}
local nomsg_thr_ffi = {}
local msg_thr       = {}
local msg_thr_ffi   = {}

   bin_thr(libzmq_thr,    "libzmq")
luajit_thr(nomsg_thr,     "thr_nomsg", ""    )
luajit_thr(nomsg_thr_ffi, "thr_nomsg", "ffi" )
luajit_thr(msg_thr,       "thr",       ""    )
luajit_thr(msg_thr_ffi,   "thr",       "ffi" )

print("\n----")
print("###Inproc Throughput Test:\n")
print(string.format("message size: %d [B]<br/>",     msg_size  ))
print(string.format("message count: %d<br/>",        msg_count ))
print(string.format("mean throughput [Mb/s]:<br/>\n"           ))

print_row{
  field(3, " # ");
  field(12, " libzmq");
  field(12, " str");
  field(12, " str(ffi)");
  field(12, " msg");
  field(12, " msg(ffi)");
}
print_row{
  ("-"):rep(3);
  ("-"):rep(12);
  ("-"):rep(12);
  ("-"):rep(12);
  ("-"):rep(12);
  ("-"):rep(12);
}
for i = 1, N do
  print_row{
    field(3, " %d",  i);
    field(12,"%.3f", libzmq_thr    [i][2]);
    field(12,"%.3f", nomsg_thr     [i][2]);
    field(12,"%.3f", nomsg_thr_ffi [i][2]);
    field(12,"%.3f", msg_thr       [i][2]);
    field(12,"%.3f", msg_thr_ffi   [i][2]);
  }
end

msg_size  = 1
msg_count = 10000
N         = 10

local libzmq_lat    = {}
local nomsg_lat     = {}
local nomsg_lat_ffi = {}
local msg_lat       = {}
local msg_lat_ffi   = {}

   bin_lat(libzmq_lat,    "libzmq")
luajit_lat(nomsg_lat,     "lat_nomsg", ""    )
luajit_lat(nomsg_lat_ffi, "lat_nomsg", "ffi" )
luajit_lat(msg_lat,       "lat",       ""    )
luajit_lat(msg_lat_ffi,   "lat",       "ffi" )


print("\n----")
print("###Inproc Latency Test:\n")
print(string.format("message size: %d [B]<br/>",   msg_size  ))
print(string.format("message count: %d<br/>",      msg_count ))
print(string.format("average latency [us]:<br/>\n"           ))

print_row{
  field(3, " # ");
  field(12, " libzmq");
  field(12, " str");
  field(12, " str(ffi)");
  field(12, " msg");
  field(12, " msg(ffi)");
}
print_row{
  ("-"):rep(3);
  ("-"):rep(12);
  ("-"):rep(12);
  ("-"):rep(12);
  ("-"):rep(12);
  ("-"):rep(12);
}
for i = 1, N do
  print_row{
    field(3, " %d",  i);
    field(12,"%.3f", libzmq_lat    [i][1]);
    field(12,"%.3f", nomsg_lat     [i][1]);
    field(12,"%.3f", nomsg_lat_ffi [i][1]);
    field(12,"%.3f", msg_lat       [i][1]);
    field(12,"%.3f", msg_lat_ffi   [i][1]);
  }
end

