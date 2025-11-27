#include "render_instrumentation.h"
#include "harness_common.h"
#include <filesystem>
#include <chrono>
#include <iostream>

RenderInstrumentation::RenderInstrumentation(bool enabled, std::string command_line)
    : enabled_(enabled), command_line_(std::move(command_line)) {
    if (!enabled_) return;
    std::filesystem::create_directories("out");
    csv_.open("out/render_pipeline_baseline.csv", std::ios::app);
    if (!csv_) {
        std::fprintf(stderr, "failed to open out/render_pipeline_baseline.csv for instrumentation logging\n");
        std::exit(1);
    }
    if (csv_.tellp() == 0)
        csv_ << "frame,timestamp_ms,fps,ray_loop_ms,hud_present_ms,framebuffer_copy_ms,frame_total_ms\n";
}

bool RenderInstrumentation::active() const { return enabled_; }

void RenderInstrumentation::write_config(const RenderInstrumentationConfig& cfg) {
    if (!enabled_) return;
    std::ofstream cfg_out("out/render_pipeline_baseline.cfg");
    if (!cfg_out) {
        std::fprintf(stderr, "failed to write out/render_pipeline_baseline.cfg\n");
        std::exit(1);
    }
    cfg_out << "instrument_command=" << command_line_ << "\n";
    cfg_out << "backend=" << cfg.backend_name << "\n";
    cfg_out << "backend_info=" << cfg.backend_info << "\n";
    cfg_out << "pixel_view=" << cfg.pixel_view << "\n";
    cfg_out << "camera_pos=" << cfg.cam_pos_x << "," << cfg.cam_pos_y << "," << cfg.cam_pos_z << "\n";
    cfg_out << "camera_ang=" << cfg.yaw << "," << cfg.pitch << "\n";
    cfg_out << "flags=smooth:" << (cfg.smooth_surfaces ? "1" : "0")
            << ",curvature:" << (cfg.curvature ? "1" : "0")
            << ",extra_light:" << (cfg.extra_light ? "1" : "0")
            << ",diag_slice:" << (cfg.diag_slice ? "1" : "0")
            << ",ray_jitter:" << (cfg.ray_jitter ? "1" : "0") << "\n";
    cfg_out << "hud_enabled=" << (cfg.hud_enabled ? "1" : "0") << "\n";
    cfg_out << "fps_target=" << cfg.fps_target << "\n";
    cfg_out << "vsync=" << (cfg.vsync ? "1" : "0") << "\n";
}

void RenderInstrumentation::record(uint64_t frame, double fps, double ray_loop_ms, double hud_present_ms, double framebuffer_copy_ms, double frame_total_ms) {
    if (!enabled_) return;
    auto now = std::chrono::system_clock::now();
    auto ts_ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
    csv_ << frame << ',' << ts_ms << ',' << fps << ',' << ray_loop_ms << ',' << hud_present_ms << ',' << framebuffer_copy_ms << ',' << frame_total_ms << '\n';
    csv_.flush();
}
