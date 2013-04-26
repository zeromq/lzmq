#include "zmq.h"
#include "zmq_utils.h"
#include "lzutils.h"
#include "lzmq.h"
#include "zerror.h"
#include "zmsg.h"
#include "zcontext.h"
#include "zsocket.h"
#include "poller.h"
#include "zpoller.h"
#include <assert.h>

const char *LUAZMQ_CONTEXT = LUAZMQ_PREFIX "Context";
const char *LUAZMQ_SOCKET  = LUAZMQ_PREFIX "Socket";
const char *LUAZMQ_ERROR   = LUAZMQ_PREFIX "Error";
const char *LUAZMQ_POLLER  = LUAZMQ_PREFIX "Poller";
const char *LUAZMQ_MESSAGE = LUAZMQ_PREFIX "Message";

static const char *LUAZMQ_STOPWATCH = LUAZMQ_PREFIX "stopwatch";

//-----------------------------------------------------------  
// common
//{----------------------------------------------------------

int luazmq_pass(lua_State *L){
  lua_pushboolean(L, 1);
  return 1;
}

static int luazmq_geterrno(lua_State *L, zsocket *skt){
  int err = zmq_errno();
  if(skt && (err == ETERM)){
    if(!(skt->flags & LUAZMQ_FLAG_CLOSED)){
      /*int ret = */zmq_close(skt->skt);
      skt->flags |= LUAZMQ_FLAG_CLOSED;
      luazmq_skt_before_close(L, skt);
#ifdef LZMQ_DEBUG
      skt->ctx->socket_count--;
#endif
    }
  }
  return err;
}

int luazmq_fail_str(lua_State *L, zsocket *skt){
  int err = luazmq_geterrno(L, skt);
  lua_pushnil(L);
  luazmq_error_pushstring(L, err);
  return 2;
}

int luazmq_fail_no(lua_State *L, zsocket *skt){
  int err = luazmq_geterrno(L, skt);
  lua_pushnil(L);
  lua_pushinteger(L, err);
  return 2;
}

int luazmq_fail_obj(lua_State *L, zsocket *skt){
  int err = luazmq_geterrno(L, skt);
  lua_pushnil(L);
  luazmq_error_create(L, err);
  return 2;
}

int luazmq_allocfail(lua_State *L){
  lua_pushliteral(L, "can not allocate enouth memory");
  return lua_error(L);
}

zcontext *luazmq_getcontext_at (lua_State *L, int i) {
 zcontext *ctx = (zcontext *)luazmq_checkudatap (L, i, LUAZMQ_CONTEXT);
 luaL_argcheck (L, ctx != NULL, 1, LUAZMQ_PREFIX"context expected");
 luaL_argcheck (L, !(ctx->flags & LUAZMQ_FLAG_CLOSED), 1, LUAZMQ_PREFIX"connection is closed");
 return ctx;
}

zsocket *luazmq_getsocket_at (lua_State *L, int i) {
 zsocket *skt = (zsocket *)luazmq_checkudatap (L, i, LUAZMQ_SOCKET);
 luaL_argcheck (L, skt != NULL, 1, LUAZMQ_PREFIX"socket expected");
 luaL_argcheck (L, !(skt->flags & LUAZMQ_FLAG_CLOSED), 1, LUAZMQ_PREFIX"socket is closed");
 return skt;
}

zerror *luazmq_geterror_at (lua_State *L, int i) {
  zerror *err = (zerror *)luazmq_checkudatap (L, i, LUAZMQ_ERROR);
  luaL_argcheck (L, err != NULL, 1, LUAZMQ_PREFIX"error object expected");
  return err;
}

zpoller *luazmq_getpoller_at (lua_State *L, int i) {
  zpoller *poller = (zpoller *)luazmq_checkudatap (L, i, LUAZMQ_POLLER);
  luaL_argcheck (L, poller != NULL, 1, LUAZMQ_PREFIX"poller expected");
  luaL_argcheck (L, poller->items != NULL, 1, LUAZMQ_PREFIX"poller is closed");
  return poller;
}

zmessage *luazmq_getmessage_at (lua_State *L, int i) {
  zmessage *zmsg = (zmessage *)luazmq_checkudatap (L, i, LUAZMQ_MESSAGE);
  luaL_argcheck (L, zmsg != NULL, 1, LUAZMQ_PREFIX"message expected");
  luaL_argcheck (L, !(zmsg->flags & LUAZMQ_FLAG_CLOSED), 1, LUAZMQ_PREFIX"message is closed");
  return zmsg;
}

//}----------------------------------------------------------

//-----------------------------------------------------------  
// zmq.utils
//{----------------------------------------------------------

typedef void* zstopwatch;

static int luazmq_stopwatch_create(lua_State *L){
  zstopwatch *timer = luazmq_newudata(L, zstopwatch, LUAZMQ_STOPWATCH);
  *timer = NULL;
  return 1;
}

static int luazmq_stopwatch_start(lua_State *L){
  zstopwatch *timer = luazmq_checkudatap(L, 1, LUAZMQ_STOPWATCH);
  luaL_argcheck (L, *timer == NULL, 1, LUAZMQ_PREFIX"timer alrady started");
  *timer = zmq_stopwatch_start();
  return 1;
}

static int luazmq_stopwatch_stop(lua_State *L){
  zstopwatch *timer = luazmq_checkudatap(L, 1, LUAZMQ_STOPWATCH);
  luaL_argcheck (L, *timer != NULL, 1, LUAZMQ_PREFIX"timer not started");
  lua_pushnumber(L, zmq_stopwatch_stop(*timer));
  *timer = NULL;
  return 1;
}

