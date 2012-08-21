#include "lzutils.h"
#include <memory.h>
#include <assert.h>

#if LUA_VERSION_NUM >= 502 

int luazmq_typerror (lua_State *L, int narg, const char *tname) {
  const char *msg = lua_pushfstring(L, "%s expected, got %s", tname,
      luaL_typename(L, narg));
  return luaL_argerror(L, narg, msg);
}

#else 

void luazmq_setfuncs (lua_State *L, const luaL_Reg *l, int nup){
  luaL_checkstack(L, nup, "too many upvalues");
  for (; l->name != NULL; l++) {  /* fill the table with given functions */
    int i;
    for (i = 0; i < nup; i++)  /* copy upvalues to the top */
      lua_pushvalue(L, -nup);
    lua_pushcclosure(L, l->func, nup);  /* closure with those upvalues */
    lua_setfield(L, -(nup + 2), l->name);
  }
  lua_pop(L, nup);  /* remove upvalues */
}

void luazmq_rawgetp(lua_State *L, int index, const void *p){
  index = luazmq_absindex(L, index);
  lua_pushlightuserdata(L, (void *)p);
  lua_rawget(L, index);
}

void luazmq_rawsetp (lua_State *L, int index, const void *p){
  index = luazmq_absindex(L, index);
  lua_pushlightuserdata(L, (void *)p);
  lua_insert(L, -2);
  lua_rawset(L, index);
}

#endif

int luazmq_newmetatablep (lua_State *L, const void *p) {
  luazmq_rawgetp(L, LUA_REGISTRYINDEX, p);
  if (!lua_isnil(L, -1))  /* name already in use? */
    return 0;  /* leave previous value on top, but return 0 */
  lua_pop(L, 1);

  lua_newtable(L);  /* create metatable */
  lua_pushvalue(L, -1); /* duplicate metatable to set*/
  luazmq_rawsetp(L, LUA_REGISTRYINDEX, p);

  return 1;
}

void luazmq_getmetatablep (lua_State *L, const void *p) {
  lua_pushlightuserdata(L, (void *)p);
  lua_rawget(L, LUA_REGISTRYINDEX);
}

int luazmq_isudatap (lua_State *L, int ud, const void *p) {
  if (lua_isuserdata(L, ud)){
    if (lua_getmetatable(L, ud)) {           /* does it have a metatable? */
      int res;
      luazmq_rawgetp(L,LUA_REGISTRYINDEX,p); /* get correct metatable */
      res = lua_rawequal(L, -1, -2);         /* does it have the correct mt? */
      lua_pop(L, 2);                         /* remove both metatables */
      return res;
    }
  }
  return 0;
}

void *luazmq_checkudatap (lua_State *L, int ud, const void *p) {
  void *up = lua_touserdata(L, ud);
  if (up != NULL) {  /* value is a userdata? */
    if (lua_getmetatable(L, ud)) {  /* does it have a metatable? */
      luazmq_rawgetp(L,LUA_REGISTRYINDEX,p); /* get correct metatable */
      if (lua_rawequal(L, -1, -2)) {  /* does it have the correct mt? */
        lua_pop(L, 2);  /* remove both metatables */
        return up;
      }
    }
  }
  luazmq_typerror(L, ud, p);  /* else error */
  return NULL;  /* to avoid warnings */
}

int luazmq_createmeta (lua_State *L, const char *name, const luaL_Reg *methods) {
  if (!luazmq_newmetatablep(L, name))
    return 0;

  /* define methods */
  luazmq_setfuncs (L, methods, 0);

  /* define metamethods */
  lua_pushliteral (L, "__index");
  lua_pushvalue (L, -2);
  lua_settable (L, -3);

  lua_pushliteral (L, "__metatable");
  lua_pushliteral (L, "you're not allowed to get this metatable");
  lua_settable (L, -3);

  return 1;
}

void luazmq_setmeta (lua_State *L, const char *name) {
  luazmq_getmetatablep(L, name);
  assert(lua_istable(L,-1));
  lua_setmetatable (L, -2);
}

void *luazmq_newudata_(lua_State *L, size_t size, const char *name){
  void *obj = lua_newuserdata (L, size);
  memset(obj, 0, size);
  luazmq_setmeta(L, name);
  return obj;
}

void luazmq_register_consts(lua_State *L, const luazmq_int_const *c){
  const luazmq_int_const *v;
  for(v = c; v->name; ++v){
    lua_pushinteger(L, v->value);
    lua_setfield(L, -2, v->name);
  }
}

void luazmq_register_consts_invers(lua_State *L, const luazmq_int_const *c){
  const luazmq_int_const *v;
  for(v = c; v->name; ++v){
    lua_pushstring(L, v->name);
    lua_rawseti(L, -2, v->value);
  }
}

