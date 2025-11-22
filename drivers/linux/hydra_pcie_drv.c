// SPDX-License-Identifier: BSD-3-Clause
// hydra_pcie_drv.c - Minimal PCIe driver stub for Hydra device
#include <linux/module.h>
#include <linux/pci.h>

#define DRV_NAME "hydra_pcie"

// TODO: replace with real IDs
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

    dev_info(&pdev->dev, DRV_NAME ": probe vendor=0x%04x device=0x%04x\n",
             pdev->vendor, pdev->device);

    err = pci_enable_device(pdev);
    if (err) {
        dev_err(&pdev->dev, "pci_enable_device failed: %d\n", err);
        return err;
    }

    // TODO: BAR mapping, DMA mask, MSI/MSI-X setup, register map.

    return 0;
}

static void hydra_remove(struct pci_dev *pdev)
{
    dev_info(&pdev->dev, DRV_NAME ": remove\n");
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
