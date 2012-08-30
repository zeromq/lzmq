#ifndef _ZSOCKET_H_
#define _ZSOCKET_H_

#include "lua.h"
#include "lzmq.h"

void luazmq_socket_initlib (lua_State *L);

int luazmq_skt_before_close (lua_State *L, zsocket *skt);

#endif
