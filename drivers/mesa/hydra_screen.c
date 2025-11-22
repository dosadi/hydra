/* Placeholder Hydra Gallium screen */
#if 0
#include "pipe/p_screen.h"
#include "pipe/p_defines.h"
#include "util/u_memory.h"

struct hydra_screen {
   struct pipe_screen base;
};

static const char *
hydra_get_name(struct pipe_screen *pscreen)
{
   return "Hydra stub";
}

static const char *
hydra_get_vendor(struct pipe_screen *pscreen)
{
   return "Hydra";
}

static void
hydra_destroy_screen(struct pipe_screen *pscreen)
{
   struct hydra_screen *hs = (struct hydra_screen *)pscreen;
   FREE(hs);
}

struct pipe_screen *
hydra_screen_create(void)
{
   struct hydra_screen *hs = CALLOC_STRUCT(hydra_screen);
   if (!hs)
      return NULL;
   hs->base.destroy = hydra_destroy_screen;
   hs->base.get_name = hydra_get_name;
   hs->base.get_vendor = hydra_get_vendor;
   /* TODO: fill caps and resource hooks */
   return &hs->base;
}
#endif
