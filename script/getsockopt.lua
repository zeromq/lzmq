local api = require "lzmq.ffi.api"
local printf = function(...) print(string.format(...)) end

local function rfit(str, n)
  if #str >= n then return str end
  return str .. (' '):rep(n-#str)
end

local options = {}
local max_len = 0

for opt in pairs(api.SOCKET_OPTIONS) do
  options[#options + 1] = opt
  if #opt > max_len then max_len = #opt end
end

table.sort(options,function(l,r)
  return api.SOCKET_OPTIONS[l][1] < api.SOCKET_OPTIONS[r][1]
end)

function print_skt_options()
  printf("static const luazmq_int_const skt_options[] ={")
  for _,opt in pairs(options) do
    local val = api.SOCKET_OPTIONS[opt]
    printf(
      "#if defined(%s)\n"         .. 
      "  DEFINE_ZMQ_CONST(%s),\n" ..
      "#endif", opt, rfit(opt:sub(5), max_len - 2)
    )
  end
  printf("  {NULL, 0}")
  printf("};")
end

function print_skt_options_define()
  printf("//{ options\n")
  for _,opt in pairs(options) do
    local val = api.SOCKET_OPTIONS[opt]
    local name = opt:sub(5)

    printf(
      "#if defined(%s)\n" ..
      "  DEFINE_SKT_OPT_%s(%s%s%s)\n" ..
      "#endif",
      opt, val[2], rfit(name:lower()..',', max_len - 2), rfit(opt..',', max_len + 8), rfit(val[3], 10)
    )
  end
  printf("\n//}")
end

function print_skt_options_register()
  print("  //{ options")
  for _,opt in pairs(options) do
    local val = api.SOCKET_OPTIONS[opt]
    local name = opt:sub(5)

    printf(
      "#if defined(%s)\n" ..
      "  REGISTER_SKT_OPT_%s(%s),\n" ..
      "#endif",
      opt, val[2], rfit(name:lower(), max_len - 2)
    )
  end
  print("  //}")
end

print_skt_options()

print_skt_options_define()

print_skt_options_register()