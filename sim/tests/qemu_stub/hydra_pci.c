     /* QEMU Hydra PCI stub device (conceptual).
      *
      * This device is intended to be dropped into a QEMU tree (e.g. hw/pci/) and
      * built as a simple PCIe endpoint exposing a BAR0 CSR window compatible with
      * drivers/linux/uapi/hydra_regs.h and hydra_ioctl.h.
      *
      * It is NOT wired into this repo's build; see sim/tests/qemu_stub/README.md
      * for integration notes.
      */
     
     #include "qemu/osdep.h"
     #include "hw/pci/pci.h"
     #include "hw/pci/msi.h"
     #include "hw/mem/memory.h"
     #include "hw/qdev-properties.h"
     #include "qapi/error.h"
     
     #define TYPE_HYDRA_PCI "hydra-pci"
     OBJECT_DECLARE_SIMPLE_TYPE(HydraPCIState, HYDRA_PCI)
     
     /* Match the values used by the Linux stub driver/UAPI. Adjust if you change
      * hydra_regs.h / hydra_ioctl.h.
      */
     #define HYDRA_VENDOR_ID 0x1BAD
     #define HYDRA_DEVICE_ID 0x2024
     
     #define HYDRA_BAR0_SIZE 0x10000 /* 64 KiB */
     
     typedef struct HydraPCIState {
         PCIDevice parent_obj;
     
         MemoryRegion bar0_mmio;
         uint32_t regs[HYDRA_BAR0_SIZE / 4];
     
         uint64_t irq_count;
     } HydraPCIState;
     
     /* Simple helpers for INT_STATUS/INT_MASK */
     static inline uint32_t hydra_reg_read(HydraPCIState *s, hwaddr addr)
     {
         if (addr >= HYDRA_BAR0_SIZE) {
             return 0xDEADBEEF;
         }
         return s->regs[addr >> 2];
     }
     
     static inline void hydra_raise_irq(HydraPCIState *s)
     {
         s->irq_count++;
         if (msi_enabled(PCI_DEVICE(s))) {
             msi_notify(PCI_DEVICE(s), 0);
         } else {
             pci_set_irq(PCI_DEVICE(s), 1);
             /* Level-triggered; caller must clear via INT_STATUS. */
         }
     }
     
     static void hydra_bar0_write(void *opaque, hwaddr addr, uint64_t val,
                                  unsigned size)
     {
         HydraPCIState *s = opaque;
         uint32_t off = addr & ~0x3u;
         uint32_t wval = (uint32_t)val;
     
         if (off >= HYDRA_BAR0_SIZE) {
             return;
         }
     
         /* Basic RW1C semantics for INT_STATUS: clear bits written as 1. */
         /* Keep offsets in sync with drivers/linux/uapi/hydra_regs.h. */
         enum {
             REG_INT_STATUS = 0x0080,
             REG_INT_MASK   = 0x0084,
             REG_IRQ_TEST   = 0x0088,
             REG_DMA_SRC    = 0x0060,
             REG_DMA_DST    = 0x0064,
             REG_DMA_LEN    = 0x0068,
             REG_DMA_CMD    = 0x006C,
             REG_BLIT_CTRL  = 0x0100,
             REG_STATUS     = 0x0014,
         };
     
         switch (off) {
         case REG_INT_STATUS: {
             uint32_t cur = s->regs[REG_INT_STATUS >> 2];
             cur &= ~wval; /* RW1C */
             s->regs[REG_INT_STATUS >> 2] = cur;
             if (!msi_enabled(PCI_DEVICE(s))) {
                 /* Drop INTx when no bits are set. */
                 if ((cur & s->regs[REG_INT_MASK >> 2]) == 0) {
                     pci_set_irq(PCI_DEVICE(s), 0);
                 }
             }
             break;
         }
         case REG_INT_MASK:
             s->regs[REG_INT_MASK >> 2] = wval;
             break;
         case REG_IRQ_TEST:
             /* Fire a synthetic IRQ_TEST pulse. */
             s->regs[REG_INT_STATUS >> 2] |= (1u << 3); /* HYDRA_INT_TEST */
             hydra_raise_irq(s);
             break;
         case REG_DMA_SRC:
         case REG_DMA_DST:
         case REG_DMA_LEN:
             s->regs[off >> 2] = wval;
             break;
         case REG_DMA_CMD:
             s->regs[REG_DMA_CMD >> 2] = wval;
             if (wval & 0x1) {
                 /* Immediate DMA completion stub: set DMA_STATUS.done and INT. */
                 uint32_t dma_status_off = 0x0070;
                 s->regs[dma_status_off >> 2] |= 0x1; /* done */
                 s->regs[REG_INT_STATUS >> 2] |= (1u << 1); /* HYDRA_INT_DMA_DONE */
                 hydra_raise_irq(s);
             }
             break;
         case REG_BLIT_CTRL:
             s->regs[REG_BLIT_CTRL >> 2] = wval;
             if (wval & 0x1) {
                 /* Blit stub: mark busy/done and raise BLIT_DONE interrupt. */
                 uint32_t blit_status_off = 0x0104;
                 s->regs[blit_status_off >> 2] |= 0x3; /* busy=1, done=1 */
                 s->regs[REG_INT_STATUS >> 2] |= (1u << 4); /* HYDRA_INT_BLIT_DONE */
                 hydra_raise_irq(s);
             }
             break;
         default:
             /* Default: plain register write. */
             s->regs[off >> 2] = wval;
             break;
         }
     }
     
     static uint64_t hydra_bar0_read(void *opaque, hwaddr addr, unsigned size)
     {
         HydraPCIState *s = opaque;
         return hydra_reg_read(s, addr & ~0x3u);
     }
     
     static const MemoryRegionOps hydra_bar0_ops = {
         .read = hydra_bar0_read,
         .write = hydra_bar0_write,
         .endianness = DEVICE_LITTLE_ENDIAN,
         .valid.min_access_size = 4,
         .valid.max_access_size = 4,
     };
     
     static void hydra_pci_realize(PCIDevice *pdev, Error **errp)
     {
         HydraPCIState *s = HYDRA_PCI(pdev);
     
         /* Program basic IDs. */
         pci_config_set_vendor_id(pdev->config, HYDRA_VENDOR_ID);
         pci_config_set_device_id(pdev->config, HYDRA_DEVICE_ID);
     
         memory_region_init_io(&s->bar0_mmio, OBJECT(s), &hydra_bar0_ops, s,
                               "hydra-bar0", HYDRA_BAR0_SIZE);
         pci_register_bar(pdev, 0, PCI_BASE_ADDRESS_SPACE_MEMORY, &s->bar0_mmio);
     
         /* Enable a single MSI vector if available; fall back to INTx. */
         if (msi_init(pdev, 1, 1, true, false, NULL) < 0) {
             /* INTx only, which pci_set_irq() already handles. */
         }
     }
     
     static void hydra_pci_reset(DeviceState *dev)
     {
         HydraPCIState *s = HYDRA_PCI(dev);
         memset(s->regs, 0, sizeof(s->regs));
         s->irq_count = 0;
     }
     
     static void hydra_pci_class_init(ObjectClass *klass, void *data)
     {
         DeviceClass *dc = DEVICE_CLASS(klass);
         PCIDeviceClass *k = PCI_DEVICE_CLASS(klass);
     
         k->realize = hydra_pci_realize;
         k->vendor_id = HYDRA_VENDOR_ID;
         k->device_id = HYDRA_DEVICE_ID;
         k->revision  = 0x00;
         k->class_id  = PCI_CLASS_DISPLAY_OTHER;
     
         dc->reset = hydra_pci_reset;
         dc->desc  = "Hydra PCI stub";
     }
     
     static const TypeInfo hydra_pci_info = {
         .name          = TYPE_HYDRA_PCI,
         .parent        = TYPE_PCI_DEVICE,
         .instance_size = sizeof(HydraPCIState),
         .class_init    = hydra_pci_class_init,
     };
     
     static void hydra_pci_register_types(void)
     {
         type_register_static(&hydra_pci_info);
     }
     
     type_init(hydra_pci_register_types)

