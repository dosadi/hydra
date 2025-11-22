#include "backend_ops.h"

BackendOps get_ops_sdl() {
    BackendOps ops;
    ops.init = [](PlatformContext& ctx, const PlatformConfig&) -> bool {
        // Nothing to init yet; keep stub user handle
        ctx.user = reinterpret_cast<void*>(0x1);
        return true;
    };
    ops.present = [](PlatformContext&, const uint32_t*, int, int) {
        // TODO: wire to SDL texture present; stub for now
    };
    ops.shutdown = [](PlatformContext&) {};
    return ops;
}
