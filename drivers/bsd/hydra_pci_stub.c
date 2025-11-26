/* SPDX-License-Identifier: BSD-3-Clause */
/* Hydra FreeBSD PCI driver stub (placeholder) */

#include <sys/types.h>
#include <sys/param.h>
#include <sys/kernel.h>
#include <sys/module.h>
#include <sys/bus.h>
#include <sys/conf.h>
#include <sys/errno.h>
#include <sys/malloc.h>
#include <sys/mutex.h>
#include <sys/proc.h>
#include <sys/sysctl.h>
#include <sys/rman.h>
#include <sys/systm.h>
#include <vm/vm.h>
#include <vm/pmap.h>
#include <dev/pci/pcivar.h>
#include <dev/pci/pcireg.h>
#include <machine/bus.h>
#include <sys/uio.h>

#ifndef __u8
#define __u8  uint8_t
#define __u16 uint16_t
#define __u32 uint32_t
#define __u64 uint64_t
#endif
#include "../linux/uapi/hydra_ioctl.h"
#include "../linux/uapi/hydra_regs.h"

#define HYDRA_VENDOR_ID 0x1BAD
#define HYDRA_DEVICE_ID 0x2024

struct hydra_softc {
    device_t        dev;
    struct resource *bar0;
    struct resource *bar1;
    int             bar0_rid;
    int             bar1_rid;
    uint8_t        *bar0_vaddr;
    uint8_t        *bar1_vaddr;
    struct mtx      lock;
    struct cdev    *cdev;
    uint32_t        int_status;
    uint32_t        int_mask;
    uint32_t        dma_status;
    uint64_t        dma_count;
    uint64_t        irq_count;
    uint64_t        dma_irq_count;
    uint64_t        test_irq_count;
    uint64_t        bar0_len;
    uint64_t        bar1_len;
    struct sysctl_ctx_list sysctl_ctx;
    struct sysctl_oid     *sysctl_tree;
};

static u32
hydra_bar0_rd32(struct hydra_softc *sc, u32 off)
{
    if (sc->bar0_vaddr == NULL || off + sizeof(u32) > HYDRA_BAR0_SIZE)
        return 0;
    return le32toh(*(volatile u32 *)(sc->bar0_vaddr + off));
}

static void
hydra_bar0_wr32(struct hydra_softc *sc, u32 off, u32 v)
{
    if (sc->bar0_vaddr == NULL || off + sizeof(u32) > HYDRA_BAR0_SIZE)
        return;
    *(volatile u32 *)(sc->bar0_vaddr + off) = htole32(v);
}

