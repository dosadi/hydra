// ============================================================================
// backend_vnc.cpp
// - VNC backend for remote viewing and automation.
// - Uses libvncserver to provide VNC server functionality.
// ============================================================================

#include "backend_vnc.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <rfb/rfb.h>

struct VncContext {
    rfbScreenInfoPtr server = nullptr;
    int width = 0;
    int height = 0;
    char* framebuffer = nullptr;
};

static void destroy_context(VncContext* vc) {
    if (!vc) return;
    if (vc->server) {
        rfbScreenCleanup(vc->server);
        vc->server = nullptr;
    }
    if (vc->framebuffer) {
        free(vc->framebuffer);
        vc->framebuffer = nullptr;
    }
    delete vc;
}

VNCBackend::VNCBackend() {}

VNCBackend::~VNCBackend() {
    if (context) destroy_context(context);
}

bool VNCBackend::init(PlatformContext& ctx, const PlatformConfig& cfg) {
    context = new VncContext();
    if (!context) return false;

    context->width = cfg.width;
    context->height = cfg.height;

    // Allocate framebuffer (32-bit RGBA)
    size_t fb_size = static_cast<size_t>(context->width) * context->height * 4;
    context->framebuffer = static_cast<char*>(malloc(fb_size));
    if (!context->framebuffer) {
        destroy_context(context);
        context = nullptr;
        return false;
    }
    memset(context->framebuffer, 0, fb_size);

    // Create VNC server
    context->server = rfbGetScreen(nullptr, nullptr, context->width, context->height, 8, 3, 4);
    if (!context->server) {
        destroy_context(context);
        context = nullptr;
        return false;
    }

    // Configure server
    context->server->frameBuffer = context->framebuffer;
    context->server->port = 5900;  // Default VNC port
    context->server->alwaysShared = TRUE;

    // Set server name
    context->server->desktopName = "Hydra VNC Backend";

    // Initialize server
    rfbInitServer(context->server);
    rfbRunEventLoop(context->server, -1, TRUE);

    ctx.user = context;
    std::fprintf(stderr, "[vnc] VNC server started on port 5900 (%dx%d)\n", context->width, context->height);
    std::fprintf(stderr, "[vnc] Connect with: vncviewer localhost:5900\n");

    return true;
}

void VNCBackend::present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    if (!context || !pixels || w <= 0 || h <= 0) return;

    // Ensure dimensions match
    if (w != context->width || h != context->height) {
        std::fprintf(stderr, "[vnc] Framebuffer size mismatch (%dx%d vs %dx%d)\n",
                    w, h, context->width, context->height);
        return;
    }

    // Copy pixels to VNC framebuffer (convert ARGB to RGBA if needed)
    char* dst = context->framebuffer;
    const uint32_t* src = pixels;
    for (int i = 0; i < w * h; ++i) {
        uint32_t pixel = *src++;
        // ARGB to RGBA conversion
        *dst++ = (pixel >> 16) & 0xFF;  // R
        *dst++ = (pixel >> 8) & 0xFF;   // G
        *dst++ = pixel & 0xFF;          // B
        *dst++ = (pixel >> 24) & 0xFF;  // A
    }

    // Mark framebuffer as updated
    rfbMarkRectAsModified(context->server, 0, 0, context->width, context->height);
}

void VNCBackend::shutdown(PlatformContext& ctx) {
    if (context) {
        destroy_context(context);
        context = nullptr;
    }
    ctx.user = nullptr;
    std::fprintf(stderr, "[vnc] VNC server shut down\n");
}