#include <stdint.h>
#include <string.h>

#include "spng.h"
#include "module.h"

#define MAX_ALLOWED_PALETTE_SIZE 256

typedef enum {
  ERR_NONE = 0,
  ERR_INVALID_PALETTE_SIZE,
  ERR_FAILED_TO_SET_PNG_HEADER,
  ERR_FAILED_TO_SET_PNG_OPTION,
  ERR_FAILED_TO_SET_PNG_BUFFER,
  ERR_FAILED_TO_SET_PNG_PALETTE,
  ERR_FAILED_TO_CALC_IMG_SIZE,
  ERR_FAILED_TO_DECODE_IMG,
  ERR_FAILED_TO_ENCODE_DATA,
  ERR_FAILED_TO_RETURN_DATA,
  ERR_INVALID_ARG,
  ERR_INVALID_TYPE,
} err_t;

typedef struct {
  uint8_t r, g, b;
} l_RGB_t;

static err_t _create_palette(struct spng_plte* plte, const l_RGB_t* plt_colors, size_t plt_size) {
  if (plt_size > MAX_ALLOWED_PALETTE_SIZE) {
    // TODO: log something
    return ERR_INVALID_PALETTE_SIZE;
  }

  plte->n_entries = (uint32_t)plt_size;
  for (int idx = 0; idx < plt_size; idx++) {
    plte->entries[idx].red = plt_colors[idx].r;
    plte->entries[idx].green = plt_colors[idx].g;
    plte->entries[idx].blue = plt_colors[idx].b;
    plte->entries[idx].alpha = 0;
  }

  return ERR_NONE;
}

static err_t c_convert(
  const void* img,
  size_t img_size,
  int img_width,
  int img_height,
  const l_RGB_t* plt_colors,
  size_t plt_size,
  void** out,
  size_t* out_size)
{
  err_t err = ERR_NONE;
  spng_ctx* ctx = spng_ctx_new(SPNG_CTX_ENCODER);
  struct spng_ihdr ihdr;
  struct spng_plte plte;

  ihdr.width = img_width;
  ihdr.height = img_height;
  ihdr.bit_depth = 8;
  ihdr.color_type = SPNG_COLOR_TYPE_INDEXED;
  ihdr.compression_method = 0;
  ihdr.filter_method = 0;
  ihdr.interlace_method = 0;

  do {
    err = _create_palette(&plte, plt_colors, plt_size);
    if (err != ERR_NONE) break;

    if (spng_set_ihdr(ctx, &ihdr) != 0) {
      err = ERR_FAILED_TO_SET_PNG_BUFFER;
      break;
    }

    if (spng_set_option(ctx, SPNG_ENCODE_TO_BUFFER, 1) != 0) {
      err = ERR_FAILED_TO_SET_PNG_OPTION;
      break;
    }

    if (spng_set_plte(ctx, &plte) != 0) {
      err = ERR_FAILED_TO_SET_PNG_PALETTE;
      break;
    }

    if (spng_encode_image(ctx, img, img_size, SPNG_FMT_PNG, SPNG_ENCODE_FINALIZE) != 0) {
      err = ERR_FAILED_TO_SET_PNG_OPTION;
      break;
    }

    void* png_buffer;
    size_t png_size;
    int spng_err;
    *out = spng_get_png_buffer(ctx, out_size, &spng_err);
    if (spng_err && spng_err != 0) {
      printf("SPNG ERR: %s\n", spng_strerror(spng_err));
      err = ERR_FAILED_TO_ENCODE_DATA;
      break;
    }
  } while (0);

  spng_ctx_free(ctx);
  return err;
}

static int l_convert(lua_State* L) {
  err_t err = ERR_NONE;
  size_t out_size;
  size_t img_size;
  size_t plt_size;
  l_RGB_t* plt_colors = NULL;
  void* out = NULL;

  do {
    const char* img_buf = luaL_checklstring(L, 1, &img_size);
    if (img_buf == NULL) {
      err = ERR_INVALID_ARG;
      break;
    }


    int img_width = luaL_checkinteger(L, 2);
    if (img_width <= 0) {
      err = ERR_INVALID_ARG;
      break;
    }

    int img_height = luaL_checkinteger(L, 3);
    if (img_height <= 0) {
      err = ERR_INVALID_ARG;
      break;
    }

    plt_size = (size_t)lua_rawlen(L, 4);
    if (plt_size <= 0) {
      err = ERR_INVALID_ARG;
      break;
    }

    // l_RGB_t* plt_colors = malloc(plt_size * sizeof(l_RGB_t));
    l_RGB_t* plt_colors = malloc(MAX_ALLOWED_PALETTE_SIZE * sizeof(l_RGB_t));

    for (int i = 0; i < plt_size; ++i) {
      int typ = lua_rawgeti(L, 4, i + 1);
      if (typ != LUA_TTABLE) {
        err = ERR_INVALID_ARG;
        break;
      }

      typ = lua_getfield(L, -1, "r");
      if (typ != LUA_TNUMBER) {
        err = ERR_INVALID_ARG;
        break;
      }
      plt_colors[i].r = (unsigned char)lua_tointeger(L, -1);
      lua_pop(L, 1);

      typ = lua_getfield(L, -1, "g");
      if (typ != LUA_TNUMBER) {
        err = ERR_INVALID_ARG;
        break;
      }
      plt_colors[i].g = (unsigned char)lua_tointeger(L, -1);
      lua_pop(L, 1); // Remove g from the stack

      typ = lua_getfield(L, -1, "b");
      if (typ != LUA_TNUMBER) {
        err = ERR_INVALID_ARG;
        break;
      }
      plt_colors[i].b = (unsigned char)lua_tointeger(L, -1);
      lua_pop(L, 1); // Remove b from the stack

      lua_pop(L, 1); // Remove the table element
    }

    err = c_convert(
      img_buf,
      img_size,
      img_width,
      img_height,
      plt_colors,
      plt_size,
      &out,
      &out_size
    );
    if (err != ERR_NONE) {
      break;
    }

    // lua_settop(L, 0);
    
    if (lua_pushlstring(L, out, out_size) == NULL) {
      err = ERR_FAILED_TO_RETURN_DATA;
      break;
    }
    
  } while (0);

  if (plt_colors) free(plt_colors);
  if (out) free(out);

  if (err != ERR_NONE) {
    printf("err: spng module: code[%d]\n", err);
    return err;
  }

  return 1;
}

static const struct luaL_Reg lib[] = {
  { "convert", l_convert},
  { NULL, NULL },
};


static int define_module(lua_State* L) {
  luaL_newlib(L, lib);
  return 1;
}

static int register_foo(lua_State* L) {
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "preload");
  lua_pushcfunction(L, define_module);
  lua_setfield(L, -2, "spng");
  lua_pop(L, 2);
}

MODULE_EXPORT int open_module_spng(lua_State * L) {
  int res = define_module(L);
    if (res == 1) {
        register_foo(L);
    }
    return res;
}