#ifndef _ZCONTEXT_H_
#define _ZCONTEXT_H_

#include "lua.h"

int luazmq_context_create (lua_State *L);

int luazmq_context_init (lua_State *L);

int luazmq_init_ctx (lua_State *L);

void luazmq_context_initlib (lua_State *L, int nup);

#endif
