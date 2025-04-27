#ifndef _PAK_HEADER_
#define _PAK_HEADER_

#include <string.h>

#include "../../deps/fs.h"
#include "../utils/types.h"
#include "../utils/io.h"
#include "../utils/macros.h"
#include "../utils/arena.h"
#include "../utils/endian.h"

static constexpr u8 MAGIC_CODE[] = "PACK";
static constexpr u8 MAGIC_CODE_LEN = 4;
static constexpr u32 HEADER_LEN = 12;
static constexpr u32 ENTRY_NAME_LEN = 56;
static constexpr u32 ENTRY_LEN = ENTRY_NAME_LEN + 4 + 4;
static constexpr u32 MAX_PATH_LEN = 1024;
static constexpr u32 MAX_FILE_SIZE = 25 * 1024 * 1024;

static u8 HEADER_BUF[HEADER_LEN] = {0};
static u8 ENTRY_BUF[ENTRY_LEN] = {0};
static char DIR_BUF[MAX_PATH_LEN + ENTRY_NAME_LEN] = {0};
static char PATH_BUF[MAX_PATH_LEN + ENTRY_NAME_LEN] = {0};
static char DATA_BUF[MAX_FILE_SIZE] = {0};

typedef FILE* pakf;
typedef enum pakerr { PAK_ERR_UNKNOWN = -1, PAK_ERR_OK = 0 } pakerr;

typedef struct {
  u8 magic_code[MAGIC_CODE_LEN];
  i32 offset;  // file entry table offset
  i32 size;    // file entry table size in bytes
} pak_header;

typedef struct {
  u8 name[ENTRY_NAME_LEN];  // each file entry name
  i32 offset;               // offset to the entry file data
  i32 size;                 // size of the entry file data
} pak_entry;

typedef struct {
  u32 entries_count;
  sz entries_size;
  sz pak_size;
} pak_meta;

typedef struct pak_s {
  pak_header header;
  pak_entry* entries;
} pak;

pakerr pak_info(arena*, cstr, pak*);
pakerr pak_list(arena*, cstr, pak*);
pakerr pak_extract(arena*, cstr, cstr, pak*);
pakerr pak_create(arena*, cstr, pak*);

//  _                 _                           _        _   _
// (_)               | |                         | |      | | (_)
//  _ _ __ ___  _ __ | | ___ _ __ ___   ___ _ __ | |_ __ _| |_ _  ___  _ __
// | | '_ ` _ \| '_ \| |/ _ \ '_ ` _ \ / _ \ '_ \| __/ _` | __| |/ _ \| '_ \
// | | | | | | | |_) | |  __/ | | | | |  __/ | | | || (_| | |_| | (_) | | | |
// |_|_| |_| |_| .__/|_|\___|_| |_| |_|\___|_| |_|\__\__,_|\__|_|\___/|_| |_|
//             | |
//             |_|

#ifdef PAK_IMPLEMENTATION

/*****************************
 * HIDDEN FUNCTIONS
 *****************************/

static void _read_header(pakf f, pak_header* h) {
  memset(HEADER_BUF, 0, HEADER_LEN);
  makesure(fread(HEADER_BUF, 1, HEADER_LEN, f) == HEADER_LEN,
           "failed to read header data");

  pak_header* hp = (pak_header*)HEADER_BUF;
  memcpy(h->magic_code, hp->magic_code, MAGIC_CODE_LEN);
  h->offset = endian_i32(hp->offset);
  h->size = endian_i32(hp->size);

  makesure(memcmp(h->magic_code, MAGIC_CODE, MAGIC_CODE_LEN) == 0,
           "invalid header magic code");
  makesure(h->offset > 0, "invalud header offset");
  makesure(h->size > 0, "invalud header size");
}

static sz _read_entries(arena* m, pakf f, pak* p, pak_meta* pm) {
  sz ts = 0;
  i32 of = p->header.offset;
  u32 fc = pm->entries_count;
  sz fs = pm->entries_size;
  sz ez = pm->entries_count * sizeof(pak_entry) /*FILE_ENTRY_LEN*/;

  p->entries = (pak_entry*)arena_alloc(m, ez, alignof(pak_entry));
  notnull(p->entries);

  fseek(f, of, SEEK_SET);
  for (u32 i = 0; i < fc; i++) {
    memset(ENTRY_BUF, 0, ENTRY_LEN);
    makesure(fread(ENTRY_BUF, 1, ENTRY_LEN, f) == ENTRY_LEN,
             "failed to read entry data at index '%u'", i);

    pak_entry* ppe = (pak_entry*)ENTRY_BUF;
    memcpy(p->entries[i].name, ppe->name, ENTRY_NAME_LEN);
    p->entries[i].offset = endian_i32(ppe->offset);
    p->entries[i].size = endian_i32(ppe->size);
  }
  return ts;
}

