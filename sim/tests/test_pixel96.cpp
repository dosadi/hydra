// SPDX-License-Identifier: BSD-3-Clause
// ============================================================================
// test_pixel96.cpp
// - Unit test for pixel96_to_argb conversion function
// - Guards the 96-bit to 32-bit ARGB packing assumptions
// ============================================================================

#include <cstdint>
#include <cstdio>
#include <cassert>

// Copy of the function from live_sdl_main.cpp
static uint32_t pixel96_to_argb(uint32_t w0, uint32_t w1, uint32_t w2) {
    (void)w0; (void)w2;
    uint8_t r = (w1 >> 24) & 0xFF;
    uint8_t g = (w1 >> 16) & 0xFF;
    uint8_t b = (w1 >>  8) & 0xFF;
    uint8_t a = 0xFF;
    return (uint32_t(a) << 24) |
           (uint32_t(r) << 16) |
           (uint32_t(g) << 8)  |
            uint32_t(b);
}

int main() {
    // Test 1: Black pixel
    {
        uint32_t argb = pixel96_to_argb(0, 0x00000000, 0);
        assert((argb & 0xFF000000) == 0xFF000000); // Alpha = 0xFF
        assert((argb & 0x00FFFFFF) == 0x00000000); // RGB = 0,0,0
        std::printf("Test 1 (black): PASS\n");
    }

    // Test 2: White pixel
    {
        uint32_t argb = pixel96_to_argb(0, 0xFFFFFF00, 0);
        assert((argb & 0xFF000000) == 0xFF000000); // Alpha = 0xFF
        assert((argb & 0x00FFFFFF) == 0x00FFFFFF); // RGB = 255,255,255
        std::printf("Test 2 (white): PASS\n");
    }

    // Test 3: Red pixel (R=255, G=0, B=0)
    {
        uint32_t argb = pixel96_to_argb(0, 0xFF000000, 0);
        assert(argb == 0xFFFF0000); // ARGB = 255,255,0,0
        std::printf("Test 3 (red): PASS\n");
    }

    // Test 4: Green pixel (R=0, G=255, B=0)
    {
        uint32_t argb = pixel96_to_argb(0, 0x00FF0000, 0);
        assert(argb == 0xFF00FF00); // ARGB = 255,0,255,0
        std::printf("Test 4 (green): PASS\n");
    }

    // Test 5: Blue pixel (R=0, G=0, B=255)
    {
        uint32_t argb = pixel96_to_argb(0, 0x0000FF00, 0);
        assert(argb == 0xFF0000FF); // ARGB = 255,0,0,255
        std::printf("Test 5 (blue): PASS\n");
    }

    // Test 6: Custom color (R=128, G=64, B=192)
    {
        uint32_t argb = pixel96_to_argb(0, 0x8040C000, 0);
        assert(argb == 0xFF8040C0); // ARGB = 255,128,64,192
        std::printf("Test 6 (custom): PASS\n");
    }

    // Test 7: Verify w0 and w2 are ignored
    {
        uint32_t argb1 = pixel96_to_argb(0xAAAAAAAA, 0xFF000000, 0xBBBBBBBB);
        uint32_t argb2 = pixel96_to_argb(0x00000000, 0xFF000000, 0x00000000);
        assert(argb1 == argb2); // Should be identical (red)
        std::printf("Test 7 (w0/w2 ignored): PASS\n");
    }

    std::printf("\nAll pixel96_to_argb tests passed!\n");
    return 0;
}
