#include <lua5.4/lua.h>
#include <lua5.4/lualib.h>
#include <lua5.4/lauxlib.h>

#include "libs/c/lfs/lfs.h"

#define ENTRY_SCRIPT "./src/init.lua"

int main(int argc, char **argv) {
    // init lua vm
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);

    // load custom modules
    open_module_lfs(L);

    // redirect input args to the main lua script
    for (int i = 0; i < argc; i++) {
      lua_pushstring(L, argv[i]);
      lua_rawseti(L, -2, i);
    }
    lua_setglobal(L, "arg");

    // run the entry script
    if (luaL_dofile(L, ENTRY_SCRIPT) != LUA_OK) {
        fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
    }

    // clean up
    lua_close(L);
    return 0;
}