static sz _total_entries_size(pakf f, i32 ofs, u32 fc) {
  sz ts = 0;

  fseek(f, ofs, SEEK_SET);
  for (u32 i = 0; i < fc; i++) {
    memset(ENTRY_BUF, 0, ENTRY_LEN);
    makesure(fread(ENTRY_BUF, 1, ENTRY_LEN, f) == ENTRY_LEN,
             "failed to read entry data at index '%u'", i);
    ts += endian_i32(((pak_entry*)ENTRY_BUF)->size);
  }
  return ts;
}

static void _read_all(arena* m, pakf f, cstr fp, pak* p, pak_meta* pm) {
  i32 ofc = p->header.offset;
  u32 fc = pm->entries_count;
  makesure(f != NULL, "faied to open file '%s'", f);

  _read_header(f, &p->header);
  _read_entries(m, f, p, pm);
}

static void _estimate(arena* m, cstr fp, pak_meta* pm) {
  arena_begin_estimate(m);

  pakf f = fopen(fp, "rb");
  makesure(f != NULL, "faied to open file '%s'", f);

  pak p = {0};
  _read_header(f, &p.header);
  pm->entries_count = p.header.size / ENTRY_LEN;
  pm->entries_size = _total_entries_size(f, p.header.offset, pm->entries_count);

  sz ez = pm->entries_count * ENTRY_LEN;
  arena_estimate_add(m, ez, alignof(pak_entry));

  fseek(f, 0, SEEK_END);
  pm->pak_size = ftell(f);
  fclose(f);

  /* arena_estimate_add(m, sizeof(), alignof(u32)); */
  arena_end_estimate(m);
}

/*****************************
 * EXPORTED FUNCTIONS
 *****************************/

pakerr pak_info(arena* m, cstr path, pak* ppak) {
  pak_meta pm = {0};
  pakf f = fopen(path, "rb");

  _estimate(m, path, &pm);
  _read_all(m, f, path, ppak, &pm);

  printf("************** INFO **************\n");
  printf("↬ file name:      '%s'\n", path);
  printf("↬ file size:      '%zu MB (%zu Bytes)'\n", pm.pak_size / 1000000,
         pm.pak_size);
  printf("↬ entries counts: '%u'\n", pm.entries_count);

  fclose(f);
  return PAK_ERR_OK;
}

pakerr pak_list(arena* m, cstr path, pak* ppak) {
  pak_meta pm = {0};
  pakf f = fopen(path, "rb");

  _estimate(m, path, &pm);
  _read_all(m, f, path, ppak, &pm);

  printf("************** ENTRIES **************\n");
  printf("       (index | name | size)\n");
  for (u32 i = 0; i < pm.entries_count; i++) {
    printf("↬ [%u] %s : %.2f MB (%d Bytes)\n", i + 1, ppak->entries[i].name,
           (f32)ppak->entries[i].size / 1000000, ppak->entries[i].size);
  }

  fclose(f);
  return PAK_ERR_OK;
}

pakerr pak_extract(arena* m, cstr path, cstr odir, pak* ppak) {
  makesure(
      strlen(odir) < MAX_PATH_LEN,
      "output director '%s' path length is larger than supported max of '%d'",
      odir, MAX_PATH_LEN);

  fs* pfs = NULL;
  fs_file_info fi;
  fs_result fr = fs_info(pfs, path, FS_READ, &fi);
  makesure(fr == FS_SUCCESS,
           "failed to get information about input pak file at '%s'", path);
  makesure(fi.directory != 1, "the input pak is not a file");

  fs_file_info od;
  fr = fs_info(pfs, odir, FS_READ, &od);
  makesure(fr != FS_SUCCESS, "the output directory at '%s' already exists",
           odir);

  pak_meta pm = {0};
  pakf f = fopen(path, "rb");

  _estimate(m, path, &pm);
  _read_all(m, f, path, ppak, &pm);

  for (u32 i = 0; i < pm.entries_count; i++) {
    memset(PATH_BUF, 0, MAX_PATH_LEN + ENTRY_NAME_LEN);
    memset(DATA_BUF, 0, MAX_FILE_SIZE);

    sprintf(PATH_BUF, "%s/%s", odir, (const char*)ppak->entries[i].name);

    fs_file* pf;
    fs_result r = fs_file_open(pfs, PATH_BUF, FS_OVERWRITE, &pf);
    makesure(r != FS_SUCCESS, "failed to create file '%s'",
             ppak->entries[i].name);
    fs_file_close(pf);

    i32 of = ppak->entries[i].offset;
    sz is = ppak->entries[i].size;
    sz os = 0;

    fseek(f, of, SEEK_SET);
    makesure(is == fread(DATA_BUF, 1, is, f), "failed to read enough data");

    FILE* ff = fopen(PATH_BUF, "wb");
    makesure(is == fwrite(DATA_BUF, 1, is, ff), "failed to write enough data");
    fclose(ff);
  }

  fclose(f);
  return PAK_ERR_OK;
}

pakerr pak_create(arena* m, cstr path, pak*) {
  mustdie("THIS FEATURE IS NOT IMPLEMENTED YET!");
  return PAK_ERR_OK;
}

#endif  // PAK_IMPLEMENTATION
#endif  //_PAK_HEADER_
