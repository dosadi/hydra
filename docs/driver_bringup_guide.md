# Driver Bring-Up Guide

This guide provides step-by-step instructions for bringing up the Hydra PCIe driver on FPGA hardware, including expected dmesg outputs, debugfs usage, and troubleshooting common issues.

## Prerequisites

- FPGA board with Hydra RTL synthesized and programmed
- Linux host with kernel headers installed
- Hydra driver sources built (`make driver-linux` from repo root)

## Step 1: Load the Driver

**Command:**
```bash
sudo insmod drivers/linux/hydra_pcie_drv.ko
```

**Expected dmesg output (successful probe):**
```
[  123.456789] hydra_pcie 0000:01:00.0: enabling device (0000 -> 0002)
[  123.456790] hydra_pcie 0000:01:00.0: BAR 0: assigned [mem 0xf0000000-0xf000ffff]
[  123.456791] hydra_pcie 0000:01:00.0: BAR 1: assigned [mem 0xf0010000-0xf001ffff]
[  123.456792] hydra_pcie 0000:01:00.0: enabling MSI interrupts
[  123.456793] hydra_pcie 0000:01:00.0: MSI interrupt enabled
[  123.456794] hydra_pcie 0000:01:00.0: Hydra PCIe device probed successfully
[  123.456795] hydra_pcie 0000:01:00.0: Registered misc device: /dev/hydra_pcie
[  123.456796] hydra_pcie 0000:01:00.0: Debugfs entry created: /sys/kernel/debug/hydra_pcie/0000:01:00.0
```

**Expected dmesg output (probe failure - no device):**
```
[  123.456789] hydra_pcie: No Hydra PCIe devices found
```

## Step 2: Verify Device Detection

**Check PCI device listing:**
```bash
lspci | grep -i hydra
# Expected output:
# 01:00.0 Unassigned class [ff00]: Unknown vendor/device ID
```

**Check device file creation:**
```bash
ls -la /dev/hydra_pcie
# Expected output:
# crw------- 1 root root 10, 123 Dec 15 10:30 /dev/hydra_pcie
```

**Check driver binding:**
```bash
ls -la /sys/bus/pci/drivers/hydra_pcie/
# Should show the bound device: 0000:01:00.0 -> ../../../../devices/pci0000:00/0000:00:01.0/0000:01:00.0
```

## Step 3: Basic Device Information

**Use the info tool:**
```bash
sudo ./scripts/hydra_drm_info /dev/hydra_pcie
```

**Expected output:**
```
Hydra PCIe Device Info:
Vendor ID: 0x1234
Device ID: 0x5678
IRQ: 42
BAR0: 0xf0000000 (size: 65536)
BAR1: 0xf0010000 (size: 65536)
IRQ count: 0
```

## Step 4: Test BAR Access

**Read BAR0 CSR (should be zero on reset):**
```bash
sudo ./scripts/hydra_drm_info /dev/hydra_pcie --read-csr 0x00
# Expected: 0x00000000 (or reset defaults from hydra_spec.md)
```

**Write and read back a test value:**
```bash
sudo ./scripts/hydra_drm_info /dev/hydra_pcie --write-csr 0x00 0xDEADBEEF
sudo ./scripts/hydra_drm_info /dev/hydra_pcie --read-csr 0x00
# Expected: 0xDEADBEEF
```

**Test BAR1 access:**
```bash
sudo ./scripts/hydra_bar1_hexdump /dev/hydra_pcie
# Expected: Hex dump of BAR1 contents (may be zeros initially)
```

## Step 5: Test Interrupts

**Trigger IRQ test:**
```bash
sudo ./scripts/hydra_irq_test /dev/hydra_pcie
```

**Expected output:**
```
Before IRQ test: INT_STATUS=0x00000000, INT_MASK=0x00000000
Triggering IRQ_TEST...
After IRQ test: INT_STATUS=0x00000010, INT_MASK=0x00000000
IRQ count: 1
```

**Expected dmesg output:**
```
[  123.456797] hydra_pcie 0000:01:00.0: IRQ_TEST triggered, INT_STATUS=0x00000010
```

## Step 6: Test DMA (Stub)

**Run DMA test:**
```bash
sudo ./scripts/hydra_dma_blit_demo /dev/hydra_pcie
```

**Expected output (stub implementation):**
```
DMA test: src=0x00000000, dst=0x00000040, len=0x00000040
DMA completed successfully
```

**Expected dmesg output:**
```
[  123.456798] hydra_pcie 0000:01:00.0: DMA completed: src=0x00000000, dst=0x00000040, len=0x00000040
```

## Step 7: Debugfs Debugging

**Check debugfs mount:**
```bash
mount | grep debugfs
# Expected: debugfs on /sys/kernel/debug type debugfs (rw,relatime)
```

**List debugfs entries:**
```bash
ls -la /sys/kernel/debug/hydra_pcie/
# Expected: 0000:01:00.0
```

**Read device registers:**
```bash
cat /sys/kernel/debug/hydra_pcie/0000:01:00.0/regs
# Expected: Hex dump of all BAR0 registers
```

