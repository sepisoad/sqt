#include <stdbool.h>
#include <stdlib.h>

#define UTILS_ARENA_IMPLEMENTATION
#define UTILS_ENDIAN_IMPLEMENTATION

bool cmd_sqt(char **argv);

int main(int argc, char **argv) {
  return cmd_sqt(argv) ? EXIT_SUCCESS : EXIT_FAILURE;
}
