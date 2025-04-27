#ifndef UTILS_IO_HEADER_
#define UTILS_IO_HEADER_

#include <stdint.h>
#include <stdio.h>

#include "types.h"
#include "arena.h"
#include "macros.h"

/* ****************** utils::io API ****************** */
sz file_size(cstr);
sz load_file(cstr, u8**);
sz load_file_mem(cstr, arena*, u8**);
/* ****************** utils::io API ****************** */

#ifdef UTILS_IO_IMPLEMENTATION

sz file_size(cstr path) {
  FILE* f = fopen(path, "rb");
  makesure(f != NULL, "failed to open '%s'", path);

  fseek(f, 0, SEEK_END);
  sz s = ftell(f);
  rewind(f);

  if (f)
    fclose(f);

  return s;
}

sz load_file(cstr path, u8** buf) {
  FILE* f = fopen(path, "rb");
  makesure(f != NULL, "failed to open '%s'", path);

  fseek(f, 0, SEEK_END);
  sz fsize = ftell(f);
  rewind(f);

  *buf = (u8*)malloc(sizeof(u8) * fsize);
  makesure(*buf != NULL, "malloc failed");

  sz rsize = fread(*buf, 1, fsize, f);
  makesure(rsize == fsize, "read size '%zu' did not match the file size '%zu'",
           rsize, fsize);

  if (f) {
    fclose(f);
  }

  return fsize;
}

sz load_file_mem(cstr path, arena* mem, u8** buf) {
  FILE* f = fopen(path, "rb");
  makesure(f != NULL, "failed to open '%s'", path);

  fseek(f, 0, SEEK_END);
  sz fsize = ftell(f);
  rewind(f);

  *buf = (u8*)arena_alloc(mem, sizeof(u8) * fsize, alignof(u8));
  makesure(*buf != NULL, "malloc failed");

  sz rsize = fread(*buf, 1, fsize, f);
  makesure(rsize == fsize, "read size '%zu' did not match the file size '%zu'",
           rsize, fsize);

  if (f) {
    fclose(f);
  }

  return fsize;
}

#endif  // UTILS_IO_IMPLEMENTATION
#endif  // UTILS_IO_HEADER_
