#include "backend_ops.h"

// macOS placeholder: reuse SDL backend until a native Cocoa/Metal path exists.
BackendOps get_ops_macos() {
#if defined(__APPLE__)
    return get_ops_sdl();
#else
    return make_stub_ops();
#endif
}
