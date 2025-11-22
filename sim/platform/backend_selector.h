// ============================================================================
// backend_selector.h
// - Chooses a platform backend at runtime based on environment/availability.
// ============================================================================
#pragma once

#include "platform.h"

PlatformBackend select_default_backend();
bool init_backend(PlatformBackend backend, const PlatformConfig& cfg, PlatformContext& ctx);
void present_backend(PlatformBackend backend, PlatformContext& ctx, const uint32_t* pixels, int w, int h);
void shutdown_backend(PlatformBackend backend, PlatformContext& ctx);
