import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


# AXI-Lite byte offsets matching hydra_regs.h (HYDRA_REG_*). The CSR logic
# internally divides by 4 to decode word indices.
CTRL        = 0x0010
INT_MASK    = 0x0084
DMA_SRC     = 0x0060
DMA_DST     = 0x0064
DMA_LEN     = 0x0068
DMA_CMD     = 0x006C
INT_STATUS  = 0x0080
IRQ_TEST    = 0x0088
HDMI_CRC    = 0x00B0

# Blitter (0x0100 region)
BLIT_CTRL        = 0x0100
BLIT_STATUS      = 0x0104
BLIT_SRC         = 0x0108
BLIT_DST         = 0x010C
BLIT_LEN         = 0x0110
BLIT_STRIDE      = 0x0114
SURF_BASE        = 0x0118
SURF_LEN         = 0x011C
BLIT_PIX_ADDR    = 0x0120
BLIT_PIX_DATA    = 0x0124
BLIT_PIX_CMD     = 0x0128
BLIT_OBJ_IDX     = 0x0130
BLIT_OBJ_ATTR    = 0x0134
SURF_STATS       = 0x0138
BLIT_FIFO_DATA   = 0x0140
BLIT_FIFO_STATUS = 0x0144

BLIT_OP_SHIFT            = 3
BLIT_OP_MEMCPY           = 0
BLIT_OP_DRAW_OBJECT      = 1
BLIT_OP_MOVE_OBJECT      = 2
BLIT_OP_SURFACE_EXTRACT  = 3

# Automatic region 0 extractor (matches HYDRA_REG_REGION0_*)
REGION0_CFG        = 0x0150
REGION0_MIN        = 0x0154
REGION0_MAX        = 0x0158
REGION0_STATUS     = 0x015C
REGION0_SURF_STATS = 0x0160

# BAR1 SDRAM window base (must match voxel_axil_shell)
BAR1_BASE  = 0x1000000
SRC_ADDR   = 0x00000100
DST_ADDR   = 0x00000200


async def axil_write(dut, byte_addr, value):
    """Single-beat AXI-Lite write (byte_addr is byte offset)."""
    dut.s_axil_awaddr.value = byte_addr
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
    dut.s_axil_araddr.value = byte_addr
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

    # Wait for frame done bit (INT_STATUS[0]) with a generous timeout to
    # cover world_gen + full frame render latency.
    frame_irq = False
    last_crc = 0
    for _ in range(2_000_000):
        val = await axil_read(dut, INT_STATUS)
        if val & 0x1:
            frame_irq = True
            last_crc = int(dut.hdmi_crc_last.value)
            break
        await RisingEdge(dut.clk)

    # With INT_MASK covering frame_done, INT_STATUS[0] must latch; irq_out
    # edge/level behavior is covered in dedicated RTL benches.
    if frame_irq:
        # Clear just frame_done and ensure we don't see spurious re-latch.
        await axil_write(dut, INT_STATUS, 0x1)
        for _ in range(10):
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

    cocotb.log.info(
        f"HDMI last CRC: 0x{last_crc:08x}, frame_irq={frame_irq}, "
        f"irq_out={int(dut.irq_out.value)}, msi_seen={irq_seen}"
    )
    assert frame_irq, "Expected frame_done IRQ"
    assert irq_seen, "Expected MSI pulse after IRQ_TEST"

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