static int luazmq_stopwatch_close(lua_State *L){
  zstopwatch *timer = luazmq_checkudatap(L, 1, LUAZMQ_STOPWATCH);
  if(*timer){
    zmq_stopwatch_stop(*timer);
    *timer = NULL;
  }
  return luazmq_pass(L);
}

static int luazmq_utils_sleep(lua_State *L){
  int sec = luaL_checkint(L, 1);
  zmq_sleep(sec);
  return luazmq_pass(L);
}

static const struct luaL_Reg luazmq_utilslib[]   = {
  { "stopwatch",    luazmq_stopwatch_create },
  { "sleep",        luazmq_utils_sleep },

  {NULL, NULL}
};

static const struct luaL_Reg luazmq_stopwatch_methods[] = {
  {"start",    luazmq_stopwatch_start },
  {"stop",     luazmq_stopwatch_stop  },
  {"__gc",     luazmq_stopwatch_close },

  {NULL,NULL}
};

static void luazmq_zutils_initlib(lua_State *L){
  luazmq_createmeta(L, LUAZMQ_STOPWATCH, luazmq_stopwatch_methods);
  lua_pop(L, 1);
  lua_newtable(L);
  luazmq_setfuncs(L, luazmq_utilslib, 0);
  lua_setfield(L,-2, "utils");
}

//}

//-----------------------------------------------------------  
// zmq
//{----------------------------------------------------------

static int luazmq_version(lua_State *L){
  int major, minor, patch;
  zmq_version (&major, &minor, &patch); 
  lua_newtable(L);
  lua_pushinteger(L, major); lua_rawseti(L, -2, 1);
  lua_pushinteger(L, minor); lua_rawseti(L, -2, 2);
  lua_pushinteger(L, patch); lua_rawseti(L, -2, 3);
  return 1;
}

static int luazmq_device(lua_State *L){
  int device_type = luaL_checkint(L,1);
  zsocket *fe = luazmq_getsocket_at(L,2);
  zsocket *be = luazmq_getsocket_at(L,3);
  int ret = zmq_device(device_type, fe->skt, be->skt);
  if (ret == -1) return luazmq_fail(L,NULL);

  assert(0 && "The zmq_device() function always returns -1 and errno set to ETERM");
  return luazmq_pass(L);
}

#if(ZMQ_VERSION_MAJOR >= 3)&&(ZMQ_VERSION_MINOR >= 3)
static int luazmq_proxy(lua_State *L){
  zsocket *fe = luazmq_getsocket_at(L,1);
  zsocket *be = luazmq_getsocket_at(L,2);
  zsocket *cp = NULL;
  int ret;
  if(!lua_isnoneornil(L,3)) cp = luazmq_getsocket_at(L,3);
  ret = zmq_proxy(fe->skt, be->skt, cp ? (cp->skt) : NULL);
  if (ret == -1) return luazmq_fail(L,NULL);

  assert(0 && "The zmq_proxy() function always returns -1 and errno set to ETERM");
  return luazmq_pass(L);
}
#endif

static int luazmq_error_create_(lua_State *L){
  int err = luaL_checkint(L, 1);
  return luazmq_error_create(L, err);
}

static int luazmq_error_tostring(lua_State *L){
  int err = luaL_checkint(L, 1);
  luazmq_error_pushstring(L, err);
  return 1;
}

//}----------------------------------------------------------  

static const struct luaL_Reg luazmqlib[]   = {
  { "version",        luazmq_version          },

#if(ZMQ_VERSION_MAJOR >= 3)&&(ZMQ_VERSION_MINOR >= 3)
  { "proxy",          luazmq_proxy           },
#endif

  { "device",         luazmq_device           },
  { "assert",         luazmq_assert           },
  { "error",          luazmq_error_create_    },
  { "strerror",       luazmq_error_tostring   },
  { "context",        luazmq_context_create   },
  { "poller",         luazmq_poller_create    },
  { "init",           luazmq_context_init     },
  { "init_ctx",       luazmq_init_ctx         },
  { "msg_init",       luazmq_msg_init         },
  { "msg_init_size",  luazmq_msg_init_size    },
  { "msg_init_data",  luazmq_msg_init_data    },
  { "msg_init_data_multi",  luazmq_msg_init_data_multi    },
  { "msg_init_data_array",  luazmq_msg_init_data_array    },

  {NULL, NULL}
};

const luazmq_int_const device_types[] ={
  DEFINE_ZMQ_CONST(  STREAMER  ),
  DEFINE_ZMQ_CONST(  FORWARDER ),
  DEFINE_ZMQ_CONST(  QUEUE     ),

  {NULL, 0}
};

static void luazmq_init_lib(lua_State *L){
  lua_newtable(L); 
  luazmq_context_initlib(L);
  luazmq_socket_initlib(L);
  luazmq_poller_initlib(L);
  luazmq_error_initlib(L);
  luazmq_message_initlib(L);
  luazmq_zutils_initlib(L);

  luazmq_register_consts(L, device_types);

  luazmq_setfuncs(L, luazmqlib, 0);
}

LUAZMQ_EXPORT int luaopen_lzmq (lua_State *L){
  LUAZMQ_STATIC_ASSERT(offsetof(zsocket, skt) == 0);

  luazmq_init_lib(L);
  return 1;
}
