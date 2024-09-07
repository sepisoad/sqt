#include <lua5.4/lua.h>
#include <lua5.4/lualib.h>
#include <lua5.4/lauxlib.h>

#include "libs/c/lfs/lfs.h"

int main(int argc, char ** argv) {

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);

    if (luaopen_lfs(L) != 1) {
      printf("err: failed to load lua lfs library");
    }

    if (luaL_dofile(L, "./src/test.lua") == LUA_OK) {
      printf(" === 1");      
    }

    lua_close(L);
    return 0;
}