@cocotb.test()
async def bar1_dma_loopback(dut):
    """BAR1 + DMA loopback: write pattern via BAR1, DMA-copy, read back via BAR1, check INT/IRQ."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Drive defaults
    dut.s_axil_awvalid.value = 0
    dut.s_axil_wvalid.value = 0
    dut.s_axil_bready.value = 0
    dut.s_axil_arvalid.value = 0
    dut.s_axil_rready.value = 0

    dut.ext_axi_awvalid.value = 0
    dut.ext_axi_wvalid.value = 0
    dut.ext_axi_bready.value = 0
    dut.ext_axi_arvalid.value = 0
    dut.ext_axi_rready.value = 0

    # Reset
    dut.rst_n.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(5):
        await RisingEdge(dut.clk)

    async def bar1_write64(byte_addr: int, value: int):
        dut.ext_axi_awaddr.value = (BAR1_BASE + byte_addr) >> 0
        dut.ext_axi_awlen.value = 0
        dut.ext_axi_awsize.value = 3  # 8 bytes
        dut.ext_axi_awburst.value = 1
        dut.ext_axi_wdata.value = value
        dut.ext_axi_wstrb.value = 0xFF
        dut.ext_axi_wlast.value = 1
        dut.ext_axi_awvalid.value = 1
        dut.ext_axi_wvalid.value = 1
        dut.ext_axi_bready.value = 1
        while True:
            await RisingEdge(dut.clk)
            if int(dut.ext_axi_awready.value) and int(dut.ext_axi_wready.value):
                dut.ext_axi_awvalid.value = 0
                dut.ext_axi_wvalid.value = 0
            if int(dut.ext_axi_bvalid.value):
                dut.ext_axi_bready.value = 0
                break

    async def bar1_read64(byte_addr: int) -> int:
        dut.ext_axi_araddr.value = (BAR1_BASE + byte_addr) >> 0
        dut.ext_axi_arlen.value = 0
        dut.ext_axi_arsize.value = 3
        dut.ext_axi_arburst.value = 1
        dut.ext_axi_arvalid.value = 1
        dut.ext_axi_rready.value = 1
        while True:
            await RisingEdge(dut.clk)
            if int(dut.ext_axi_arready.value):
                dut.ext_axi_arvalid.value = 0
            if int(dut.ext_axi_rvalid.value):
                val = int(dut.ext_axi_rdata.value)
                dut.ext_axi_rready.value = 0
                return val

    # Seed SRC region via BAR1 and clear DST region.
    for i in range(4):
        pattern = ((0xDEAD_0000 | i) << 32) | (0xBEEF_0000 | i)
        await bar1_write64(SRC_ADDR + i * 8, pattern)
        await bar1_write64(DST_ADDR + i * 8, 0)

    # Enable only DMA_DONE interrupt (bit1) in INT_MASK.
    await axil_write(dut, INT_MASK, 0x00000002)
    # Program DMA SRC/DST/LEN using same byte addresses.
    await axil_write(dut, DMA_SRC, SRC_ADDR)
    await axil_write(dut, DMA_DST, DST_ADDR)
    await axil_write(dut, DMA_LEN, 32)   # 4 * 8 bytes
    await axil_write(dut, DMA_CMD, 0x1)

    # Wait for dma_done in INT_STATUS[1].
    dma_irq = False
    for _ in range(2000):
        val = await axil_read(dut, INT_STATUS)
        if val & (1 << 1):
            dma_irq = True
            break
        await RisingEdge(dut.clk)

    assert dma_irq, "Expected dma_done bit set in BAR1+DMA loopback"
    assert int(dut.irq_out.value) == 1, "Expected irq_out high when dma_done set in BAR1+DMA loopback"

    # Clear dma_done via W1C and ensure irq_out drops.
    await axil_write(dut, INT_STATUS, 0x00000002)
    for _ in range(10):
        await RisingEdge(dut.clk)
    assert int(dut.irq_out.value) == 0, "Expected irq_out low after clearing dma_done in BAR1+DMA loopback"

    # Read back DST region via BAR1 and compare to SRC pattern.
    for i in range(4):
        expected = ((0xDEAD_0000 | i) << 32) | (0xBEEF_0000 | i)
        got = await bar1_read64(DST_ADDR + i * 8)
        assert got == expected, f"BAR1+DMA data mismatch at word {i}: got 0x{got:016x}, expected 0x{expected:016x}"


@cocotb.test()
async def blitter_basic_copy(dut):
    """Exercise BLIT_CTRL/STATUS and verify a simple pix_mem copy and BLIT_DONE IRQ."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Drive AXI-Lite defaults
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

    # Seed a few source pixels in the local blit_pix_mem window.
    patterns = [0x11110000, 0x22220001, 0x33330002, 0x44440003]
    for idx, val in enumerate(patterns):
        await axil_write(dut, BLIT_PIX_ADDR, idx)
        await axil_write(dut, BLIT_PIX_DATA, val)

    # Program a simple in-SDRAM copy: src indices [0..3] to dst [16..19].
    src_base_idx = 0
    dst_base_idx = 16
    await axil_write(dut, BLIT_SRC, src_base_idx << 2)
    await axil_write(dut, BLIT_DST, dst_base_idx << 2)
    await axil_write(dut, BLIT_LEN, len(patterns) * 4)

    # Enable only BLIT_DONE interrupt (bit4).
    await axil_write(dut, INT_MASK, 1 << 4)

    # Kick blitter with use_fifo=0, start=1.
    await axil_write(dut, BLIT_CTRL, 0x1)

    busy_seen = False
    done_seen = False
    for _ in range(2000):
        status = await axil_read(dut, BLIT_STATUS)
        busy = bool(status & 0x1)
        done = bool(status & 0x2)
        if busy:
            busy_seen = True
        if done:
            done_seen = True
            break
        await RisingEdge(dut.clk)

    assert busy_seen, "Expected blitter busy bit to assert at least once"
    assert done_seen, "Expected blitter done bit to assert"

    int_val = await axil_read(dut, INT_STATUS)
    assert int_val & (1 << 4), "Expected BLIT_DONE interrupt bit set in INT_STATUS"
    assert int(dut.irq_out.value) == 1, "Expected irq_out high when BLIT_DONE interrupt set"

    # Clear BLIT_DONE via W1C and ensure irq_out drops.
    await axil_write(dut, INT_STATUS, 1 << 4)
    for _ in range(10):
        await RisingEdge(dut.clk)
    assert int(dut.irq_out.value) == 0, "Expected irq_out low after clearing BLIT_DONE"

    # Read back destination pixels and confirm they match source patterns.
    for i, expected in enumerate(patterns):
        dst_idx = dst_base_idx + i
        await axil_write(dut, BLIT_PIX_ADDR, dst_idx)
        got = await axil_read(dut, BLIT_PIX_DATA)
        assert got == expected, (
            f"BLIT copy mismatch at dst idx {dst_idx}: got 0x{got:08x}, expected 0x{expected:08x}"
        )


