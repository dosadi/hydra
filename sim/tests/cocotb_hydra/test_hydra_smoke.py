import cocotb
from cocotb.triggers import RisingEdge

@cocotb.test()
async def smoke_irq_and_crc(dut):
    """Minimal smoke: reset, wait a few frames, observe CRC and IRQ pulse."""
    dut.rst_n.value = 0
    for _ in range(5):
        dut.clk.value = 0
        await RisingEdge(dut.clk)
        dut.clk.value = 1
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1

    # Run for some cycles and capture MSI pulse/CRC
    irq_seen = False
    for _ in range(2000):
        dut.clk.value = 0
        await RisingEdge(dut.clk)
        dut.clk.value = 1
        await RisingEdge(dut.clk)
        if int(dut.msi_pulse.value) == 1:
            irq_seen = True
    crc = int(dut.hdmi_crc_last.value)
    cocotb.log.info(f"HDMI last CRC: 0x{crc:08x}, IRQ seen={irq_seen}")
    assert crc != 0, "CRC should accumulate over frames"
