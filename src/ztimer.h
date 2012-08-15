#ifndef _ZTIMER_H_
#define _ZTIMER_H_

#include "lua.h"

#if defined (_WIN32) || defined (_WINDOWS)
#  define __WINDOWS__
#endif

#ifdef _MSC_VER
#  define LUAZMQ_TIMER_EXPORT __declspec(dllexport)
#else
#  define LUAZMQ_TIMER_EXPORT
#endif

void luazmq_timer_initlib(lua_State *L);

#endif