#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "../../deps/optparse.h"

bool pak_info(const char *input);

static struct optparse_long opts[] = {
    {"help", 'h', OPTPARSE_NONE}, {"input", 'i', OPTPARSE_REQUIRED}, {0}};

static void usage() { printf("usage: sqt pack info -i [FILE]\n"); }

bool cmd_pak_info(char **argv) {
  struct optparse optp;
  optparse_init(&optp, argv);
  optp.permute = 0;

  int opt;
  while ((opt = optparse_long(&optp, opts, NULL)) != -1) {
    switch (opt) {
    case 'h':
      usage();
      return true;
    case 'i':
      pak_info(optp.optarg);
      break;
    case '?':
      usage();
      printf("%s: %s\n", argv[0], optp.errmsg);
      return false;
    }
  }

  return true;
}
