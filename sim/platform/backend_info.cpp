// SPDX-License-Identifier: BSD-3-Clause
// ============================================================================
// backend_info.cpp
// - Backend info reporting implementation
// ============================================================================

#include "backend_info.h"

namespace backend_info {
    static std::string g_backend_info;

    void set(const std::string& info) {
        g_backend_info = info;
    }

    const std::string& get() {
        return g_backend_info;
    }
}
