#include "zcontext.h"
#include "lzutils.h"
#include "lzmq.h"

int luazmq_context_create (lua_State *L) {
  zcontext *zctx = luazmq_newudata(L, zcontext, LUAZMQ_CONTEXT);
  zctx->ctx = zmq_ctx_new();
  return 1;
}

int luazmq_context_init (lua_State *L) {
  zcontext *zctx = luazmq_newudata(L, zcontext, LUAZMQ_CONTEXT);
  int n = luaL_optint(L, 1, 1);
  zctx->ctx = zmq_init(n);
  return 1;
}

int luazmq_init_ctx (lua_State *L) {
  zcontext *src_ctx = (zcontext *)lua_touserdata(L,1);
  if(src_ctx){
    zcontext *zctx = luazmq_newudata(L, zcontext, LUAZMQ_CONTEXT);
    zctx->ctx = src_ctx->ctx;
    zctx->flags = LUAZMQ_FLAG_DONT_DESTROY;
    return 1;
  }
  luaL_argcheck(L, 0, 1, "lightuserdata expected");
  return 0;
}

static int luazmq_ctx_lightuserdata(lua_State *L) {
  zcontext *zctx = luazmq_getcontext(L);
  lua_pushlightuserdata(L, zctx);
  return 1;
}

static int luazmq_ctx_tostring(lua_State *L) {
  zcontext *ctx = luazmq_getcontext(L);
  lua_pushstring(L, LUAZMQ_CONTEXT);
  return 1;
}

static int luazmq_ctx_set (lua_State *L) {
  zcontext *ctx = luazmq_getcontext(L);
  int option_name  = luaL_checkint(L, 2);
  int option_value = luaL_checkint(L, 3);
  int ret = zmq_ctx_set(ctx->ctx,option_name,option_value);
  if (ret == -1) return luazmq_fail(L,NULL);
  return luazmq_pass(L);
}

static int luazmq_ctx_get (lua_State *L) {
  zcontext *ctx = luazmq_getcontext(L);
  int option_name  = luaL_checkint(L, 2);
  int ret = zmq_ctx_get(ctx->ctx,option_name);
  if (ret == -1) return luazmq_fail(L,NULL);
  lua_pushinteger(L, ret);
  return 1;
}

static int luazmq_ctx_destroy (lua_State *L) {
  zcontext *ctx = (zcontext *)luazmq_checkudatap (L, 1, LUAZMQ_CONTEXT);
  luaL_argcheck (L, ctx != NULL, 1, LUAZMQ_PREFIX"context expected");
  if(!(ctx->flags & LUAZMQ_FLAG_CLOSED)){
    if(!(ctx->flags & LUAZMQ_FLAG_DONT_DESTROY)){
      int ret = zmq_ctx_destroy(ctx->ctx);
      if(ret == -1)return luazmq_fail(L,NULL);
    }
    ctx->flags |= LUAZMQ_FLAG_CLOSED;
  }
  return luazmq_pass(L);
}

static int luazmq_ctx_closed (lua_State *L) {
  zcontext *ctx = (zcontext *)luazmq_checkudatap (L, 1, LUAZMQ_CONTEXT);
  luaL_argcheck (L, ctx != NULL, 1, LUAZMQ_PREFIX"context expected");
  lua_pushboolean(L, ctx->flags & LUAZMQ_FLAG_CLOSED);
  return 1;
}

static int luazmq_create_socket (lua_State *L) {
  zsocket *zskt;
  zcontext *ctx = luazmq_getcontext(L);
  int stype = luaL_checkint(L,2);
  void *skt = zmq_socket(ctx->ctx, stype);
  if(!skt)return luazmq_fail(L,NULL);

  zskt = luazmq_newudata(L, zsocket, LUAZMQ_SOCKET);
  zskt->skt = skt;

  return 1;
}

#define DEFINE_CTX_OPT(NAME, OPTNAME) \
  static int luazmq_ctx_set_##NAME(lua_State *L){\
    lua_pushinteger(L, OPTNAME);\
    lua_insert(L, 2);\
    return luazmq_ctx_set(L);\
  }\
  static int luazmq_ctx_get_##NAME(lua_State *L){\
    lua_pushinteger(L, OPTNAME);\
    return luazmq_ctx_get(L);\
  }

#define REGISTER_CTX_OPT(NAME) {"set_"#NAME, luazmq_ctx_set_##NAME}, {"get_"#NAME, luazmq_ctx_get_##NAME}

DEFINE_CTX_OPT(io_threads,  ZMQ_IO_THREADS)
DEFINE_CTX_OPT(max_sockets, ZMQ_MAX_SOCKETS)


static const struct luaL_Reg luazmq_ctx_methods[] = {
  {"set",           luazmq_ctx_set           },
  {"get",           luazmq_ctx_get           },
  {"socket",        luazmq_create_socket     },
  {"lightuserdata", luazmq_ctx_lightuserdata },

  REGISTER_CTX_OPT(io_threads),
  REGISTER_CTX_OPT(max_sockets),

  {"__gc",       luazmq_ctx_destroy},
  {"destroy",    luazmq_ctx_destroy},
  {"term",       luazmq_ctx_destroy},
  {"closed",     luazmq_ctx_closed },
  {NULL,NULL}
};

void luazmq_context_initlib (lua_State *L){
  luazmq_createmeta(L, LUAZMQ_CONTEXT, luazmq_ctx_methods);
  lua_pop(L, 1);
}
