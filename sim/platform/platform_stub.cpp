#include "platform.h"

bool platform_backend_supported(PlatformBackend backend) {
    // Only SDL is currently available in-tree; others are placeholders.
    return backend == PlatformBackend::SDL;
}

bool platform_init(PlatformBackend backend, const PlatformConfig&, PlatformContext& ctx) {
    (void)ctx;
    return backend == PlatformBackend::SDL;
}

void platform_present(PlatformBackend, PlatformContext&, const uint32_t*, int, int) {
    // Stub: nothing to do.
}

void platform_shutdown(PlatformBackend, PlatformContext&) {
    // Stub: nothing to do.
}
