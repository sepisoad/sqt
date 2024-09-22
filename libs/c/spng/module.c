#include <stdint.h>
#include <string.h>

#include "spng.h"
#include "module.h"

#define MAX_ALLOWED_PALETTE_SIZE 256

typedef enum {
  ERR_NONE = 0,
  ERR_SPNG_FAILED,
  ERR_LUA_FAILED
} err_t;

typedef struct {
  uint8_t r, g, b;
} l_RGB_t;

static err_t _create_palette(
  struct spng_plte* plte,
  const l_RGB_t* plt_colors,
  size_t plt_size) {
  if (plt_size > MAX_ALLOWED_PALETTE_SIZE) {
    return ERR_SPNG_FAILED;
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

static int color_distance(l_RGB_t c1, uint8_t r, uint8_t g, uint8_t b) {
  return (c1.r - r) * (c1.r - r) + (c1.g - g) * (c1.g - g) + (c1.b - b) * (c1.b - b);
}

static void palette_quantize(
  const uint8_t* rgba_data,
  uint8_t* indexed_data,
  const l_RGB_t* palette,
  size_t palette_size,
  int width,
  int height) {
  for (int i = 0; i < width * height; i++) {
    uint8_t r = rgba_data[i * 4];
    uint8_t g = rgba_data[i * 4 + 1];
    uint8_t b = rgba_data[i * 4 + 2];

    // Find the closest color in the palette
    int closest_index = 0;
    int closest_distance = color_distance(palette[0], r, g, b);

    for (size_t j = 1; j < palette_size; j++) {
      int dist = color_distance(palette[j], r, g, b);
      if (dist < closest_distance) {
        closest_distance = dist;
        closest_index = j;
      }
    }

    // Assign the closest palette color index to the pixel
    indexed_data[i] = closest_index;
  }
}

static err_t c_encode(
  const void* img,
  size_t img_size,
  int img_width,
  int img_height,
  const l_RGB_t* plt_colors,
  size_t plt_size,
  void** out,
  size_t* out_size,
  int* spng_err)
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
      err = ERR_SPNG_FAILED;
      break;
    }

    if (spng_set_option(ctx, SPNG_ENCODE_TO_BUFFER, 1) != 0) {
      err = ERR_SPNG_FAILED;
      break;
    }

    if (spng_set_plte(ctx, &plte) != 0) {
      err = ERR_SPNG_FAILED;
      break;
    }

    if (spng_encode_image(ctx, img, img_size, SPNG_FMT_PNG, SPNG_ENCODE_FINALIZE) != 0) {
      err = ERR_SPNG_FAILED;
      break;
    }

    void* png_buffer;
    size_t png_size;
    *out = spng_get_png_buffer(ctx, out_size, spng_err);
    if (*spng_err != 0) {
      err = ERR_SPNG_FAILED;
      break;
    }
  } while (0);

  spng_ctx_free(ctx);
  return err;
}