static int
hydra_ioctl(struct cdev *dev, u_long cmd, caddr_t data, int fflag, struct thread *td)
{
    struct hydra_softc *sc = dev->si_drv1;

    if (sc == NULL || sc->bar0_vaddr == NULL)
        return (ENODEV);

    mtx_lock(&sc->lock);
    switch (cmd) {
    case HYDRA_IOCTL_INFO: {
        struct hydra_info *info = (struct hydra_info *)data;
        info->vendor = HYDRA_VENDOR_ID;
        info->device = HYDRA_DEVICE_ID;
        info->irq = 0;
        info->bar0_start = rman_get_start(sc->bar0);
        info->bar0_len = rman_get_size(sc->bar0);
        info->bar1_start = sc->bar1 ? rman_get_start(sc->bar1) : 0;
        info->bar1_len = sc->bar1 ? rman_get_size(sc->bar1) : 0;
        info->irq_count = sc->irq_count;
        mtx_unlock(&sc->lock);
        return (0);
    }
    case HYDRA_IOCTL_VERSION: {
        struct hydra_version *ver = (struct hydra_version *)data;
        ver->abi_major    = HYDRA_ABI_MAJOR;
        ver->abi_minor    = HYDRA_ABI_MINOR;
        ver->sizeof_info  = sizeof(struct hydra_info);
        ver->sizeof_dma_req = sizeof(struct hydra_dma_req);
        ver->sizeof_reg_rw  = sizeof(struct hydra_reg_rw);
        mtx_unlock(&sc->lock);
        return (0);
    }
    case HYDRA_IOCTL_RD32: {
        struct hydra_reg_rw *rw = (struct hydra_reg_rw *)data;
        if ((rw->offset & 0x3) || rw->offset + 4 > HYDRA_BAR0_SIZE)
            goto inval;
        if (rw->offset == HYDRA_REG_INT_STATUS)
            rw->value = sc->int_status;
        else if (rw->offset == HYDRA_REG_INT_MASK)
            rw->value = sc->int_mask;
        else if (rw->offset == HYDRA_REG_DMA_STATUS)
            rw->value = sc->dma_status;
        else if (rw->offset == HYDRA_REG_STATUS) {
            uint32_t st = 0;
            if (sc->dma_status & HYDRA_STATUS_DMA_DONE)
                st |= HYDRA_STATUS_DMA_DONE;
            if (sc->dma_status & HYDRA_STATUS_DMA_BUSY)
                st |= HYDRA_STATUS_DMA_BUSY;
            rw->value = st;
        } else {
            rw->value = hydra_bar0_rd32(sc, rw->offset);
        }
        mtx_unlock(&sc->lock);
        return (0);
    }
    case HYDRA_IOCTL_WR32: {
        struct hydra_reg_rw *rw = (struct hydra_reg_rw *)data;
        if ((rw->offset & 0x3) || rw->offset + 4 > HYDRA_BAR0_SIZE)
            goto inval;
        /* INT_STATUS is RW1C in RTL; emulate that here. */
        if (rw->offset == HYDRA_REG_INT_STATUS) {
            sc->int_status &= ~rw->value;
            mtx_unlock(&sc->lock);
            return (0);
        }
        if (rw->offset == HYDRA_REG_INT_MASK) {
            sc->int_mask = rw->value;
            mtx_unlock(&sc->lock);
            return (0);
        }
        if (rw->offset == HYDRA_REG_IRQ_TEST) {
            if (rw->value & 0x1)
                sc->int_status |= HYDRA_INT_TEST;
            if (rw->value & 0x1)
                sc->irq_count++;
            if (rw->value & 0x1)
                sc->test_irq_count++;
            mtx_unlock(&sc->lock);
            return (0);
        }
        hydra_bar0_wr32(sc, rw->offset, rw->value);
        mtx_unlock(&sc->lock);
        return (0);
    }
    case HYDRA_IOCTL_DMA: {
        struct hydra_dma_req *dr = (struct hydra_dma_req *)data;
        /* Stub: validate len/offsets within BAR0 window; no real DMA. */
        if (dr->len == 0 ||
            dr->src >= HYDRA_BAR0_SIZE ||
            dr->dst >= HYDRA_BAR0_SIZE ||
            dr->src + dr->len > HYDRA_BAR0_SIZE ||
            dr->dst + dr->len > HYDRA_BAR0_SIZE)
            goto inval;
        /* Pretend done immediately by setting DMA_STATUS done bit. */
        sc->dma_status = HYDRA_STATUS_DMA_DONE;
        sc->dma_count++;
        if (sc->int_mask & HYDRA_INT_DMA_DONE)
            sc->int_status |= HYDRA_INT_DMA_DONE;
        if (sc->int_status & HYDRA_INT_DMA_DONE)
            sc->irq_count++;
        if (sc->int_status & HYDRA_INT_DMA_DONE)
            sc->dma_irq_count++;
        mtx_unlock(&sc->lock);
        return (0); /* pretend success */
    }
    default:
        mtx_unlock(&sc->lock);
        return (ENOTTY);
    }
inval:
    mtx_unlock(&sc->lock);
    return (EINVAL);
}

static int
hydra_open(struct cdev *dev, int oflags, int devtype, struct thread *td)
{
    return (0);
}

