#include "backend_ops.h"

// Windows placeholder: reuse SDL backend while a native Win32 present path is authored.
BackendOps get_ops_win32() {
#if defined(_WIN32)
    return get_ops_sdl();
#else
    return make_stub_ops();
#endif
}
