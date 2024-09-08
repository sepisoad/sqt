#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "foo.h"

static char* c_up(const char* str) {
    char* upper_str = (char*)malloc(strlen(str) + 1);
    if (!upper_str) return NULL;

    for (int i = 0; str[i]; i++) {
        upper_str[i] = toupper((unsigned char)str[i]);
    }

    upper_str[strlen(str)] = '\0';
    return upper_str;
}

static int l_up(lua_State *L) {
    const char *input = luaL_checkstring(L, 1);
    char *result = c_up(input);
    lua_pushstring(L, result);
    free(result);
    return 1;
}

static int define_module(lua_State *L) {
    static const luaL_Reg _module[] = {
        {"to_uppercase", l_up},
        {NULL, NULL}  // End marker
    };

    // define the module
    luaL_newlib(L, _module);    
    return 1;
}

static int register_foo(lua_State *L) {    
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    lua_pushcfunction(L, define_module);
    lua_setfield(L, -2, "foo");
    lua_pop(L, 2);
}

int open_module_foo(lua_State *L) {
    int res = define_module(L);
    if (res == 1) {
        register_foo(L);
    }
    return res;
}