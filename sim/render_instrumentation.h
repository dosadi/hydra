#pragma once

#include <string>
#include <fstream>

struct RenderInstrumentationConfig;

struct RenderInstrumentation {
    RenderInstrumentation(bool enabled, std::string command_line);
    bool active() const;
    void write_config(const RenderInstrumentationConfig& cfg);
    void record(uint64_t frame, double fps, double ray_loop_ms, double hud_present_ms, double framebuffer_copy_ms, double frame_total_ms);
private:
    bool enabled_;
    std::ofstream csv_;
    std::string command_line_;
};
