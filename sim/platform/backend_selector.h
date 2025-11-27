// ============================================================================
// backend_selector.h
// - Chooses a platform backend at runtime based on environment/availability.
// ============================================================================
#pragma once

#include "platform.h"
#include "backend_base.h"

PlatformBackend select_default_backend();
BackendPtr create_backend(PlatformBackend backend);
bool init_backend(PlatformBackend backend, const PlatformConfig& cfg, PlatformContext& ctx);
void present_backend(PlatformContext& ctx, const uint32_t* pixels, int w, int h);
void shutdown_backend(PlatformContext& ctx);
// Log available platform/backend capabilities to stderr (used by --caps).
void platform_log_capabilities();
