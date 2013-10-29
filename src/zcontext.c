#include "zcontext.h"
#include "lzutils.h"
#include "lzmq.h"
#include <assert.h>

#if ZMQ_VERSION_MAJOR == 4
#  define LUAZMQ_SUPPORT_CTX_SHUTDOWN
#endif

// apply options for object on top of stack
// if set option fail call destroy method for object and return error
// unknown options are ignoring
static int apply_options(lua_State *L, int opt, const char *close_meth){
  if(lua_type(L, opt) == LUA_TTABLE){
    int o = lua_gettop(L);

    lua_pushnil(L);
    while (lua_next(L, opt) != 0){
      assert(lua_gettop(L) == (o+2));
      if(lua_type(L, -2) != LUA_TSTRING){
        lua_pop(L, 1);
        continue;
      }

      lua_pushliteral(L, "set_"); lua_pushvalue(L, -3); lua_concat(L, 2);
      lua_gettable(L, o);
      if(lua_isnil(L, -1)){
        lua_pop(L, 2);
        assert(lua_gettop(L) == (o+1));
        continue;
      }
      lua_insert(L, -2);
      lua_pushvalue(L, o); lua_insert(L, -2);
      lua_call(L, 2, 2);

      if(lua_isnil(L, -2)){
        lua_pushvalue(L, o);
        luazmq_pcall_method(L, close_meth, 0, 0, 0);
        return 2;
      }

      lua_pop(L, 2);
      assert(lua_gettop(L) == (o+1));
    }
    assert(lua_gettop(L) == o);
  }

  return 0;
}

static int apply_bind_connect(lua_State *L, int opt, const char *meth){
  if(lua_type(L, opt) == LUA_TTABLE){
    int o = lua_gettop(L);         // socket
    lua_getfield(L, opt, meth);
    if(!lua_isnil(L, -1)){         // socket, address
      lua_pushvalue(L, o);         // socket, address, socket
      lua_getfield(L, -1, meth);   // socket, address, socket, bind
      lua_insert(L, -3);           // socket, bind, address, socket
      lua_insert(L, -2);           // socket, bind, socket, address
      lua_call(L, 2, 3);
      if(lua_isnil(L, -3)){
        int n = lua_gettop(L);
        lua_pushvalue(L, o);
        luazmq_pcall_method(L, "close", 0, 0, 0);
        lua_settop(L, n);
        return 3;
      }
    }
    lua_settop(L, o);
  }
  return 0;
}

int luazmq_context_create (lua_State *L) {
  zcontext *zctx = luazmq_newudata(L, zcontext, LUAZMQ_CONTEXT);
  zctx->ctx = zmq_ctx_new();
  zctx->autoclose_ref = LUA_NOREF;

#if LZMQ_SOCKET_COUNT
  zctx->socket_count = 0;
#endif

  {int n = apply_options(L, 1, "destroy"); if(n != 0) return n;}

  return 1;
}

int luazmq_context_init (lua_State *L) {
  zcontext *zctx = luazmq_newudata(L, zcontext, LUAZMQ_CONTEXT);
  int n = luaL_optint(L, 1, 1);
  zctx->ctx = zmq_init(n);
  zctx->autoclose_ref = LUA_NOREF;

#if LZMQ_SOCKET_COUNT
  zctx->socket_count = 0;
#endif

  return 1;
}