static err_t c_decode(
  const void* png_data,
  size_t png_size,
  const l_RGB_t* known_palette,
  size_t known_palette_size,
  void** out_data,
  int* out_width,
  int* out_height,
  int* spng_err
) {
  err_t err = ERR_NONE;
  spng_ctx* ctx = spng_ctx_new(0); // Create a new SPNG context

  if (!ctx) {
    return ERR_SPNG_FAILED;
  }

  spng_set_png_buffer(ctx, png_data, png_size);

  struct spng_ihdr ihdr;
  *spng_err = spng_get_ihdr(ctx, &ihdr); // Retrieve the image header

  if (*spng_err != 0) {
    spng_ctx_free(ctx);
    return ERR_SPNG_FAILED;
  }

  *out_width = ihdr.width;
  *out_height = ihdr.height;

  if (ihdr.color_type == SPNG_COLOR_TYPE_INDEXED) {
    // Already indexed, no need to quantize
    struct spng_plte plte;
    *spng_err = spng_get_plte(ctx, &plte);

    if (*spng_err != 0) {
      spng_ctx_free(ctx);
      return ERR_SPNG_FAILED;
    }

    // Map the PNG's palette to the known palette if needed
    size_t palette_size = plte.n_entries;
    size_t data_size = (*out_width) * (*out_height) * 3;
    *out_data = malloc((*out_width) * (*out_height));  // Indexed data
    *spng_err = spng_decode_image(ctx, *out_data, data_size, SPNG_FMT_PNG, 0);

    if (*spng_err != 0) {
      printf("%s\n", spng_strerror(*spng_err));
      free(*out_data);
      spng_ctx_free(ctx);
      return ERR_SPNG_FAILED;
    }

  }
  else {
    // Non-indexed, we need to apply the known palette
    size_t raw_size;
    *spng_err = spng_decoded_image_size(ctx, SPNG_FMT_RGBA8, &raw_size);

    if (*spng_err != 0) {
      spng_ctx_free(ctx);
      return ERR_SPNG_FAILED;
    }

    uint8_t* raw_data = malloc(raw_size);

    if (!raw_data) {
      spng_ctx_free(ctx);
      return ERR_SPNG_FAILED;
    }

    *spng_err = spng_decode_image(ctx, raw_data, raw_size, SPNG_FMT_RGBA8, 0);

    if (*spng_err != 0) {
      free(raw_data);
      spng_ctx_free(ctx);
      return ERR_SPNG_FAILED;
    }

    // Allocate the output indexed data
    *out_data = malloc((*out_width) * (*out_height));

    // Quantize using the known palette
    palette_quantize(raw_data, (uint8_t*)*out_data, known_palette, known_palette_size, *out_width, *out_height);

    free(raw_data);
  }

  spng_ctx_free(ctx);
  return ERR_NONE;
}



static int l_encode(lua_State* L) {
  err_t err = ERR_NONE;
  size_t out_size;
  size_t img_size;
  size_t plt_size;
  l_RGB_t* plt_colors = NULL;
  void* out = NULL;

  do {
    const char* img_buf = luaL_checklstring(L, 1, &img_size);
    if (img_buf == NULL) {
      err = ERR_LUA_FAILED;
      break;
    }

    int img_width = luaL_checkinteger(L, 2);
    if (img_width <= 0) {
      err = ERR_LUA_FAILED;
      break;
    }

    int img_height = luaL_checkinteger(L, 3);
    if (img_height <= 0) {
      err = ERR_LUA_FAILED;
      break;
    }

    plt_size = (size_t)lua_rawlen(L, 4);
    if (plt_size <= 0) {
      err = ERR_LUA_FAILED;
      break;
    }

    l_RGB_t* plt_colors = malloc(MAX_ALLOWED_PALETTE_SIZE * sizeof(l_RGB_t));

    for (int i = 0; i < plt_size; ++i) {
      int typ = lua_rawgeti(L, 4, i + 1);
      if (typ != LUA_TTABLE) {
        err = ERR_LUA_FAILED;
        break;
      }

      typ = lua_getfield(L, -1, "Red");
      if (typ != LUA_TNUMBER) {
        err = ERR_LUA_FAILED;
        break;
      }
      plt_colors[i].r = (unsigned char)lua_tointeger(L, -1);
      lua_pop(L, 1);

      typ = lua_getfield(L, -1, "Green");
      if (typ != LUA_TNUMBER) {
        err = ERR_LUA_FAILED;
        break;
      }
      plt_colors[i].g = (unsigned char)lua_tointeger(L, -1);
      lua_pop(L, 1); // Remove g from the stack

      typ = lua_getfield(L, -1, "Blue");
      if (typ != LUA_TNUMBER) {
        err = ERR_LUA_FAILED;
        break;
      }
      plt_colors[i].b = (unsigned char)lua_tointeger(L, -1);
      lua_pop(L, 1); // Remove b from the stack

      lua_pop(L, 1); // Remove the table element
    }

    lua_pushnil(L); // the data set to nil

    int spng_err;

    err = c_encode(
      img_buf,
      img_size,
      img_width,
      img_height,
      plt_colors,
      plt_size,
      &out,
      &out_size,
      &spng_err
    );

    if (err != ERR_NONE) {
      printf("-=-=-=-=-=[%d]=-=-=-=-=-=-\n", err);
      lua_pushnil(L); // set the return data to nil

      if (err == ERR_SPNG_FAILED) lua_pushstring(L, spng_strerror(spng_err)); // the error message
      else if (err == ERR_LUA_FAILED) lua_pushstring(L, "something went wrong in the lua wrapper!"); // the error message
      else lua_pushstring(L, "i have no idea what went wrong!"); // the error message

      break;
    }

    lua_pushlstring(L, out, out_size); // set the actual return data
    lua_pushnil(L); // set the return error to nil

  } while (0);

  if (plt_colors) free(plt_colors);
  if (out) free(out);

  if (err != ERR_NONE) {
    printf("err <spng-l>: code[%d]\n", err);
    return 2;
  }

  return 2;
}

