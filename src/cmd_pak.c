#include <stdbool.h>
#include <stdio.h>

#include "../deps/optparse.h"

int cmd_pak(char **argv) {
  int i, option;
  bool newline = true;
  struct optparse options;

  optparse_init(&options, argv);
  options.permute = 0;
  while ((option = optparse(&options, "hn")) != -1) {
    switch (option) {
    case 'h':
      puts("usage: echo [-hn] [ARG]...");
      return 0;
    case 'n':
      newline = false;
      break;
    case '?':
      printf("%s: %s\n", argv[0], options.errmsg);
      return 1;
    }
  }
  argv += options.optind;

  for (i = 0; argv[i]; i++) {
    printf("%s%s", i ? " " : "", argv[i]);
  }
  if (newline) {
    putchar('\n');
  }

  return 0;
}
