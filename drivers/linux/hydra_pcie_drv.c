// SPDX-License-Identifier: BSD-3-Clause
// hydra_pcie_drv.c - Minimal PCIe driver stub for Hydra device
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/interrupt.h>
#include <linux/debugfs.h>
#include <linux/seq_file.h>
#include <linux/miscdevice.h>
#include <linux/uaccess.h>

#define DRV_NAME "hydra_pcie"

// Placeholder IDs; update when assigned officially.
#define HYDRA_VENDOR_ID_DEFAULT 0x1BAD
#define HYDRA_DEVICE_ID_DEFAULT 0x2024

#include "uapi/hydra_ioctl.h"

struct hydra_dev {
    struct pci_dev *pdev;
    void __iomem *bar0;
    resource_size_t bar0_start;
    resource_size_t bar0_len;
    int irq;
    u64 irq_count;
    struct dentry *dbg_dir;
    struct miscdevice miscdev;
};

static const struct pci_device_id hydra_pci_ids[] = {
    { PCI_DEVICE(HYDRA_VENDOR_ID_DEFAULT, HYDRA_DEVICE_ID_DEFAULT) },
    { 0, }
};
MODULE_DEVICE_TABLE(pci, hydra_pci_ids);

static irqreturn_t hydra_irq(int irq, void *dev_id)
{
    struct hydra_dev *hdev = dev_id;
    hdev->irq_count++;
    dev_dbg(&hdev->pdev->dev, DRV_NAME ": IRQ %d count=%llu\n", irq,
            (unsigned long long)hdev->irq_count);
    // TODO: read/clear interrupt status from BARs when defined.
    return IRQ_HANDLED;
}

static int hydra_dbg_show(struct seq_file *s, void *unused)
{
    struct hydra_dev *hdev = s->private;
    seq_printf(s, "BAR0 start=0x%pa len=0x%llx\n",
               &hdev->bar0_start, (unsigned long long)hdev->bar0_len);
    seq_printf(s, "IRQ=%d\n", hdev->irq);
    seq_printf(s, "IRQ count=%llu\n", (unsigned long long)hdev->irq_count);
    return 0;
}

static int hydra_dbg_open(struct inode *inode, struct file *file)
{
    return single_open(file, hydra_dbg_show, inode->i_private);
}

static const struct file_operations hydra_dbg_fops = {
    .owner   = THIS_MODULE,
    .open    = hydra_dbg_open,
    .read    = seq_read,
    .llseek  = seq_lseek,
    .release = single_release,
};

static long hydra_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
    struct hydra_dev *hdev = container_of(file->private_data, struct hydra_dev, miscdev);
    struct hydra_reg_rw reg;
    struct hydra_info info;

    if (!hdev->bar0)
        return -ENODEV;

    if (_IOC_TYPE(cmd) != HYDRA_IOCTL_MAGIC)
        return -ENOTTY;

    switch (cmd) {
    case HYDRA_IOCTL_INFO:
        info.vendor     = hdev->pdev->vendor;
        info.device     = hdev->pdev->device;
        info.irq        = hdev->irq;
        info.bar0_start = hdev->bar0_start;
        info.bar0_len   = hdev->bar0_len;
        info.irq_count  = hdev->irq_count;
        if (copy_to_user((void __user *)arg, &info, sizeof(info)))
            return -EFAULT;
        return 0;
    case HYDRA_IOCTL_RD32:
        if (copy_from_user(&reg, (void __user *)arg, sizeof(reg)))
            return -EFAULT;
        if (reg.offset + sizeof(u32) > hdev->bar0_len || reg.offset & 0x3)
            return -EINVAL;
        reg.value = readl(hdev->bar0 + reg.offset);
        if (copy_to_user((void __user *)arg, &reg, sizeof(reg)))
            return -EFAULT;
        return 0;
    case HYDRA_IOCTL_WR32:
        if (copy_from_user(&reg, (void __user *)arg, sizeof(reg)))
            return -EFAULT;
        if (reg.offset + sizeof(u32) > hdev->bar0_len || reg.offset & 0x3)
            return -EINVAL;
        writel(reg.value, hdev->bar0 + reg.offset);
        return 0;
    default:
        return -ENOTTY;
    }
}

static const struct file_operations hydra_misc_fops = {
    .owner          = THIS_MODULE,
    .unlocked_ioctl = hydra_ioctl,
    .compat_ioctl   = hydra_ioctl,
    .llseek         = no_llseek,
};

