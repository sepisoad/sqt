#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "foo.h"

char* c_up(const char* str) {
    char* upper_str = (char*)malloc(strlen(str) + 1);
    if (!upper_str) return NULL;

    for (int i = 0; str[i]; i++) {
        upper_str[i] = toupper((unsigned char)str[i]);
    }

    upper_str[strlen(str)] = '\0';
    return upper_str;
}

int l_up(lua_State *L) {
    const char *input = luaL_checkstring(L, 1);
    char *result = c_up(input);
    lua_pushstring(L, result);
    free(result);
    return 1;
}

// Register the functions to a Lua module
int module_foo(lua_State *L) {
    static const luaL_Reg _module[] = {
        {"to_uppercase", l_up},
        {NULL, NULL}  // End marker
    };

    luaL_newlib(L, _module);
    return 1;
}
