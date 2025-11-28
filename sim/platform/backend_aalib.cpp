// Simple AAlib-like ASCII backend for the sim
// This backend produces an ASCII representation of the framebuffer
// to stdout. It's intentionally dependency-free and used for quick
// headless/text-mode renders (useful in CI where terminal output is available).

#include "backend_aalib.h"
#include <cstdio>
#include <cstdlib>
#include <vector>

const char* AALibBackend::luminance_chars = "@%#*+=-:. ";

AALibBackend::AALibBackend() : last_width(0), last_height(0) {}

AALibBackend::~AALibBackend() {}

bool AALibBackend::init(PlatformContext& ctx, const PlatformConfig& cfg) {
    (void)ctx; (void)cfg;
    return true;
}

void AALibBackend::present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    (void)ctx;

    // Only render if dimensions changed or first frame
    if (w == last_width && h == last_height && last_width > 0) {
        return; // Skip rendering identical frames
    }
    last_width = w;
    last_height = h;

    // Downscale by sampling every Nth pixel when large.
    int sx = 1, sy = 2; // characters are taller, sample more vertically
    int out_w = (w + sx - 1) / sx;
    int out_h = (h + sy - 1) / sy;
    std::vector<char> out; out.reserve(out_w * out_h + out_h);

    for (int y = 0; y < h; y += sy) {
        for (int x = 0; x < w; x += sx) {
            uint32_t px = pixels[y * w + x];
            unsigned r = (px >> 16) & 0xFF;
            unsigned g = (px >> 8) & 0xFF;
            unsigned b = px & 0xFF;
            unsigned lum = (299 * r + 587 * g + 114 * b) / 1000; // luma
            int idx = (lum * 9) / 256; // 0..8
            if (idx < 0) idx = 0; if (idx > 8) idx = 8;
            out.push_back(luminance_chars[idx]);
        }
        out.push_back('\n');
    }

    // Print a header and the ASCII art to stdout.
    std::printf("[hydra] AAlib render (%dx%d -> %dx%d)\n", w, h, out_w, out_h);
    std::fwrite(out.data(), 1, out.size(), stdout);
    std::fflush(stdout);
}

void AALibBackend::shutdown(PlatformContext& ctx) {
    (void)ctx;
    // Reset state
    last_width = 0;
    last_height = 0;
}
