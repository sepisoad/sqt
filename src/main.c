#include <lua5.4/lua.h>
#include <lua5.4/lualib.h>
#include <lua5.4/lauxlib.h>

#include "libs/c/foo/foo.h"

int main(int argc, char **argv) {

    // Initialize a new Lua state
    lua_State *L = luaL_newstate();

    // Open Lua standard libraries
    luaL_openlibs(L);

    // Add the 'foo' module to the package preload table
    lua_getglobal(L, "package");               // Get the 'package' table
    lua_getfield(L, -1, "preload");            // Get the 'package.preload' table
    lua_pushcfunction(L, module_foo);          // Push the C function (module_foo)
    lua_setfield(L, -2, "foo");                // Set it in the 'preload' table under 'foo'
    lua_pop(L, 2);                             // Pop the 'package' table from the stack

    // Execute the Lua script (test.lua)
    if (luaL_dofile(L, "./src/test.lua") != LUA_OK) {
        fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);  // Pop error message from stack
    }

    // Close the Lua state
    lua_close(L);
    return 0;
}
