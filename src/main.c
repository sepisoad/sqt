#include <stdbool.h>
#include <stdlib.h>

#define UTILS_IO_IMPLEMENTATION
#define UTILS_ARENA_IMPLEMENTATION
#define UTILS_ENDIAN_IMPLEMENTATION
#define PAK_IMPLEMENTATION

#include "../deps/log.h"
#include "../deps/sokol_app.h"
#include "../deps/sokol_args.h"
#include "../deps/sokol_gfx.h"
#include "../deps/nuklear.h"
#include "../deps/sokol_nuklear.h"
#include "../deps/sokol_glue.h"
#include "../deps/sokol_time.h"
#include "../deps/sokol_log.h"

#include "app.h"
#include "glsl/default.h"
#include "utils/types.h"

bool cmd_sqt(char**);
void draw_ui(state*);

static state s;

void init(void) {
  // setup sokol-gfx and sokol-nuklear
  sg_setup(&(sg_desc){
      .environment = sglue_environment(),
      .logger.func = slog_func,
  });

  snk_setup(&(snk_desc_t){
      .enable_set_mouse_cursor = true,
      .dpi_scale = sapp_dpi_scale(),
      .logger.func = slog_func,
  });
}

void frame(void) {
  draw_ui(&s);
}

void cleanup(void) {
  snk_shutdown();
  sg_shutdown();
}

void input(const sapp_event* event) {}

sapp_desc sokol_main(int argc, char* argv[]) {
  (void)argc;
  (void)argv;
  return (sapp_desc){
      .init_cb = init,
      .frame_cb = frame,
      .cleanup_cb = cleanup,
      .event_cb = input,
      .enable_clipboard = true,
      .width = 1024,
      .height = 768,
      .window_title = "nuklear (sokol-app)",
      .ios_keyboard_resizes_canvas = true,
      .icon.sokol_default = true,
      .logger.func = slog_func,
  };
}

/* int main(int argc, char** argv) { */
/*   return cmd_sqt(argv) ? EXIT_SUCCESS : EXIT_FAILURE; */
/* } */
