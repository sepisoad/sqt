#include <stdint.h>
#include <stdbool.h>
#include <lua5.4/lua.h>
#include <lua5.4/lauxlib.h>
#include <lua5.4/lualib.h>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "img_decoders.h"
#include "img_encoders.h"
#include "img.h"

const char* _errors[] = {
  /*00*/"l_encode_paletted_png: Expected a string (path)",
  /*01*/"l_encode_paletted_png: Expected a table (palette)",
  /*02*/"l_encode_paletted_png: Expected a table (pixels)",
  /*03*/"l_encode_paletted_png: Expected a number (width)",
  /*04*/"l_encode_paletted_png: Expected a number (height)",
  /*05*/"l_encode_paletted_png: Pixel element is not a number",
  /*06*/"l_encode_paletted_png: Palette element is not a RGB value",
  /*07*/"l_encode_paletted_png: Palette element RGB field is not a number",
  /*08*/"c_encode_paletted_png: FAILED TODO",
};

typedef struct RGB_t { uint8_t R; uint8_t G; uint8_t B; } RGB_t;

// C level functions
static int8_t c_encode_paletted_png(
  const char* path,
  const uint8_t* pixels,
  uint32_t width,
  uint32_t height
) {
  if (!stbi_write_png(path, width, height, 3, pixels, width * 3)) {
    return 7;
  }

  return -1;
}

// Lua level functions
static int l_encode_paletted_png(lua_State* L) {
  const uint8_t channels = 3;
  int8_t _erridx = -1;
  RGB_t* palette = NULL;
  uint8_t* pixels = NULL;

  // validate parameters type
  if (!lua_isstring(L, 1)) { _erridx = 0; goto cleanup; }
  if (!lua_istable(L, 2)) { _erridx = 1; goto cleanup; }
  if (!lua_istable(L, 3)) { _erridx = 2; goto cleanup; }
  if (!lua_isinteger(L, 4)) { _erridx = 3; goto cleanup; }
  if (!lua_isinteger(L, 5)) { _erridx = 4; goto cleanup; }

  const char* path = luaL_checkstring(L, 1);
  int palette_len = luaL_len(L, 2);
  int pixels_len = luaL_len(L, 3);
  int width = luaL_checkinteger(L, 4);
  int height = luaL_checkinteger(L, 5);

  // read palette values into memory
  palette = malloc(sizeof(RGB_t) * palette_len);
  for (int palette_index = 1; palette_index <= palette_len; palette_index++) {
    lua_rawgeti(L, 2, palette_index);
    if (!lua_istable(L, -1)) {
      lua_pop(L, 1);
      _erridx = 5;
      goto cleanup;
    }

    lua_getfield(L, -1, "Red");
    lua_getfield(L, -2, "Green");
    lua_getfield(L, -3, "Blue");

    if (!lua_isnumber(L, -3) || !lua_isnumber(L, -2) || !lua_isnumber(L, -1)) {
      lua_pop(L, 4);
      _erridx = 6;
      goto cleanup;
    }

    palette[palette_index-1].R = (uint8_t)lua_tonumber(L, -3);
    palette[palette_index-1].G = (uint8_t)lua_tonumber(L, -2);
    palette[palette_index-1].B = (uint8_t)lua_tonumber(L, -1);
    lua_pop(L, 4);
  }

  // read pixel values into memory
  pixels = malloc(sizeof(uint8_t) * channels * pixels_len);
  for (int pixel_index = 1; pixel_index <= pixels_len; pixel_index++) {
    lua_rawgeti(L, 3, pixel_index);

    if (!lua_isnumber(L, -1)) {
      lua_pop(L, 1);
      _erridx = 4;
      goto cleanup;
    }

    uint8_t palette_index = (uint8_t)lua_tonumber(L, -1);
    int img_index = (pixel_index - 1) * 3;
    pixels[img_index] = palette[palette_index].R;
    pixels[img_index + 1] = palette[palette_index].G;
    pixels[img_index + 2] = palette[palette_index].B;

    lua_pop(L, 1);
  }

  // do the actual processing:
  if (c_encode_paletted_png(path, pixels, width, height) >= 0) {
    goto cleanup;
  }


cleanup:
  if (palette) {
    free(palette);
  }
  if (pixels) {
    free(pixels);
  }
  if (_erridx >= 0) {
    printf("_erridx: %d\n", _erridx);
    return luaL_error(L, _errors[_erridx]);
  };
  return 0;
}

// Module
static const struct luaL_Reg module[] = {
  { "encode_paletted_png", l_encode_paletted_png },
  { NULL, NULL },
};

static int define_module(lua_State* L) {
  luaL_newlib(L, module);
  return 1;
}

static int register_foo(lua_State* L) {
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "preload");
  lua_pushcfunction(L, define_module);
  lua_setfield(L, -2, "stb");
  lua_pop(L, 2);
}

MODULE_EXPORT int open_module_stb(lua_State* L) {
  int res = define_module(L);
  if (res == 1) register_foo(L);
  return res;
}