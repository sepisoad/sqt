#pragma once

#include <lua5.4/lua.h>
#include <lua5.4/lauxlib.h>
#include <lua5.4/lualib.h>

#ifdef _WIN32
#define MODULE_EXPORT __declspec (dllexport)
#else
#define MODULE_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

  MODULE_EXPORT int open_module_spng(lua_State * L);

#ifdef __cplusplus
}
#endif
