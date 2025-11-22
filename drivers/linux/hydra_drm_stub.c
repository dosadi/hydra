// SPDX-License-Identifier: BSD-3-Clause
// hydra_drm_stub.c - Minimal DRM/KMS skeleton for Hydra PCIe device.
//
// This is a bring-up placeholder only; it does not expose a mode or render
// node yet. It just binds to the PCI ID, maps BAR0, and registers a DRM device
// so userspace can discover it. Wire up real GEM/BO helpers and planes later.

#include <linux/module.h>
#include <linux/pci.h>
#include <linux/io.h>
#include <drm/drm_drv.h>
#include <drm/drm_file.h>
#include <drm/drm_ioctl.h>
#include <drm/drm_prime.h>
#include <drm/drm_gem_shmem_helper.h>
#include <drm/drm_gem_framebuffer_helper.h>
#include <drm/drm_pci.h>

#include "uapi/hydra_regs.h"
#include "uapi/hydra_drm.h"

#define HYDRA_VENDOR_ID_DEFAULT 0x1BAD
#define HYDRA_DEVICE_ID_DEFAULT 0x2024

struct hydra_drm {
    struct drm_device *drm;
    void __iomem *bar0;
    resource_size_t bar0_len;
    resource_size_t bar0_start;
    void __iomem *bar1;
    resource_size_t bar1_len;
    resource_size_t bar1_start;
    struct drm_fb_helper *fb_helper;
};

static const struct pci_device_id hydra_drm_pci_tbl[] = {
    { PCI_DEVICE(HYDRA_VENDOR_ID_DEFAULT, HYDRA_DEVICE_ID_DEFAULT) },
    { 0, }
};
MODULE_DEVICE_TABLE(pci, hydra_drm_pci_tbl);

static int hydra_drm_ioctl_info(struct drm_device *drm, void *data, struct drm_file *file)
{
    struct hydra_drm *h = drm_get_drvdata(drm);
    struct drm_hydra_info *info = data;

    info->vendor = HYDRA_VENDOR_ID_DEFAULT;
    info->device = HYDRA_DEVICE_ID_DEFAULT;
    info->bar0_start = h->bar0_start;
    info->bar0_len = h->bar0_len;
    info->bar1_start = h->bar1_start;
    info->bar1_len = h->bar1_len;
    return 0;
}

static int hydra_drm_dumb_create(struct drm_file *file, struct drm_device *drm,
				 struct drm_mode_create_dumb *args)
{
	/* force alignment/padding if needed; otherwise use shmem helper */
	if (!args->bpp)
		args->bpp = 32;
	return drm_gem_shmem_dumb_create(file, drm, args);
}

static int hydra_drm_gem_mmap(struct file *filp, struct vm_area_struct *vma)
{
	return drm_gem_mmap(filp, vma);
}

static const struct file_operations hydra_drm_fops = {
	.owner = THIS_MODULE,
	.open = drm_open,
	.release = drm_release,
	.unlocked_ioctl = drm_ioctl,
	.mmap = hydra_drm_gem_mmap,
	.poll = drm_poll,
	.read = drm_read,
	.llseek = noop_llseek,
};

static const struct drm_ioctl_desc hydra_ioctls[] = {
	DRM_IOCTL_DEF_DRV(HYDRA_INFO, hydra_drm_ioctl_info, DRM_RENDER_ALLOW),
};

static const struct drm_driver hydra_drm_driver = {
	.driver_features = DRIVER_GEM | DRIVER_RENDER,
	.name = "hydra_drm_stub",
	.desc = "Hydra DRM stub (render-only)",
	.date = "2024",
	.major = 0,
	.minor = 4,
	.fops = &hydra_drm_fops,
	.dumb_create = hydra_drm_dumb_create,
	.gem_free_object_unlocked = drm_gem_shmem_free_object,
	.gem_create_object = drm_gem_shmem_create_object,
	.prime_handle_to_fd = drm_gem_prime_handle_to_fd,
	.prime_fd_to_handle = drm_gem_prime_fd_to_handle,
	.gem_prime_import = drm_gem_prime_import,
	.gem_prime_export = drm_gem_prime_export,
	.gem_prime_import_sg_table = drm_gem_shmem_prime_import_sg_table,
	.gem_prime_mmap = drm_gem_prime_mmap,
	.ioctls = hydra_ioctls,
	.num_ioctls = ARRAY_SIZE(hydra_ioctls),
};

static int hydra_drm_pci_probe(struct pci_dev *pdev,
			       const struct pci_device_id *ent)
{
	struct drm_device *drm;
	struct hydra_drm *h;
	int ret;

	ret = pcim_enable_device(pdev);
	if (ret)
		return ret;

	ret = pcim_iomap_regions(pdev, BIT(0), pci_name(pdev));
	if (ret)
		return ret;

	h = devm_kzalloc(&pdev->dev, sizeof(*h), GFP_KERNEL);
	if (!h)
		return -ENOMEM;

	drm = drm_dev_alloc(&hydra_drm_driver, &pdev->dev);
	if (IS_ERR(drm))
		return PTR_ERR(drm);

	h->drm = drm;
    h->bar0 = pcim_iomap_table(pdev)[0];
    h->bar0_len = pci_resource_len(pdev, 0);
    h->bar0_start = pci_resource_start(pdev, 0);
    if (pci_resource_len(pdev, 1)) {
        h->bar1 = pcim_iomap_table(pdev)[1];
        h->bar1_len = pci_resource_len(pdev, 1);
        h->bar1_start = pci_resource_start(pdev, 1);
    }
	drm_set_drvdata(drm, h);
	pci_set_drvdata(pdev, drm);

	ret = drm_dev_register(drm, 0);
	if (ret) {
		drm_dev_put(drm);
		return ret;
	}

	dev_info(&pdev->dev, "Hydra DRM render-only stub registered (BAR0 len=0x%llx)\n",
		 (unsigned long long)h->bar0_len);
	return 0;
}

static void hydra_drm_pci_remove(struct pci_dev *pdev)
{
	struct drm_device *drm = pci_get_drvdata(pdev);

	if (drm) {
		drm_dev_unplug(drm);
		drm_dev_put(drm);
	}
}

static struct pci_driver hydra_drm_pci_driver = {
	.name = "hydra_drm_stub",
	.id_table = hydra_drm_pci_tbl,
	.probe = hydra_drm_pci_probe,
	.remove = hydra_drm_pci_remove,
};

module_pci_driver(hydra_drm_pci_driver);

MODULE_LICENSE("BSD");
MODULE_AUTHOR("Hydra Team");
MODULE_DESCRIPTION("Hydra DRM/KMS stub (render-only dumb buffers)");
