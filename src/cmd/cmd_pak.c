#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "../../deps/optparse.h"
#include "../utils/types.h"

bool cmd_pak_info(char **argv);
bool cmd_pak_list(char **argv);
bool cmd_pak_extract(char **argv);
bool cmd_pak_create(char **argv);

static struct optparse_long opts[] = {{"help", 'h', OPTPARSE_NONE}, {0}};

static const struct {
  char name[8];
  bool (*cmd)(char **);
} cmds[] = {{"info", cmd_pak_info},
            {"list", cmd_pak_list},
            {"extract", cmd_pak_extract},
            {"create", cmd_pak_create}};

static void usage() {
  printf("usage: sqt pack [-h] <info|list|extract|create> [OPTION]...\n");
}

bool cmd_pak(char **argv) {
  struct optparse optp;
  optparse_init(&optp, argv);
  optp.permute = 0;

  int opt;
  while ((opt = optparse_long(&optp, opts, NULL)) != -1) {
    switch (opt) {
    case 'h':
      usage();
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
