// Implementations for small harness helpers declared in harness_common.h
#include "harness_common.h"
#include <cstdlib>
#include <cstring>
#include <strings.h>

const char* pixel_view_mode_name(PixelViewMode m) {
    switch (m) {
        case PixelViewMode::Color:      return "color";
        case PixelViewMode::Word0:      return "word0";
        case PixelViewMode::Word2:      return "word2";
        case PixelViewMode::SidebandMix:return "sideband";
        default:                        return "unknown";
    }
}

PixelViewMode pixel_view_from_string(const char* s) {
    if (!s) return PixelViewMode::Color;
    if (strcasecmp(s, "color") == 0)    return PixelViewMode::Color;
    if (strcasecmp(s, "word0") == 0)    return PixelViewMode::Word0;
    if (strcasecmp(s, "depth") == 0)    return PixelViewMode::Word0;
    if (strcasecmp(s, "word2") == 0)    return PixelViewMode::Word2;
    if (strcasecmp(s, "reemissure") == 0 || strcasecmp(s, "reem") == 0) return PixelViewMode::Word2;
    if (strcasecmp(s, "sideband") == 0) return PixelViewMode::SidebandMix;
    return PixelViewMode::Color;
}

bool env_truthy(const char* key) {
    if (const char* v = std::getenv(key)) {
        return v[0] != '\0' && v[0] != '0' && strcasecmp(v, "false") != 0;
    }
    return false;
}

std::string flatten_cli_args(int argc, char** argv) {
    std::string out;
    for (int i = 0; i < argc; ++i) {
        if (i) out += ' ';
        if (argv[i]) out += argv[i];
    }
    return out;
}