**Read interrupt statistics:**
```bash
cat /sys/kernel/debug/hydra_pcie/0000:01:00.0/irq_stats
# Expected:
# Total IRQs: 1
# Last INT_STATUS: 0x00000010
# Last INT_MASK: 0x00000000
```

**Read DMA statistics:**
```bash
cat /sys/kernel/debug/hydra_pcie/0000:01:00.0/dma_stats
# Expected:
# Total DMA operations: 1
# Last DMA: src=0x00000000, dst=0x00000040, len=0x00000040
```

## Step 8: Camera/Blitter Testing

**Reset camera state:**
```bash
sudo ./scripts/hydra_cam_reset /dev/hydra_pcie
```

**Expected output:**
```
Camera reset: wrote 0x00000000 to camera registers
Flags reset: wrote 0x00000000 to flag registers
Selection reset: wrote 0x00000000 to selection registers
```

## Common Issues and Troubleshooting

### Issue: Device not detected by driver

**Symptoms:**
- No dmesg output from hydra_pcie
- `lspci` shows device but no `/dev/hydra_pcie`

**Checks:**
```bash
# Verify PCI IDs match
lspci -nn | grep -i hydra
# Should show: [1234:5678]

# Check if another driver claimed the device
lspci -k | grep -A 2 "01:00.0"

# Try manual binding
echo "0000:01:00.0" > /sys/bus/pci/drivers/hydra_pcie/bind
```

### Issue: BAR access fails

**Symptoms:**
- IOCTL returns EINVAL or EIO
- Register reads return unexpected values

**Checks:**
```bash
# Verify BAR mapping
cat /proc/iomem | grep f0000000
# Should show: f0000000-f000ffff : 0000:01:00.0

# Check for PCIe link issues
lspci -vvv -s 01:00.0 | grep -A 5 "LnkSta:"
```

### Issue: Interrupts not working

**Symptoms:**
- IRQ test doesn't increment counters
- No interrupt dmesg messages

**Checks:**
```bash
# Verify MSI setup
lspci -vvv -s 01:00.0 | grep -A 5 "MSI:"

# Check interrupt routing
cat /proc/interrupts | grep hydra_pcie

# Test with legacy interrupts (if MSI fails)
# Modify driver to use legacy IRQs and rebuild
```

### Issue: DMA failures

**Symptoms:**
- DMA operations time out
- Data corruption in transfers

**Checks:**
```bash
# Check DMA mask
lspci -vvv -s 01:00.0 | grep -A 2 "DMA:"

# Verify BAR1 mapping
cat /proc/iomem | grep f0010000

# Test with smaller transfers
sudo ./scripts/hydra_dma_blit_demo /dev/hydra_pcie --length 16
```

### Issue: FPGA not responding

**Symptoms:**
- All register reads return 0xFFFFFFFF or 0x00000000
- No interrupts, DMA doesn't complete

**Checks:**
```bash
# Verify FPGA is programmed
# Check FPGA DONE pin, power rails, clock signals

# Test PCIe link training
lspci -vvv -s 01:00.0 | grep -A 10 "Capabilities:"

# Try PCIe link reset
echo 1 > /sys/bus/pci/devices/0000:01:00.0/reset
```

## Debugfs Advanced Usage

**Monitor register changes in real-time:**
```bash
watch -n 0.1 cat /sys/kernel/debug/hydra_pcie/0000:01:00.0/regs
```

**Log all interrupts:**
```bash
while true; do
    cat /sys/kernel/debug/hydra_pcie/0000:01:00.0/irq_stats
    sleep 1
done
```

**Dump BAR1 memory region:**
```bash
dd if=/dev/hydra_pcie of=bar1_dump.bin bs=1 skip=$((0x10000)) count=256
hexdump -C bar1_dump.bin
```

## Performance Validation

**Interrupt latency test:**
```bash
time sudo ./scripts/hydra_irq_test /dev/hydra_pcie
# Should complete in < 1ms
```

**BAR access bandwidth:**
```bash
# Use dd to test BAR0 throughput
dd if=/dev/hydra_pcie of=/dev/null bs=4 count=1000
```

## Cleanup

**Unload driver:**
```bash
sudo rmmod hydra_pcie
```

**Expected dmesg output:**
```
[  123.456799] hydra_pcie 0000:01:00.0: Removing Hydra PCIe device
[  123.456800] hydra_pcie 0000:01:00.0: Debugfs entry removed
```

## Next Steps

After successful bring-up:
1. Test with actual FPGA RTL (not just stubs)
2. Enable real DMA engines in FPGA
3. Test with libhydra user-space library
4. Run full integration tests with sim_voxel

## Reference

- Device specification: `docs/hydra_spec.md`
- Register map: `docs/hydra_spec.md#register-map`
- Driver source: `drivers/linux/hydra_pcie_drv.c`
- Debug tools: `scripts/` directory</content>
<parameter name="filePath">/workspaces/hydra/docs/driver_bringup_guide.md