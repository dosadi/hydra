/* Placeholder Gallium driver skeleton for Hydra.
 * This file is NOT built in this repo. Copy/port into Mesa's
 * src/gallium/drivers/hydra/ and wire up meson when implementing.
 */

#if 0
#include "pipe/p_screen.h"
#include "pipe/p_context.h"
#include "pipe/p_defines.h"
#include "util/u_memory.h"
#include "util/u_screen.h"

struct hydra_screen {
   struct pipe_screen base;
};

static const char *
hydra_get_name(struct pipe_screen *pscreen)
{
   return "Hydra (stub)";
}

static void
hydra_destroy_screen(struct pipe_screen *pscreen)
{
   struct hydra_screen *hs = (struct hydra_screen *)pscreen;
   FREE(hs);
}

static struct pipe_context *
hydra_context_create(struct pipe_screen *pscreen, void *priv, unsigned flags)
{
   return NULL; /* stub: return NULL to signal unsupported */
}

struct pipe_screen *
hydra_screen_create(void)
{
   struct hydra_screen *hs = CALLOC_STRUCT(hydra_screen);
   if (!hs)
      return NULL;

   hs->base.destroy = hydra_destroy_screen;
   hs->base.get_name = hydra_get_name;
   hs->base.context_create = hydra_context_create;
   /* TODO: add caps/format query stubs */
   return &hs->base;
}
#endif