static int hydra_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
    int err;
    resource_size_t bar0_start, bar0_len;
    void __iomem *bar0;
    int irq = -1;
    struct hydra_dev *hdev;

    dev_info(&pdev->dev, DRV_NAME ": probe vendor=0x%04x device=0x%04x\n",
             pdev->vendor, pdev->device);

    hdev = devm_kzalloc(&pdev->dev, sizeof(*hdev), GFP_KERNEL);
    if (!hdev)
        return -ENOMEM;
    hdev->pdev = pdev;
    pci_set_drvdata(pdev, hdev);

    err = pci_enable_device_mem(pdev);
    if (err) {
        dev_err(&pdev->dev, "pci_enable_device_mem failed: %d\n", err);
        return err;
    }

    err = pci_set_dma_mask(pdev, DMA_BIT_MASK(64));
    if (err) {
        dev_warn(&pdev->dev, "64-bit DMA not supported (%d), falling back to 32-bit\n", err);
        err = pci_set_dma_mask(pdev, DMA_BIT_MASK(32));
        if (err) {
            dev_err(&pdev->dev, "32-bit DMA mask setup failed: %d\n", err);
            goto err_disable;
        }
    }
    err = pci_set_consistent_dma_mask(pdev, DMA_BIT_MASK(64));
    if (err) {
        dev_warn(&pdev->dev, "consistent 64-bit DMA not supported (%d), falling back to 32-bit\n", err);
        err = pci_set_consistent_dma_mask(pdev, DMA_BIT_MASK(32));
        if (err) {
            dev_err(&pdev->dev, "consistent 32-bit DMA mask failed: %d\n", err);
            goto err_disable;
        }
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
    hdev->bar0 = bar0;
    hdev->bar0_start = bar0_start;
    hdev->bar0_len   = bar0_len;

    irq = pci_alloc_irq_vectors(pdev, 1, 1, PCI_IRQ_MSI | PCI_IRQ_MSIX | PCI_IRQ_LEGACY);
    if (irq < 0) {
        dev_warn(&pdev->dev, "No MSI/MSI-X, falling back to legacy (%d)\n", irq);
        irq = pci_alloc_irq_vectors(pdev, 1, 1, PCI_IRQ_LEGACY);
    }
    if (irq < 0) {
        dev_warn(&pdev->dev, "Failed to allocate IRQ vectors (%d)\n", irq);
        hdev->irq = -1;
    } else {
        hdev->irq = pci_irq_vector(pdev, 0);
        err = request_irq(hdev->irq, hydra_irq, 0, DRV_NAME, hdev);
        if (err) {
            dev_warn(&pdev->dev, "request_irq failed: %d\n", err);
            pci_free_irq_vectors(pdev);
            hdev->irq = -1;
        }
    }

    hdev->dbg_dir = debugfs_create_dir(DRV_NAME, NULL);
    if (!IS_ERR_OR_NULL(hdev->dbg_dir))
        debugfs_create_file("status", 0444, hdev->dbg_dir, hdev, &hydra_dbg_fops);

    // TODO: BAR mapping, DMA mask, MSI/MSI-X setup, register map.

    hdev->miscdev.minor = MISC_DYNAMIC_MINOR;
    hdev->miscdev.name  = DRV_NAME;
    hdev->miscdev.fops  = &hydra_misc_fops;
    err = misc_register(&hdev->miscdev);
    if (err) {
        dev_warn(&pdev->dev, "misc_register failed: %d\n", err);
        hdev->miscdev.minor = MISC_DYNAMIC_MINOR;
    }

    return 0;
err_release:
    if (hdev->irq >= 0) {
        free_irq(hdev->irq, hdev);
        pci_free_irq_vectors(pdev);
    }
    debugfs_remove_recursive(hdev->dbg_dir);
    hdev->dbg_dir = NULL;
    if (bar0)
        pci_iounmap(pdev, bar0);
    pci_release_mem_regions(pdev);
err_disable:
    pci_disable_device(pdev);
    return err;
}

static void hydra_remove(struct pci_dev *pdev)
{
    struct hydra_dev *hdev = pci_get_drvdata(pdev);

    dev_info(&pdev->dev, DRV_NAME ": remove\n");
    if (hdev) {
        if (hdev->miscdev.minor != MISC_DYNAMIC_MINOR)
            misc_deregister(&hdev->miscdev);
        if (hdev->irq >= 0) {
            free_irq(hdev->irq, hdev);
            pci_free_irq_vectors(pdev);
        }
        if (hdev->bar0)
            pci_iounmap(pdev, hdev->bar0);
        debugfs_remove_recursive(hdev->dbg_dir);
        hdev->dbg_dir = NULL;
    }
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
