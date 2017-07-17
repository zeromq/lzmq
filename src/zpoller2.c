/*
  Author: Alexey Melnichuk <mimir@newmail.ru>

  Copyright (C) 2013-2014 Alexey Melnichuk <mimir@newmail.ru>

  Licensed according to the included 'LICENCE' document

  This file is part of lua-lzqm library.
 */

#include "lzutils.h"
#include "lzmq.h"
#include <assert.h>

#ifdef ZMQ_HAVE_POLLER

#include "zpoller2.h"

#ifdef _WIN32
typedef SOCKET socket_t;
#else
typedef int socket_t;
#endif

static void luazmq_plr_save_socket(lua_State *L, zpoller2 *poller, void *socket, int idx){
  lua_rawgeti(L, LUAZMQ_LUA_REGISTRY, poller->sockets_ref);
  lua_pushlightuserdata(L, socket);
  lua_pushvalue(L, idx);
  lua_rawset(L, -3);
  lua_pop(L, 1);
}

static void luazmq_plr_remove_socket(lua_State *L, zpoller2 *poller, void *socket){
  lua_rawgeti(L, LUAZMQ_LUA_REGISTRY, poller->sockets_ref);
  lua_pushlightuserdata(L, socket);
  lua_pushnil(L);
  lua_rawset(L, -3);
  lua_pop(L, 1);
}

static void luazmq_plr_push_event_socket(lua_State *L, zpoller2 *poller, zmq_poller_event_t *event){
  if(event->socket){
    lua_rawgeti(L, LUAZMQ_LUA_REGISTRY, poller->sockets_ref);
    lua_pushlightuserdata(L, event->socket);
    lua_rawget(L, -2);
    lua_remove(L, -2);
  }
  else{
    lua_pushnumber(L, event->fd);
  }
}

#define LUAZMQ_DEFAULT_POLLER_LEN 10

int luazmq_poller2_create(lua_State *L){
  unsigned int n = luaL_optinteger(L, 1, LUAZMQ_DEFAULT_POLLER_LEN);
  size_t poller_size = sizeof(sizeof(zpoller2) + (n - 1) * sizeof(zmq_poller_event_t));
  zpoller2 *poller = luazmq_newudata(L, zpoller2, LUAZMQ_POLLER2);

  // create storage for sockets references
  lua_newtable(L);
  poller->sockets_ref = luaL_ref(L, LUAZMQ_LUA_REGISTRY);

  poller->handle = zmq_poller_new();
  if(!poller->handle){
    lua_pushnil(L);
    lua_pushliteral(L, "memory allocation error");
    return 2;
  }
  poller->n_events = n;
  return 1;
}

/* method: close */
static int luazmq_plr_close(lua_State *L){
  zpoller2 *poller = (zpoller2 *)luazmq_checkudatap (L, 1, LUAZMQ_POLLER2);
  luaL_argcheck (L, poller != NULL, 1, LUAZMQ_PREFIX"poller expected");
  if(poller->handle) zmq_poller_destroy(&poller->handle);
  if(poller->sockets_ref != LUA_NOREF){
    luaL_unref(L, LUAZMQ_LUA_REGISTRY, poller->sockets_ref);
    poller->sockets_ref = LUA_NOREF;
  }
  return luazmq_pass(L);
}

/* method: closed */
static int luazmq_plr_closed (lua_State *L) {
  zpoller2 *poller = (zpoller2 *)luazmq_checkudatap (L, 1, LUAZMQ_POLLER2);
  luaL_argcheck (L, poller != NULL, 1, LUAZMQ_PREFIX"poller expected");
  lua_pushboolean(L, poller->handle == NULL);
  return 1;
}

/* method: add */
static int luazmq_plr_add(lua_State *L) {
  zpoller2 *poller = luazmq_getpoller2(L);
  short events     = luaL_checkinteger(L, 3);
  zsocket *sock    = NULL;
  socket_t fd      = 0;
  int ret;

  if(lua_isuserdata(L, 2)) sock = luazmq_getsocket_at(L, 2);
  else if(lua_isnumber(L, 2)) fd = lua_tonumber(L, 2);
  else return luazmq_typerror(L, 2, "number or ZMQ socket");

  if(sock){
    ret = zmq_poller_add(poller->handle, sock->skt, NULL, events);
    if(-1 != ret){
      luazmq_plr_save_socket(L, poller, sock->skt, 2);
    }
  }
  else{
    ret = zmq_poller_add_fd(poller->handle, fd, NULL, events);
  }

  if(-1 == ret){
    return luazmq_fail(L, NULL);
  }

  lua_settop(L, 1);
  return 1;
}

