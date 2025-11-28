// viewer_globals.h - Shared global variables for viewer modules
#ifndef VIEWER_GLOBALS_H
#define VIEWER_GLOBALS_H

#include <cstdint>
#include "harness_common.h"  // For PixelViewMode enum

// Fog system globals
extern bool g_fog_enabled;
extern float g_fog_density;
extern uint32_t g_fog_color;

// Pixel view mode globals
extern PixelViewMode g_pixel_view_mode;

#endif // VIEWER_GLOBALS_H