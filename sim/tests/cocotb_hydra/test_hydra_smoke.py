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

    irq_seen = False
    last_crc = 0
    # Pulse IRQ test CSR mid-run
    for cycle in range(4000):
        dut.clk.value = 0
        await RisingEdge(dut.clk)
        dut.clk.value = 1
        await RisingEdge(dut.clk)
        if cycle == 500:
            dut.s_axil_awaddr.value = 0x88 >> 2
            dut.s_axil_awvalid.value = 1
            dut.s_axil_wdata.value = 1
            dut.s_axil_wstrb.value = 0xF
            dut.s_axil_wvalid.value = 1
        if int(dut.msi_pulse.value):
            irq_seen = True
        last_crc = int(dut.hdmi_crc_last.value)
    cocotb.log.info(f"HDMI last CRC: 0x{last_crc:08x}, IRQ seen={irq_seen}")
    assert last_crc != 0, "CRC should accumulate over frames"
    assert irq_seen, "Expected at least one MSI pulse"
