// SPDX-License-Identifier: BSD-3-Clause
// ============================================================================
// backend_headless.cpp
// - Headless (no-window) backend for regression testing and CI.
// - Accepts frames but does not display them.
// ============================================================================

#include "backend_ops.h"
#include <cstdio>

static bool headless_init(PlatformContext& ctx, const PlatformConfig& cfg) {
    (void)cfg;
    (void)ctx;
    std::fprintf(stderr, "[headless] Backend initialized (no window)\n");
    return true;
}

static void headless_present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    (void)ctx;
    (void)pixels;
    (void)w;
    (void)h;
    // No-op: headless mode doesn't display anything
}

static void headless_shutdown(PlatformContext& ctx) {
    (void)ctx;
    std::fprintf(stderr, "[headless] Backend shut down\n");
}

BackendOps get_ops_headless() {
    BackendOps ops;
    ops.init = headless_init;
    ops.present = headless_present;
    ops.shutdown = headless_shutdown;
    return ops;
}
