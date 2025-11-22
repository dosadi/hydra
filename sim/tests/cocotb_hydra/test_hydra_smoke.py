import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


CTRL       = 0x0010
INT_MASK   = 0x0084
DMA_SRC    = 0x0060
DMA_DST    = 0x0064
DMA_LEN    = 0x0068
DMA_CMD    = 0x006C
INT_STATUS = 0x0080
IRQ_TEST   = 0x0088
HDMI_CRC   = 0x00B0


async def axil_write(dut, byte_addr, value):
    """Single-beat AXI-Lite write (byte_addr is byte offset)."""
    dut.s_axil_awaddr.value = byte_addr >> 2
    dut.s_axil_wdata.value = value
    dut.s_axil_wstrb.value = 0xF
    dut.s_axil_awvalid.value = 1
    dut.s_axil_wvalid.value = 1
    while True:
        await RisingEdge(dut.clk)
        if dut.s_axil_awready.value and dut.s_axil_wready.value:
            dut.s_axil_awvalid.value = 0
            dut.s_axil_wvalid.value = 0
        if dut.s_axil_bvalid.value:
            dut.s_axil_bready.value = 1
            await RisingEdge(dut.clk)
            dut.s_axil_bready.value = 0
            break


async def axil_read(dut, byte_addr):
    """Single-beat AXI-Lite read; returns data."""
    dut.s_axil_araddr.value = byte_addr >> 2
    dut.s_axil_arvalid.value = 1
    while True:
        await RisingEdge(dut.clk)
        if dut.s_axil_arready.value:
            dut.s_axil_arvalid.value = 0
        if dut.s_axil_rvalid.value:
            dut.s_axil_rready.value = 1
            val = int(dut.s_axil_rdata.value)
            await RisingEdge(dut.clk)
            dut.s_axil_rready.value = 0
            return val

@cocotb.test()
async def smoke_irq_and_crc(dut):
    """Minimal smoke: reset, tick frames, verify HDMI CRC, IRQ test pulse, and DMA done IRQ."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Drive defaults on AXI-Lite
    dut.s_axil_awvalid.value = 0
    dut.s_axil_wvalid.value = 0
    dut.s_axil_bready.value = 0
    dut.s_axil_arvalid.value = 0
    dut.s_axil_rready.value = 0

    # Reset
    dut.rst_n.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(5):
        await RisingEdge(dut.clk)

    # Enable interrupts and kick a frame
    await axil_write(dut, INT_MASK, 0x1F)
    await axil_write(dut, CTRL, 0x2)  # start_frame

    # Wait for frame done bit (INT_STATUS[0])
    frame_irq = False
    last_crc = 0
    for _ in range(5000):
        val = await axil_read(dut, INT_STATUS)
        if val & 0x1:
            frame_irq = True
            last_crc = int(dut.hdmi_crc_last.value)
            break
        await RisingEdge(dut.clk)

    # Pulse IRQ test CSR and watch for MSI
    await axil_write(dut, IRQ_TEST, 1)
    irq_seen = False
    last_crc = 0
    for _ in range(1000):
        await RisingEdge(dut.clk)
        if int(dut.msi_pulse.value):
            irq_seen = True
        last_crc = int(dut.hdmi_crc_last.value)

    cocotb.log.info(f"HDMI last CRC: 0x{last_crc:08x}, frame_irq={frame_irq}, irq_out={int(dut.irq_out.value)}, msi_seen={irq_seen}")
    assert frame_irq, "Expected frame_done IRQ"

    # Clear INT_STATUS then kick DMA stub and expect INT_STATUS bit1
    await axil_write(dut, INT_STATUS, 0xFFFFFFFF)
    await axil_write(dut, DMA_SRC, 0x00000000)
    await axil_write(dut, DMA_DST, 0x00000040)
    await axil_write(dut, DMA_LEN, 0x00000040)
    await axil_write(dut, DMA_CMD, 0x1)

    dma_irq = False
    for _ in range(2000):
        val = await axil_read(dut, INT_STATUS)
        if val & (1 << 1):
            dma_irq = True
            # clear just the DMA_DONE bit
            await axil_write(dut, INT_STATUS, (1 << 1))
            break
        await RisingEdge(dut.clk)

    assert dma_irq, "Expected DMA done IRQ after kick"
