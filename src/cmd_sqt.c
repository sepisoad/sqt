#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "../deps/optparse.h"

int cmd_pak(char **argv);
int cmd_lmp(char **argv);
int cmd_wad(char **argv);

static void usage() {
  printf("usage: example [-h] <pak|lmp|wad> [OPTION]...\n");
}

static void version() { printf("version 0.0.1\n"); }

int cmd_sqt(char **argv) {
  int i, option;
  char **subargv;
  struct optparse options;

  static const struct {
    char name[8];
    int (*cmd)(char **);
  } cmds[] = {
      {"pak", cmd_pak},
      {"lmp", cmd_lmp},
      {"wad", cmd_wad},
  };
  int ncmds = sizeof(cmds) / sizeof(*cmds);

  optparse_init(&options, argv);
  options.permute = 0;
  while ((option = optparse(&options, "hv")) != -1) {
    switch (option) {
    case 'h':
      usage();
      return 0;
    case 'v':
      version();
      return 0;

    case '?':
      usage();
      printf("%s: %s\n", argv[0], options.errmsg);
      return 1;
    }
  }

  subargv = argv + options.optind;
  if (!subargv[0]) {
    printf("%s: missing subcommand\n", argv[0]);
    usage();
    return 1;
  }

  for (i = 0; i < ncmds; i++) {
    if (!strcmp(cmds[i].name, subargv[0])) {
      return cmds[i].cmd(subargv);
    }
  }
  printf("%s: invalid subcommand: %s\n", argv[0], subargv[0]);
  return 1;
}