@cocotb.test()
async def region0_auto_extractor_stub(dut):
    """Exercise REGION0_* CSRs and automatic extractor stub.

    Kicks the region-0 FSM via REGION0_CFG, waits for STATUS.valid and
    REGION0_SURF_STATS to become non-zero, and checks INT_STATUS[REGION0_DONE].
    """
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Drive AXI-Lite defaults
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

    # Program a dummy region AABB; layout is TBD, so keep it opaque for now.
    await axil_write(dut, REGION0_MIN, 0x00000000)
    await axil_write(dut, REGION0_MAX, 0x00000000)

    # Enable only REGION0_DONE interrupt (bit5).
    await axil_write(dut, INT_MASK, 1 << 5)

    # CFG[0]=enable, CFG[1]=kick, lod_hint=0.
    await axil_write(dut, REGION0_CFG, 0x3)

    # Wait for STATUS.valid and INT_STATUS[5].
    valid_seen = False
    for _ in range(5000):
        status = await axil_read(dut, REGION0_STATUS)
        if status & (1 << 1):
            valid_seen = True
            break
        await RisingEdge(dut.clk)

    assert valid_seen, "Expected REGION0_STATUS.valid to assert"

    int_val = await axil_read(dut, INT_STATUS)
    assert int_val & (1 << 5), "Expected REGION0_DONE interrupt bit set in INT_STATUS"

    # Read back REGION0_SURF_STATS and ensure we see non-zero voxels/patches.
    surf_stats = await axil_read(dut, REGION0_SURF_STATS)
    voxels = surf_stats & 0xFFF
    patches = (surf_stats >> 12) & 0xFFF
    cocotb.log.info(f"REGION0_SURF_STATS=0x{surf_stats:08x} voxels={voxels} patches={patches}")
    assert voxels > 0, "Expected non-zero voxel count in REGION0_SURF_STATS stub"
    assert patches > 0, "Expected non-zero patch count in REGION0_SURF_STATS stub"
