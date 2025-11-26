// SPDX-License-Identifier: BSD-3-Clause
// libhydra sample: set camera, flags, and selection, then dump INT_STATUS.

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
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

    printf("libhydra version: %s\n", hydra_version_string());

    ret = hydra_set_camera_raw(&h, -512, -512, -512, -32768, 0, 0, 0, 64);
    if (ret) goto out;
    ret = hydra_set_flags(&h, true, false, true, false, false);
    if (ret) goto out;
    ret = hydra_set_selection(&h, true, 1, 2, 3);
    if (ret) goto out;

    uint32_t int_status = 0;
    hydra_get_int_status(&h, &int_status);
    printf("[hydra_cam_flags_demo] INT_STATUS=0x%08x after programming camera/flags/selection\n", int_status);

out:
    hydra_close(&h);
    return ret ? 1 : 0;
}
