// SPDX-License-Identifier: BSD-3-Clause
// Simple CLI to reset camera/flags/selection via libhydra.

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

#include "../drivers/libhydra/hydra.h"

int main(int argc, char** argv) {
    const char* dev = (argc > 1) ? argv[1] : "/dev/hydra_pcie";

    struct hydra_handle h = HYDRA_HANDLE_INIT;
    int ret = hydra_open(&h, dev);
    if (ret != 0) {
        perror("hydra_open");
        return (ret == -ENOENT || ret == -ENODEV) ? 77 : 1;
    }

    // Defaults mirror sim reset: position (10,10,10), dir (-1,0,0), plane (0,64) in s16.
    ret = hydra_soft_reset(&h);
    if (ret) goto out;
    ret = hydra_set_camera_raw(&h, -2560, -2560, -2560, -32768, 0, 0, 0, 64);
    if (ret) goto out;
    ret = hydra_set_flags(&h, false, false, false, false, false);
    if (ret) goto out;
    ret = hydra_set_selection(&h, false, 0, 0, 0);
    if (ret) goto out;

    printf("[hydra_cam_reset] camera/flags/selection reset on %s\n", dev);
out:
    hydra_close(&h);
    return ret ? 1 : 0;
}