static int
hydra_close(struct cdev *dev, int fflag, int devtype, struct thread *td)
{
    return (0);
}

static int
hydra_mmap(struct cdev *dev, vm_ooffset_t offset, vm_paddr_t *paddr,
    int nprot, vm_memattr_t *memattr)
{
    struct hydra_softc *sc = dev->si_drv1;

    if (sc == NULL)
        return (ENODEV);

    if ((offset & PAGE_MASK) != 0)
        return (EINVAL);

    /* Support contiguous mmap of BAR0 then BAR1. */
    if (offset < sc->bar0_len) {
        *paddr = rman_get_start(sc->bar0) + offset;
    } else {
        vm_ooffset_t bar1_off = offset - sc->bar0_len;
        if (sc->bar1 == NULL || bar1_off >= sc->bar1_len)
            return (EINVAL);
        *paddr = rman_get_start(sc->bar1) + bar1_off;
    }

    *memattr = VM_MEMATTR_UNCACHEABLE;
    return (0);
}

static struct cdevsw hydra_cdevsw = {
    .d_version = D_VERSION,
    .d_name    = "hydra",
    .d_open    = hydra_open,
    .d_close   = hydra_close,
    .d_ioctl   = hydra_ioctl,
    .d_mmap    = hydra_mmap,
};

static int
hydra_probe(device_t dev)
{
    if ((pci_get_vendor(dev) == HYDRA_VENDOR_ID) &&
        (pci_get_device(dev) == HYDRA_DEVICE_ID)) {
        device_set_desc(dev, "Hydra PCIe Stub");
        return (BUS_PROBE_DEFAULT);
    }
    return (ENXIO);
}

