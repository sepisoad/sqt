#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "../../deps/optparse.h"
#include "../pak/pak.h"

static struct optparse_long opts[] = {{"help", 'h', OPTPARSE_NONE},
                                      {"input", 'i', OPTPARSE_REQUIRED},
                                      {0}};

static void _usage() {
  printf("usage: sqt pack info -i [FILE]\n");
}

static bool _pak_info(cstr fp) {
  arena m = {0};
  pak p = {0};
  pakerr e = pak_info(&m, fp, &p);
  return e == PAK_ERR_OK;
}

bool cmd_pak_info(char** argv) {
  struct optparse optp;
  optparse_init(&optp, argv);
  optp.permute = 0;

  int opt;
  while ((opt = optparse_long(&optp, opts, NULL)) != -1) {
    switch (opt) {
      case 'h':
        _usage();
        return true;
      case 'i':
        _pak_info(optp.optarg);
        break;
      case '?':
        _usage();
        printf("%s: %s\n", argv[0], optp.errmsg);
        return false;
    }
  }

  return true;
}
