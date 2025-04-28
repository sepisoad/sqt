#include "../../deps/sokol_app.h"
#include "../../deps/log.h"
#include "../../deps/sokol_gfx.h"
#include "../../deps/sokol_glue.h"
#include "../../deps/nuklear.h"
#include "../../deps/sokol_nuklear.h"

#include "../app.h"

void draw_ui(state* s) {
  struct nk_context* ctx = snk_new_frame();
  sg_begin_pass(&(sg_pass){
      .action = {.colors[0] = {.load_action = SG_LOADACTION_CLEAR,
                               .clear_value = {0.25f, 0.5f, 0.7f, 1.0f}}},
      .swapchain = sglue_swapchain()});
  snk_render(sapp_width(), sapp_height());
  sg_end_pass();
  sg_commit();
}