static int l_decode(lua_State* L) {
  err_t err = ERR_NONE;
  size_t png_size;
  size_t plt_size;
  const char* png_data = luaL_checklstring(L, 1, &png_size);
  if (png_data == NULL) {
    lua_pushnil(L);
    lua_pushstring(L, "Invalid PNG data");
    return 2;
  }

  plt_size = (size_t)lua_rawlen(L, 2);
  if (plt_size <= 0) {
    lua_pushnil(L);
    lua_pushstring(L, "Invalid Palette data");
    return 2;
  }

  l_RGB_t* plt_colors = malloc(MAX_ALLOWED_PALETTE_SIZE * sizeof(l_RGB_t));

  for (int i = 0; i < plt_size; ++i) {
    int typ = lua_rawgeti(L, 2, i + 1);
    if (typ != LUA_TTABLE) {
      err = ERR_LUA_FAILED;
      break;
    }

    typ = lua_getfield(L, -1, "Red");
    if (typ != LUA_TNUMBER) {
      err = ERR_LUA_FAILED;
      break;
    }
    plt_colors[i].r = (unsigned char)lua_tointeger(L, -1);
    lua_pop(L, 1);

    typ = lua_getfield(L, -1, "Green");
    if (typ != LUA_TNUMBER) {
      err = ERR_LUA_FAILED;
      break;
    }
    plt_colors[i].g = (unsigned char)lua_tointeger(L, -1);
    lua_pop(L, 1); // Remove g from the stack

    typ = lua_getfield(L, -1, "Blue");
    if (typ != LUA_TNUMBER) {
      err = ERR_LUA_FAILED;
      break;
    }
    plt_colors[i].b = (unsigned char)lua_tointeger(L, -1);
    lua_pop(L, 1); // Remove b from the stack

    lua_pop(L, 1); // Remove the table element
  }

  void* out_data = NULL;
  int out_width = 0, out_height = 0;
  int spng_err = 0;

  err = c_decode(
    png_data,
    png_size,
    plt_colors,
    plt_size,
    &out_data,
    &out_width,
    &out_height,
    &spng_err);

  if (err != ERR_NONE) {
    lua_pushnil(L);
    if (err == ERR_SPNG_FAILED) {
      printf(spng_strerror(spng_err));
      lua_pushstring(L, spng_strerror(spng_err));
    }
    else {
      lua_pushstring(L, "Unknown error occurred during PNG decoding");
    }
    free(plt_colors);
    return 2;
  }

  lua_pushlstring(L, (const char*)out_data, out_width * out_height); // Push indexed data
  lua_pushinteger(L, out_width);
  lua_pushinteger(L, out_height);

  free(out_data);
  free(plt_colors);

  return 3;
}



static const struct luaL_Reg lib[] = {
  { "encode", l_encode},
  { "decode", l_decode},
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

MODULE_EXPORT int open_module_spng(lua_State* L) {
  int res = define_module(L);
  if (res == 1) {
    register_foo(L);
  }
  return res;
}