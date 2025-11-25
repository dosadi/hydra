// Minimal tool to query the Hydra DRM render node.
// Build: gcc -I drivers/linux/uapi -o scripts/hydra_drm_info scripts/hydra_drm_info.c -ldrm

#include <libdrm/drm.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "../drivers/linux/uapi/hydra_drm.h"
#include "../drivers/libhydra/hydra.h"
#include "../drivers/linux/uapi/hydra_regs.h"

static int do_ioctl(int fd, unsigned long req, void* arg)
{
    int ret = ioctl(fd, req, arg);
    if (ret < 0)
        perror("ioctl");
    return ret;
}

int main(int argc, char** argv)
{
    const char* node = (argc > 1) ? argv[1] : "/dev/dri/renderD128";
    int fd = open(node, O_RDWR);
    if (fd < 0) {
        perror("open render node");
        return 1;
    }

    int rc = 0;
    struct drm_hydra_info info = {0};
    if (do_ioctl(fd, DRM_IOCTL_HYDRA_INFO, &info) != 0) {
        rc = 1;
        goto out;
    }
    printf("libhydra version (userland): %s\n", hydra_version_string());
    printf("Hydra DRM info:\n");
    printf("  vendor=0x%04x device=0x%04x\n", info.vendor, info.device);
    printf("  BAR0 start=0x%llx len=0x%llx\n",
           (unsigned long long)info.bar0_start,
           (unsigned long long)info.bar0_len);
    printf("  BAR1 start=0x%llx len=0x%llx\n",
           (unsigned long long)info.bar1_start,
           (unsigned long long)info.bar1_len);

    struct drm_hydra_csraut csrs = {0};
    csrs.count = 2;
    csrs.offsets[0] = HYDRA_REG_STATUS;
    csrs.offsets[1] = HYDRA_REG_INT_STATUS;
    if (do_ioctl(fd, DRM_IOCTL_HYDRA_CSROUT, &csrs) != 0) {
        rc = 1;
        goto out;
    }
    printf("CSR status:\n");
    for (uint32_t i = 0; i < csrs.count; i++) {
        printf("  [0x%04x] = 0x%08x\n", csrs.offsets[i], csrs.values[i]);
    }

out:
    close(fd);
    return rc;
}
