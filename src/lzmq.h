#ifndef _LZMQ_H_
#define _LZMQ_H_
#include "lua.h"
#include "zmq.h"

#if defined (_WIN32) || defined (_WINDOWS)
#  define __WINDOWS__
#endif

#ifdef _MSC_VER
#  define LUAZMQ_EXPORT __declspec(dllexport)
#else
#  define LUAZMQ_EXPORT
#endif


#define LUAZMQ_PREFIX  "LuaZMQ3: "

typedef unsigned char uchar;
#define LUAZMQ_FLAG_CLOSED       (uchar)0x01
/*context only*/
#define LUAZMQ_FLAG_DONT_DESTROY (uchar)0x02
/*socket only*/
#define LUAZMQ_FLAG_MORE         (uchar)0x02

typedef struct{
  void  *ctx;
  uchar flags;
#ifdef LZMQ_DEBUG
  int socket_count;
#endif
  int autoclose_ref;
} zcontext;

typedef struct{
  void  *skt;
  uchar flags;
#ifdef LZMQ_DEBUG
  zcontext *ctx;
#endif
  int onclose_ref;
} zsocket;

typedef struct{
  int no;
} zerror;

struct ZMQ_Poller;
typedef struct ZMQ_Poller zpoller;

typedef struct{
  zmq_msg_t msg;
  uchar flags;
} zmessage;

extern const char *LUAZMQ_CONTEXT;
extern const char *LUAZMQ_SOCKET;
extern const char *LUAZMQ_ERROR;
extern const char *LUAZMQ_POLLER;
extern const char *LUAZMQ_MESSAGE;

zcontext *luazmq_getcontext_at (lua_State *L, int i);
#define luazmq_getcontext(L) luazmq_getcontext_at((L),1)

zsocket *luazmq_getsocket_at (lua_State *L, int i);
#define luazmq_getsocket(L) luazmq_getsocket_at((L),1)

zerror *luazmq_geterror_at (lua_State *L, int i);
#define luazmq_geterror(L) luazmq_geterror_at((L),1) 

zpoller *luazmq_getpoller_at (lua_State *L, int i);
#define luazmq_getpoller(L) luazmq_getpoller_at((L),1)

zmessage *luazmq_getmessage_at (lua_State *L, int i);
#define luazmq_getmessage(L) luazmq_getmessage_at((L),1)


int luazmq_pass(lua_State *L);
int luazmq_fail_str(lua_State *L, zsocket *skt);
int luazmq_fail_obj(lua_State *L, zsocket *skt);
int luazmq_fail_no(lua_State *L, zsocket *skt);

#if   defined LUAZMQ_USE_ERR_TYPE_OBJECT
#  define luazmq_fail luazmq_fail_obj
#elif defined LUAZMQ_USE_ERR_TYPE_NUMBER 
#  define luazmq_fail luazmq_fail_no
#elif defined LUAZMQ_USE_ERR_TYPE_STRING
#  define luazmq_fail luazmq_fail_str
#else /* default */
#  define luazmq_fail luazmq_fail_no
#endif

int luazmq_allocfail(lua_State *L);

#endif