static int
hydra_attach(device_t dev)
{
    struct hydra_softc *sc = device_get_softc(dev);
    int rid;

    bzero(sc, sizeof(*sc));
    sc->dev = dev;
    pci_enable_busmaster(dev);

    sc->bar0_rid = PCIR_BAR(0);
    sc->bar0 = bus_alloc_resource_any(dev, SYS_RES_MEMORY, &sc->bar0_rid, RF_ACTIVE);
    if (sc->bar0 == NULL) {
        device_printf(dev, "Failed to map BAR0\n");
        return (ENXIO);
    }
    sc->bar0_vaddr = rman_get_virtual(sc->bar0);
    sc->bar0_len = rman_get_size(sc->bar0);
    sc->bar1_rid = PCIR_BAR(1);
    sc->bar1 = bus_alloc_resource_any(dev, SYS_RES_MEMORY, &sc->bar1_rid, RF_ACTIVE);
    if (sc->bar1) {
        sc->bar1_vaddr = rman_get_virtual(sc->bar1);
        sc->bar1_len = rman_get_size(sc->bar1);
    } else {
        sc->bar1_len = 0;
    }

    rid = rman_get_rid(sc->bar0);
    device_printf(dev, "Hydra stub attached: BAR0 mapped (rid=%d), BAR1 %s\n",
                  rid, sc->bar1 ? "mapped" : "absent");
    mtx_init(&sc->lock, "hydra", NULL, MTX_DEF);
    sc->cdev = make_dev(&hydra_cdevsw, 0, UID_ROOT, GID_WHEEL, 0600, "hydra");
    if (sc->cdev)
        sc->cdev->si_drv1 = sc;
    sc->int_status = 0;
    sc->int_mask = 0;
    sc->dma_status = 0;
    sc->dma_count = 0;
    sc->irq_count = 0;
    sc->dma_irq_count = 0;
    sc->test_irq_count = 0;
    sysctl_ctx_init(&sc->sysctl_ctx);
    sc->sysctl_tree = SYSCTL_ADD_NODE(&sc->sysctl_ctx,
        SYSCTL_STATIC_CHILDREN(_dev),
        OID_AUTO,
        device_get_nameunit(dev),
        CTLFLAG_RD,
        0,
        "Hydra device");
    if (sc->sysctl_tree) {
        SYSCTL_ADD_U64(&sc->sysctl_ctx, SYSCTL_CHILDREN(sc->sysctl_tree), OID_AUTO,
            "bar0_len", CTLFLAG_RD, &sc->bar0_len, 0, "BAR0 length");
        SYSCTL_ADD_U64(&sc->sysctl_ctx, SYSCTL_CHILDREN(sc->sysctl_tree), OID_AUTO,
            "bar1_len", CTLFLAG_RD, &sc->bar1_len, 0, "BAR1 length");
        SYSCTL_ADD_U32(&sc->sysctl_ctx, SYSCTL_CHILDREN(sc->sysctl_tree), OID_AUTO,
            "int_status", CTLFLAG_RD, &sc->int_status, 0, "INT_STATUS RW1C latched bits");
        SYSCTL_ADD_U32(&sc->sysctl_ctx, SYSCTL_CHILDREN(sc->sysctl_tree), OID_AUTO,
            "int_mask", CTLFLAG_RD, &sc->int_mask, 0, "INT_MASK");
        SYSCTL_ADD_U32(&sc->sysctl_ctx, SYSCTL_CHILDREN(sc->sysctl_tree), OID_AUTO,
            "dma_status", CTLFLAG_RD, &sc->dma_status, 0, "DMA_STATUS stub bits");
        SYSCTL_ADD_U64(&sc->sysctl_ctx, SYSCTL_CHILDREN(sc->sysctl_tree), OID_AUTO,
            "dma_count", CTLFLAG_RD, &sc->dma_count, 0, "Number of stub DMA completions");
        SYSCTL_ADD_UQUAD(&sc->sysctl_ctx, SYSCTL_CHILDREN(sc->sysctl_tree), OID_AUTO,
            "irq_count", CTLFLAG_RD, &sc->irq_count, "IRQ count (stub)");
        SYSCTL_ADD_U64(&sc->sysctl_ctx, SYSCTL_CHILDREN(sc->sysctl_tree), OID_AUTO,
            "dma_irq_count", CTLFLAG_RD, &sc->dma_irq_count, 0, "DMA IRQ pulses (stub)");
        SYSCTL_ADD_U64(&sc->sysctl_ctx, SYSCTL_CHILDREN(sc->sysctl_tree), OID_AUTO,
            "test_irq_count", CTLFLAG_RD, &sc->test_irq_count, 0, "IRQ_TEST pulses (stub)");
    }
    /* Mirror BAR0/BAR1 map from docs/hydra_spec.md via HYDRA_IOCTL_INFO + RW32. */
    return (0);
}

static int
hydra_detach(device_t dev)
{
    struct hydra_softc *sc = device_get_softc(dev);
    if (sc->cdev)
        destroy_dev(sc->cdev);
    sysctl_ctx_free(&sc->sysctl_ctx);
    mtx_destroy(&sc->lock);
    if (sc->bar0)
        bus_release_resource(dev, SYS_RES_MEMORY, sc->bar0_rid, sc->bar0);
    if (sc->bar1)
        bus_release_resource(dev, SYS_RES_MEMORY, sc->bar1_rid, sc->bar1);
    device_printf(dev, "Hydra stub detached\n");
    return (0);
}

static device_method_t hydra_methods[] = {
    DEVMETHOD(device_probe,  hydra_probe),
    DEVMETHOD(device_attach, hydra_attach),
    DEVMETHOD(device_detach, hydra_detach),
    DEVMETHOD_END
};

static driver_t hydra_driver = {
    "hydra",
    hydra_methods,
    sizeof(struct hydra_softc),
};

static devclass_t hydra_devclass;

DRIVER_MODULE(hydra, pci, hydra_driver, hydra_devclass, NULL, NULL);
MODULE_DEPEND(hydra, pci, 1, 1, 1);
MODULE_VERSION(hydra, 1);