int luazmq_init_ctx (lua_State *L) {
  zcontext *src_ctx = (zcontext *)lua_touserdata(L,1);
  if(src_ctx){
    zcontext *zctx = luazmq_newudata(L, zcontext, LUAZMQ_CONTEXT);
    zctx->ctx = src_ctx->ctx;
    zctx->flags = LUAZMQ_FLAG_DONT_DESTROY;
    zctx->autoclose_ref = LUA_NOREF;

#if LZMQ_SOCKET_COUNT
    zctx->socket_count = 0;
#endif

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

static int create_autoclose_list(lua_State *L){
  luazmq_new_weak_table(L, "k");
  return luaL_ref(L, lua_upvalueindex(1));
}

static void call_socket_destroy(lua_State *L){
  int top = lua_gettop(L);
  assert(luazmq_checkudatap (L, -1, LUAZMQ_SOCKET));
  lua_pushvalue(L, -1);
  luazmq_pcall_method(L, "close", 0, 0, 0);
  lua_settop(L, top);
}

static int luazmq_ctx_autoclose (lua_State *L) {
  zcontext *ctx = luazmq_getcontext(L);
  /*zsocket  *skt = */luazmq_getsocket_at(L,2);

  lua_settop(L, 2);

  if(LUA_NOREF == ctx->autoclose_ref){
    ctx->autoclose_ref = create_autoclose_list(L);
  }

  lua_rawgeti(L, lua_upvalueindex(1), ctx->autoclose_ref);
  lua_pushvalue(L, -2);
  lua_pushboolean(L, 1);
  lua_rawset(L, -3);
  lua_pop(L,1);

  return 0;
}

static int luazmq_ctx_close_sockets (lua_State *L, zcontext *ctx) {
  if(LUA_NOREF == ctx->autoclose_ref) return 0;

  lua_rawgeti(L, lua_upvalueindex(1), ctx->autoclose_ref);
  assert(lua_istable(L, -1));
  lua_pushnil(L);
  while(lua_next(L, -2)){
    lua_pop(L, 1); // we do not need value
    call_socket_destroy(L);
  }

  return 0;
}


#if LZMQ_SOCKET_COUNT

static int luazmq_ctx_skt_count (lua_State *L) {
  zcontext *ctx = luazmq_getcontext(L);
  lua_pushinteger(L, ctx->socket_count);
  return 1;
}

#endif

#ifdef LUAZMQ_SUPPORT_CTX_SHUTDOWN

static int luazmq_ctx_shutdown (lua_State *L) {
  zcontext *ctx = luazmq_getcontext(L);
  luazmq_ctx_close_sockets(L, ctx);
  if(!(ctx->flags & LUAZMQ_FLAG_DONT_DESTROY)){
    int ret = zmq_ctx_shutdown(ctx->ctx);
    if(ret == -1)return luazmq_fail(L,NULL);
  }
  ctx->flags |= LUAZMQ_FLAG_CTX_SHUTDOWN;
  return luazmq_pass(L);
}

static int luazmq_ctx_shutdowned (lua_State *L) {
  zcontext *ctx = (zcontext *)luazmq_checkudatap (L, 1, LUAZMQ_CONTEXT);
  luaL_argcheck (L, ctx != NULL, 1, LUAZMQ_PREFIX"context expected");
  lua_pushboolean(L, ctx->flags & LUAZMQ_FLAG_CTX_SHUTDOWN);
  return 1;
}

#endif

static int luazmq_ctx_destroy (lua_State *L) {
  zcontext *ctx = (zcontext *)luazmq_checkudatap (L, 1, LUAZMQ_CONTEXT);
  luaL_argcheck (L, ctx != NULL, 1, LUAZMQ_PREFIX"context expected");
  if(!(ctx->flags & LUAZMQ_FLAG_CLOSED)){
    luazmq_ctx_close_sockets(L, ctx);
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
  zskt->onclose_ref = LUA_NOREF;

#if LZMQ_SOCKET_COUNT
  ctx->socket_count++;
  zskt->ctx = ctx;
  assert(ctx->socket_count > 0);
#endif

  {
#ifdef LZMQ_DEBUG
    int top = lua_gettop(L);
#endif
    int n = apply_options(L, 3, "close");
    if(n != 0) return n;
    n = apply_bind_connect(L, 3, "bind");
    if(n != 0) return n;
    n = apply_bind_connect(L, 3, "connect");
    if(n != 0) return n;
#ifdef LZMQ_DEBUG
    assert(top == lua_gettop(L));
#endif
  }

#if LZMQ_AUTOCLOSE_SOCKET
  {
    int n, o = lua_gettop(L);
    lua_pushvalue(L, 1);
    lua_pushvalue(L, o);
    n = luazmq_pcall_method(L, "autoclose", 1, 0, 0);
    if(n != 0){
      int top = lua_gettop(L);
      lua_pushvalue(L, o);
      luazmq_pcall_method(L, "close", 0, 0, 0);
      lua_settop(L, top);
      return lua_error(L);
    }
    assert(o == lua_gettop(L));
  }
#endif

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
  {"lightuserdata", luazmq_ctx_lightuserdata },

#if LZMQ_SOCKET_COUNT
  {"socket_count",  luazmq_ctx_skt_count     },
#endif

  REGISTER_CTX_OPT(io_threads),
  REGISTER_CTX_OPT(max_sockets),

  {"closed",     luazmq_ctx_closed },
  {NULL,NULL}
};
static const struct luaL_Reg luazmq_ctx_methods_2[] = {
  {"socket",     luazmq_create_socket  },
  {"autoclose",  luazmq_ctx_autoclose  },
  {"__gc",       luazmq_ctx_destroy    },
  {"destroy",    luazmq_ctx_destroy    },
  {"term",       luazmq_ctx_destroy    },
#ifdef LUAZMQ_SUPPORT_CTX_SHUTDOWN
  {"shutdown",   luazmq_ctx_shutdown   },
  {"shutdowned", luazmq_ctx_shutdowned },
#endif
  {NULL,NULL}
};

void luazmq_context_initlib (lua_State *L){
  luazmq_createmeta(L, LUAZMQ_CONTEXT, luazmq_ctx_methods);
  lua_newtable(L);
  luazmq_setfuncs(L, luazmq_ctx_methods_2, 1);
  lua_pop(L, 1);
}
