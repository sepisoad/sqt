#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "../../deps/optparse.h"
#include "../utils/types.h"

bool cmd_pak(char **argv);
bool cmd_lmp(char **argv);
bool cmd_wad(char **argv);

static struct optparse_long opts[] = {
    {"help", 'h', OPTPARSE_NONE}, {"version", 'v', OPTPARSE_NONE}, {0}};

static const struct {
  char name[8];
  bool (*cmd)(char **);
} cmds[] = {{"pak", cmd_pak}, {"lmp", cmd_lmp}, {"wad", cmd_wad}};

static void usage() {
  printf("usage: example [-h] <pak|lmp|wad> [OPTION]...\n");
}

static void version() { printf("version 0.0.1\n"); }

bool cmd_sqt(char **argv) {
  struct optparse optp;
  optparse_init(&optp, argv);
  optp.permute = 0;

  int opt;
  while ((opt = optparse_long(&optp, opts, NULL)) != -1) {
    switch (opt) {
    case 'h':
      usage();
      return true;
    case 'v':
      version();
      return true;

    case '?':
      usage();
      printf("%s: %s\n", argv[0], optp.errmsg);
      return false;
    }
  }

  char **subargv = argv + optp.optind;
  if (!subargv[0]) {
    printf("%s: missing subcommand\n", argv[0]);
    usage();
    return false;
  }

  int cmdsln = sizeof(cmds) / sizeof(*cmds);
  for (u8 i = 0; i < cmdsln; i++) {
    if (!strcmp(cmds[i].name, subargv[0])) {
      return cmds[i].cmd(subargv);
    }
  }

  printf("%s: invalid subcommand: %s\n", argv[0], subargv[0]);
  return false;
}
