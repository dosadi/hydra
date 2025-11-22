// SPDX-License-Identifier: BSD-3-Clause
// hydra_pcie_drv.c - Minimal PCIe driver stub for Hydra device
#include <linux/module.h>
#include <linux/pci.h>

#define DRV_NAME "hydra_pcie"

// Placeholder IDs; update when assigned officially.
#define HYDRA_VENDOR_ID 0x1BAD
#define HYDRA_DEVICE_ID 0x2024

static const struct pci_device_id hydra_pci_ids[] = {
    { PCI_DEVICE(HYDRA_VENDOR_ID, HYDRA_DEVICE_ID) },
    { 0, }
};
MODULE_DEVICE_TABLE(pci, hydra_pci_ids);

static int hydra_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
    int err;
    resource_size_t bar0_start, bar0_len;
    void __iomem *bar0;

    dev_info(&pdev->dev, DRV_NAME ": probe vendor=0x%04x device=0x%04x\n",
             pdev->vendor, pdev->device);

    err = pci_enable_device_mem(pdev);
    if (err) {
        dev_err(&pdev->dev, "pci_enable_device_mem failed: %d\n", err);
        return err;
    }

    err = pci_request_mem_regions(pdev, DRV_NAME);
    if (err) {
        dev_err(&pdev->dev, "pci_request_mem_regions failed: %d\n", err);
        goto err_disable;
    }

    pci_set_master(pdev);

    bar0_start = pci_resource_start(pdev, 0);
    bar0_len   = pci_resource_len(pdev, 0);
    bar0 = pci_iomap(pdev, 0, 0);
    if (!bar0) {
        dev_err(&pdev->dev, "pci_iomap BAR0 failed\n");
        err = -ENODEV;
        goto err_release;
    }

    dev_info(&pdev->dev, "BAR0 start=0x%pa len=0x%llx\n",
             &bar0_start, (unsigned long long)bar0_len);

    // TODO: BAR mapping, DMA mask, MSI/MSI-X setup, register map.

    // For now, unmap immediately (no persistent state)
    pci_iounmap(pdev, bar0);
err_release:
    pci_release_mem_regions(pdev);
err_disable:
    pci_disable_device(pdev);
    return 0;
}

static void hydra_remove(struct pci_dev *pdev)
{
    dev_info(&pdev->dev, DRV_NAME ": remove\n");
    pci_release_mem_regions(pdev);
    pci_disable_device(pdev);
}

static struct pci_driver hydra_pci_driver = {
    .name     = DRV_NAME,
    .id_table = hydra_pci_ids,
    .probe    = hydra_probe,
    .remove   = hydra_remove,
};

module_pci_driver(hydra_pci_driver);

MODULE_LICENSE("BSD");
MODULE_AUTHOR("Hydra Team");
MODULE_DESCRIPTION("Hydra PCIe driver stub");
