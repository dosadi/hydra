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
#include <sys/rman.h>
#include <sys/systm.h>
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
        info->irq_count = 0;
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
            if (sc->dma_status & HYDRA_INT_DMA_DONE)
                st |= HYDRA_STATUS_DMA_DONE;
            if (sc->dma_status & 0x2)
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
        sc->dma_status = HYDRA_INT_DMA_DONE;
        if (sc->int_mask & HYDRA_INT_DMA_DONE)
            sc->int_status |= HYDRA_INT_DMA_DONE;
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

static struct cdevsw hydra_cdevsw = {
    .d_version = D_VERSION,
    .d_name    = "hydra",
    .d_open    = hydra_open,
    .d_close   = hydra_close,
    .d_ioctl   = hydra_ioctl,
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

    sc->dev = dev;
    pci_enable_busmaster(dev);

    sc->bar0_rid = PCIR_BAR(0);
    sc->bar0 = bus_alloc_resource_any(dev, SYS_RES_MEMORY, &sc->bar0_rid, RF_ACTIVE);
    if (sc->bar0 == NULL) {
        device_printf(dev, "Failed to map BAR0\n");
        return (ENXIO);
    }
    sc->bar0_vaddr = rman_get_virtual(sc->bar0);
    sc->bar1_rid = PCIR_BAR(1);
    sc->bar1 = bus_alloc_resource_any(dev, SYS_RES_MEMORY, &sc->bar1_rid, RF_ACTIVE);
    if (sc->bar1)
        sc->bar1_vaddr = rman_get_virtual(sc->bar1);

    rid = rman_get_rid(sc->bar0);
    device_printf(dev, "Hydra stub attached: BAR0 mapped (rid=%d), BAR1 %s\n",
                  rid, sc->bar1 ? "mapped" : "absent");
    mtx_init(&sc->lock, "hydra", NULL, MTX_DEF);
    sc->cdev = make_dev(&hydra_cdevsw, 0, UID_ROOT, GID_WHEEL, 0600, "hydra");
    if (sc->cdev)
        sc->cdev->si_drv1 = sc;
    /* TODO: register cdev/ioctl hooks and mirror BAR0/1 map from docs/hydra_spec.md. */
    return (0);
}

static int
hydra_detach(device_t dev)
{
    struct hydra_softc *sc = device_get_softc(dev);
    if (sc->cdev)
        destroy_dev(sc->cdev);
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
