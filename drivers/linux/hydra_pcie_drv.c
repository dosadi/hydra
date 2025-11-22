// SPDX-License-Identifier: BSD-3-Clause
// hydra_pcie_drv.c - Minimal PCIe driver stub for Hydra device
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/interrupt.h>
#include <linux/debugfs.h>
#include <linux/seq_file.h>
#include <linux/miscdevice.h>
#include <linux/mm.h>
#include <linux/delay.h>
#include <linux/uaccess.h>

#define DRV_NAME "hydra_pcie"

// Placeholder IDs; update when assigned officially.
#define HYDRA_VENDOR_ID_DEFAULT 0x1BAD
#define HYDRA_DEVICE_ID_DEFAULT 0x2024

#include "uapi/hydra_ioctl.h"
#include "uapi/hydra_regs.h"

struct hydra_dev {
    struct pci_dev *pdev;
    void __iomem *bar0;
    resource_size_t bar0_start;
    resource_size_t bar0_len;
    void __iomem *bar1;
    resource_size_t bar1_start;
    resource_size_t bar1_len;
    int irq;
    u64 irq_count;
    u64 frame_irq;
    u64 dma_irq;
    u64 blit_irq;
    struct dentry *dbg_dir;
    struct miscdevice miscdev;
};

static bool enable_msi = true;
module_param(enable_msi, bool, 0444);
MODULE_PARM_DESC(enable_msi, "Enable MSI/MSI-X if available (default: true)");

static inline u32 hydra_bar0_rd32(struct hydra_dev *hdev, u32 off)
{
    if (!hdev->bar0 || off + sizeof(u32) > hdev->bar0_len)
        return 0;
    return readl(hdev->bar0 + off);
}

static inline void hydra_bar0_wr32(struct hydra_dev *hdev, u32 off, u32 v)
{
    if (!hdev->bar0 || off + sizeof(u32) > hdev->bar0_len)
        return;
    writel(v, hdev->bar0 + off);
}

static const struct pci_device_id hydra_pci_ids[] = {
    { PCI_DEVICE(HYDRA_VENDOR_ID_DEFAULT, HYDRA_DEVICE_ID_DEFAULT) },
    { 0, }
};
MODULE_DEVICE_TABLE(pci, hydra_pci_ids);

static irqreturn_t hydra_irq(int irq, void *dev_id)
{
    struct hydra_dev *hdev = dev_id;
    u32 status = 0;

    if (hdev->bar0)
        status = hydra_bar0_rd32(hdev, HYDRA_REG_INT_STATUS);

    if (status)
        hydra_bar0_wr32(hdev, HYDRA_REG_INT_STATUS, status); // RW1C

    if (status & HYDRA_INT_FRAME_DONE)
        hdev->frame_irq++;
    if (status & HYDRA_INT_DMA_DONE)
        hdev->dma_irq++;
    if (status & HYDRA_INT_BLIT_DONE)
        hdev->blit_irq++;
    hdev->irq_count++;
    dev_dbg(&hdev->pdev->dev, DRV_NAME ": IRQ %d count=%llu status=0x%x\n", irq,
            (unsigned long long)hdev->irq_count, status);
    return status ? IRQ_HANDLED : IRQ_NONE;
}

