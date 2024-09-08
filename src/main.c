#include <lua5.4/lua.h>
#include <lua5.4/lualib.h>
#include <lua5.4/lauxlib.h>

#include "libs/c/foo/foo.h"

int main(int argc, char **argv) {
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    open_module_foo(L);

    
    if (luaL_dofile(L, "./src/test.lua") != LUA_OK) {
        fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);  // Pop error message from stack
    }

    // Close the Lua state
    lua_close(L);
    return 0;
}
