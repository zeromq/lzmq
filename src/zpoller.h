#ifndef _ZPOLLER_H_
#define _ZPOLLER_H_

#include "lua.h"

int luazmq_poller_create(lua_State *L);

void luazmq_poller_initlib (lua_State *L);

#endif