/* method: modify */
static int luazmq_plr_modify(lua_State *L){
  zpoller2 *poller = luazmq_getpoller2(L);
  short events     = luaL_checkinteger(L, 3);
  zsocket *sock    = NULL;
  socket_t fd      = 0;
  int ret;

  if(lua_isuserdata(L, 2)) sock = luazmq_getsocket_at(L, 2);
  else if(lua_isnumber(L, 2)) fd = lua_tonumber(L, 2);
  else return luazmq_typerror(L, 2, "number or ZMQ socket");

  if(sock){
    if(events != 0){
      ret = zmq_poller_modify(poller->handle, sock->skt, events);
    }
    else{
      ret = zmq_poller_remove(poller->handle, sock->skt);
      luazmq_plr_remove_socket(L, poller, sock->skt);
    }
  }
  else{
    if(events != 0){
      ret = zmq_poller_modify_fd(poller->handle, fd, events);
    }
    else{
      ret = zmq_poller_remove_fd(poller->handle, fd);
    }
  }

  if(-1 == ret){
    return luazmq_fail(L, NULL);
  }

  lua_settop(L, 1);
  return 1;
}

/* method: remove */
static int luazmq_plr_remove(lua_State *L) {
  zpoller2 *poller = luazmq_getpoller2(L);
  zsocket *sock    = NULL;
  socket_t fd      = 0;
  int ret;

  if(lua_isuserdata(L, 2)) sock = luazmq_getsocket_at(L, 2);
  else if(lua_isnumber(L, 2)) fd = lua_tonumber(L, 2);
  else return luazmq_typerror(L, 2, "number or ZMQ socket");

  if(sock){
    ret = zmq_poller_remove(poller->handle, sock->skt);
    luazmq_plr_remove_socket(L, poller, sock->skt);
  }
  else{
    ret = zmq_poller_remove_fd(poller->handle, fd);
  }

  if(-1 == ret){
    return luazmq_fail(L, NULL);
  }

  lua_settop(L, 1);
  return 1;
}

/* method: poll */
static int luazmq_plr_poll(lua_State *L) {
  zpoller2 *poller = luazmq_getpoller2(L);
  long timeout = luaL_checkinteger(L,2);
  int ret = zmq_poller_wait(poller->handle, &poller->events[0], timeout);

  if(-1 == ret){
    if(zmq_errno() == ETIMEDOUT){
      lua_pushboolean(L, 0);
      return 1;
    }
    return luazmq_fail(L, NULL);
  }

  luazmq_plr_push_event_socket(L, poller, &poller->events[0]);
  lua_pushinteger(L, poller->events[0].events);
  return 2;
}

static int luazmq_plr_count(lua_State *L) {
  zpoller2 *poller = luazmq_getpoller2(L);
  lua_pushinteger(L, poller->n_events);
  return 1;
}

static int luazmq_plr_tostring(lua_State *L) {
  zpoller2 *poller = (zpoller2 *)luazmq_checkudatap (L, 1, LUAZMQ_POLLER2);
  luaL_argcheck (L, poller != NULL, 1, LUAZMQ_PREFIX"poller expected");
  if(!poller->handle){
    lua_pushfstring(L, LUAZMQ_PREFIX"Poller (%p) - closed", poller);
  }
  else{
    lua_pushfstring(L, LUAZMQ_PREFIX"Poller (%p)", poller);
  }
  return 1;}

static const struct luaL_Reg luazmq_plr_methods[] = {
  {"add",              luazmq_plr_add              },
  {"modify",           luazmq_plr_modify           },
  {"remove",           luazmq_plr_remove           },
  {"poll",             luazmq_plr_poll             },
  {"count",            luazmq_plr_count            },
  {"close",            luazmq_plr_close            },
  {"closed",           luazmq_plr_closed           },
  {"__gc",             luazmq_plr_close            },
  {"__tostring",       luazmq_plr_tostring         },
  {NULL,NULL}
};

static const luazmq_int_const poll_flags[] ={
  DEFINE_ZMQ_CONST(  POLLIN   ),
  DEFINE_ZMQ_CONST(  POLLOUT  ),
  DEFINE_ZMQ_CONST(  POLLERR  ),

  {NULL, 0}
};

void luazmq_poller2_initlib (lua_State *L, int nup){
#ifdef LUAZMQ_DEBUG
  int top = lua_gettop(L);
#endif

  luazmq_createmeta(L, LUAZMQ_POLLER2,  luazmq_plr_methods, nup);
  lua_pop(L, 1);

#ifdef LUAZMQ_DEBUG
  assert(top == (lua_gettop(L) + nup));
#endif

  luazmq_register_consts(L, poll_flags);
}

#endif
