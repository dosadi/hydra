// viewer_globals.cpp - Definitions for shared global variables
#include "viewer_globals.h"

// Fog system globals
bool g_fog_enabled = false;
float g_fog_density = 0.01f;
uint32_t g_fog_color = 0x404040FF;  // Dark gray fog

// Pixel view mode globals
PixelViewMode g_pixel_view_mode = PixelViewMode::Color;