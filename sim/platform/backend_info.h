// SPDX-License-Identifier: BSD-3-Clause
// ============================================================================
// backend_info.h
// - Backend info reporting for HUD overlay
// ============================================================================
#pragma once

#include <string>

namespace backend_info {
    // Set backend info string to be displayed in HUD
    // This is called by backends during initialization to report their status
    void set(const std::string& info);

    // Get current backend info (used by main loop for HUD rendering)
    const std::string& get();
}
