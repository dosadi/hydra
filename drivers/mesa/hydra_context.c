/* Placeholder Hydra Gallium context */
#if 0
#include "pipe/p_context.h"
#include "pipe/p_state.h"
#include "util/u_memory.h"

struct hydra_context {
   struct pipe_context base;
};

static void
hydra_context_destroy(struct pipe_context *pctx)
{
   struct hydra_context *hc = (struct hydra_context *)pctx;
   FREE(hc);
}

struct pipe_context *
hydra_context_create(struct pipe_screen *pscreen, void *priv, unsigned flags)
{
   struct hydra_context *hc = CALLOC_STRUCT(hydra_context);
   if (!hc)
      return NULL;
   hc->base.destroy = hydra_context_destroy;
   /* TODO: add blit/resource ops */
   return &hc->base;
}
#endif
