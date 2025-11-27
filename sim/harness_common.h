// Shared declarations for sim harnesses — small, stable API
#pragma once

#include <string>

enum class PixelViewMode {
    Color = 0,
    Word0,
    Word2,
    SidebandMix,
};

const char* pixel_view_mode_name(PixelViewMode m);
PixelViewMode pixel_view_from_string(const char* s);

// Small helpers used across harnesses
bool env_truthy(const char* key);
std::string flatten_cli_args(int argc, char** argv);

// Instrumentation config shared type
struct RenderInstrumentationConfig {
    float cam_pos_x = 0.0f;
    float cam_pos_y = 0.0f;
    float cam_pos_z = 0.0f;
    float yaw = 0.0f;
    float pitch = 0.0f;
    bool smooth_surfaces = false;
    bool curvature = false;
    bool extra_light = false;
    bool diag_slice = false;
    bool ray_jitter = false;
    bool hud_enabled = true;
    float fps_target = 0.0f;
    bool vsync = true;
    std::string backend_name;
    std::string backend_info;
    std::string pixel_view;
};