static int hydra_dbg_show(struct seq_file *s, void *unused)
{
    struct hydra_dev *hdev = s->private;
    u32 status = hydra_bar0_rd32(hdev, HYDRA_REG_STATUS);
    u32 int_status = hydra_bar0_rd32(hdev, HYDRA_REG_INT_STATUS);
    u32 int_mask = hydra_bar0_rd32(hdev, HYDRA_REG_INT_MASK);
    seq_printf(s, "BAR0 start=0x%pa len=0x%llx\n",
               &hdev->bar0_start, (unsigned long long)hdev->bar0_len);
    if (hdev->bar1)
        seq_printf(s, "BAR1 start=0x%pa len=0x%llx\n",
                   &hdev->bar1_start, (unsigned long long)hdev->bar1_len);
    seq_printf(s, "IRQ=%d\n", hdev->irq);
    seq_printf(s, "IRQ count=%llu frame=%llu dma=%llu blit=%llu\n",
               (unsigned long long)hdev->irq_count,
               (unsigned long long)hdev->frame_irq,
               (unsigned long long)hdev->dma_irq,
               (unsigned long long)hdev->blit_irq);
    seq_printf(s, "STATUS=0x%08x INT_STATUS=0x%08x INT_MASK=0x%08x\n",
               status, int_status, int_mask);
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

static int hydra_mmap(struct file *file, struct vm_area_struct *vma)
{
    struct hydra_dev *hdev = container_of(file->private_data, struct hydra_dev, miscdev);
    unsigned long pgoff = vma->vm_pgoff;
    unsigned long len = vma->vm_end - vma->vm_start;
    resource_size_t phys = 0;

    if (pgoff == 0) {
        if (len > hdev->bar0_len)
            return -EINVAL;
        phys = hdev->bar0_start;
    } else {
        /* Map BAR1 when pgoff != 0 */
        if (!hdev->bar1 || len > hdev->bar1_len)
            return -EINVAL;
        phys = hdev->bar1_start + (pgoff << PAGE_SHIFT);
        if (phys + len > hdev->bar1_start + hdev->bar1_len)
            return -EINVAL;
    }

    vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
    if (remap_pfn_range(vma, vma->vm_start, phys >> PAGE_SHIFT, len, vma->vm_page_prot))
        return -EAGAIN;
    return 0;
}

static long hydra_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
    struct hydra_dev *hdev = container_of(file->private_data, struct hydra_dev, miscdev);
    struct hydra_reg_rw reg;
    struct hydra_info info;
    struct hydra_dma_req dma;

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
        info.bar1_start = hdev->bar1_start;
        info.bar1_len   = hdev->bar1_len;
        info.irq_count  = hdev->irq_count;
        if (copy_to_user((void __user *)arg, &info, sizeof(info)))
            return -EFAULT;
        return 0;
    case HYDRA_IOCTL_RD32:
        if (copy_from_user(&reg, (void __user *)arg, sizeof(reg)))
            return -EFAULT;
        if (reg.offset + sizeof(u32) > hdev->bar0_len ||
            reg.offset + sizeof(u32) > HYDRA_BAR0_SIZE ||
            reg.offset & 0x3)
            return -EINVAL;
        reg.value = readl(hdev->bar0 + reg.offset);
        if (copy_to_user((void __user *)arg, &reg, sizeof(reg)))
            return -EFAULT;
        return 0;
    case HYDRA_IOCTL_WR32:
        if (copy_from_user(&reg, (void __user *)arg, sizeof(reg)))
            return -EFAULT;
        if (reg.offset + sizeof(u32) > hdev->bar0_len ||
            reg.offset + sizeof(u32) > HYDRA_BAR0_SIZE ||
            reg.offset & 0x3)
            return -EINVAL;
        writel(reg.value, hdev->bar0 + reg.offset);
        return 0;
    case HYDRA_IOCTL_DMA:
        if (copy_from_user(&dma, (void __user *)arg, sizeof(dma)))
            return -EFAULT;
        /* Stub: program BAR0 DMA registers and poll. */
        if (dma.len == 0 || dma.src >= hdev->bar0_len || dma.dst >= hdev->bar0_len)
            return -EINVAL;
        hydra_bar0_wr32(hdev, HYDRA_REG_DMA_SRC, (u32)dma.src);
        hydra_bar0_wr32(hdev, HYDRA_REG_DMA_DST, (u32)dma.dst);
        hydra_bar0_wr32(hdev, HYDRA_REG_DMA_LEN, dma.len);
        hydra_bar0_wr32(hdev, HYDRA_REG_DMA_CMD, 1);
        /* Poll done (stub). */
        {
            int i;
            for (i = 0; i < 1000; i++) {
                u32 st = hydra_bar0_rd32(hdev, HYDRA_REG_DMA_STATUS);
                if (st & HYDRA_INT_DMA_DONE)
                    break;
                udelay(10);
            }
        }
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
    .mmap           = hydra_mmap,
};

static int hydra_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
    int err;
    resource_size_t bar0_start, bar0_len, bar1_start = 0, bar1_len = 0;
    void __iomem *bar0, *bar1 = NULL;
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
    if (pci_resource_len(pdev, 1)) {
        bar1_start = pci_resource_start(pdev, 1);
        bar1_len   = pci_resource_len(pdev, 1);
        bar1 = pci_iomap(pdev, 1, 0);
        if (bar1) {
            dev_info(&pdev->dev, "BAR1 start=0x%pa len=0x%llx\n",
                     &bar1_start, (unsigned long long)bar1_len);
            hdev->bar1 = bar1;
            hdev->bar1_start = bar1_start;
            hdev->bar1_len   = bar1_len;
        }
    }
    /* Clear/enable interrupts if the CSR map is present. */
    hydra_bar0_wr32(hdev, HYDRA_REG_INT_STATUS, 0xFFFFFFFF);
    hydra_bar0_wr32(hdev, HYDRA_REG_INT_MASK,
                    HYDRA_INT_FRAME_DONE | HYDRA_INT_DMA_DONE | HYDRA_INT_BLIT_DONE);

    if (enable_msi)
        irq = pci_alloc_irq_vectors(pdev, 1, 1, PCI_IRQ_MSI | PCI_IRQ_MSIX | PCI_IRQ_LEGACY);
    else
        irq = pci_alloc_irq_vectors(pdev, 1, 1, PCI_IRQ_LEGACY);
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
    if (bar1)
        pci_iounmap(pdev, bar1);
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
