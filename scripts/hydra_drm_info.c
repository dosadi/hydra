// Minimal tool to query the Hydra DRM render node.
// Build: gcc -I drivers/linux/uapi -o scripts/hydra_drm_info scripts/hydra_drm_info.c -ldrm

#include <libdrm/drm.h>
#include <fcntl.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "../drivers/linux/uapi/hydra_drm.h"
#include "../drivers/libhydra/hydra.h"
#include "../drivers/linux/uapi/hydra_regs.h"

static int do_ioctl(int fd, unsigned long req, void* arg, const char* name)
{
    int ret = ioctl(fd, req, arg);
    if (ret < 0) {
        fprintf(stderr, "ioctl %s failed (req=0x%lx): %s\n",
                name ? name : "(unknown)", req, strerror(errno));
    }
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

    struct hydra_version ver = {0};
    if (ioctl(fd, HYDRA_IOCTL_VERSION, &ver) == 0) {
        if (ver.abi_major != HYDRA_ABI_MAJOR) {
            fprintf(stderr, "ABI mismatch: user ABI %u.%u vs kernel %u.%u\n",
                    HYDRA_ABI_MAJOR, HYDRA_ABI_MINOR, ver.abi_major, ver.abi_minor);
            rc = 1;
            goto out;
        }
        if (ver.sizeof_info != sizeof(struct hydra_info) ||
            ver.sizeof_dma_req != sizeof(struct hydra_dma_req) ||
            ver.sizeof_reg_rw != sizeof(struct hydra_reg_rw)) {
            fprintf(stderr, "Struct size mismatch (user vs kernel): info %zu/%u dma_req %zu/%u reg_rw %zu/%u\n",
                    sizeof(struct hydra_info), ver.sizeof_info,
                    sizeof(struct hydra_dma_req), ver.sizeof_dma_req,
                    sizeof(struct hydra_reg_rw), ver.sizeof_reg_rw);
            rc = 1;
            goto out;
        }
    } else if (errno != ENOTTY) {
        perror("ioctl HYDRA_IOCTL_VERSION");
        rc = 1;
        goto out;
    }

    struct drm_hydra_info info = {0};
    if (do_ioctl(fd, DRM_IOCTL_HYDRA_INFO, &info, "DRM_IOCTL_HYDRA_INFO") != 0) {
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
    if (do_ioctl(fd, DRM_IOCTL_HYDRA_CSROUT, &csrs, "DRM_IOCTL_HYDRA_CSROUT") != 0) {
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
