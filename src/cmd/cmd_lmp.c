#include <stdbool.h>
#include <stdio.h>

#include "../../deps/optparse.h"

bool cmd_lmp(char **argv) {
  int i, option;
  struct optparse options;

  optparse_init(&options, argv);
  while ((option = optparse(&options, "h")) != -1) {
    switch (option) {
    case 'h':
      puts("usage: sleep [-h] [NUMBER]...");
      return true;
    case '?':
      printf("%s: %s\n", argv[0], options.errmsg);
      return false;
    }
  }

  return true;
}
