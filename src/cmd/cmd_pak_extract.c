#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "../../deps/optparse.h"
#include "../pak/pak.h"

static struct optparse_long opts[] = {{"help", 'h', OPTPARSE_NONE},
                                      {"input", 'i', OPTPARSE_REQUIRED},
                                      {"output", 'o', OPTPARSE_REQUIRED},
                                      {0}};

static void _usage() {
  printf("usage: sqt pack extract -i [FILE] -o [DIR]\n");
}

static bool _pak_extract(cstr fp, cstr dir) {
  arena m = {0};
  pak p = {0};
  pakerr e = pak_extract(&m, fp, dir, &p);
  return e == PAK_ERR_OK;
}

bool cmd_pak_extract(char** argv) {
  struct optparse optp;
  optparse_init(&optp, argv);
  optp.permute = 0;

  cstr input = NULL;
  cstr output = NULL;

  int opt;
  while ((opt = optparse_long(&optp, opts, NULL)) != -1) {
    switch (opt) {
      case 'h':
        _usage();
        return true;
      case 'i':
        input = optp.optarg;
        break;
      case 'o':
        output = optp.optarg;
        break;
      case '?':
        _usage();
        printf("%s: %s\n", argv[0], optp.errmsg);
        return false;
    }
  }

  if (input && output) {
    _pak_extract(input, output);
  } else {
    _usage();
  }

  return true;
}
