// SPDX-License-Identifier: BSD-3-Clause
// ============================================================================
// backend_headless.cpp
// - Headless (no-window) backend for regression testing and CI.
// - Accepts frames but does not display them.
// ============================================================================

#include "backend_headless.h"
#include <cstdio>

HeadlessBackend::HeadlessBackend() {}

HeadlessBackend::~HeadlessBackend() {}

bool HeadlessBackend::init(PlatformContext& ctx, const PlatformConfig& cfg) {
    (void)cfg;
    (void)ctx;
    std::fprintf(stderr, "[headless] Backend initialized (no window)\n");
    return true;
}

void HeadlessBackend::present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    (void)ctx;
    (void)pixels;
    (void)w;
    (void)h;
    // No-op: headless mode doesn't display anything
}

void HeadlessBackend::shutdown(PlatformContext& ctx) {
    (void)ctx;
    std::fprintf(stderr, "[headless] Backend shut down\n");
}
