#!/usr/bin/env python3
"""LiteX shell around voxel_axi_core.

This is a flat, CPU-less wrapper that exposes the voxel engine as:
- AXI-Lite for control (e.g. PCIe BAR0 CSRs),
- AXI4 master for framebuffer writes to DRAM,
- AXI-Stream master for video output (e.g. HDMI/TMDS pipeline).

It is intended to be wired directly into LiteX/LitePCIe/LiteDRAM/LiteVideo
blocks on an FPGA board (Nexys Video, Arty, etc.) or ASIC shells, without
introducing a traditional SoC/CPU topology.
"""

from __future__ import annotations

from pathlib import Path
import sys

# ---------------------------------------------------------------------------
# In-tree LiteX imports
# ---------------------------------------------------------------------------

_REPO_ROOT = Path(__file__).resolve().parents[1]
_LITEX_ROOT = _REPO_ROOT / "third_party" / "litex"
if str(_LITEX_ROOT) not in sys.path:
    # Expect a "litex" Python package under third_party/litex/.
    sys.path.insert(0, str(_LITEX_ROOT))

from litex.gen import LiteXModule, Signal, ClockSignal, ResetSignal  # type: ignore
from litex.soc.interconnect.axi.axi_lite import AXILiteInterface  # type: ignore
from litex.soc.interconnect.axi.axi_full import AXIInterface  # type: ignore
from litex.soc.interconnect import stream  # type: ignore


class HydraCore(LiteXModule):
    """AXI-Lite + AXI4 + AXI-Stream wrapper around voxel_axi_core.

    This intentionally stays very flat: no CPU, no peripheral bus hierarchy.
    Callers are expected to hook AXI-Lite to a PCIe BAR bridge, AXI4 master
    to DRAM (for framebuffer writes), and AXI-Stream master to HDMI encoder.
    """

    def __init__(
        self,
        screen_width: int = 480,
        screen_height: int = 360,
        voxel_grid_size: int = 64,
        test_force_world_ready: int = 0,
        auto_start_frames: int = 1,
    ) -> None:
        super().__init__()

        # Upstream control path (e.g. PCIe BAR0) - AXI-Lite slave.
        self.csr_bus = AXILiteInterface(data_width=32, address_width=16)

        # Framebuffer write path - AXI4 master to DRAM.
        self.fb_master = AXIInterface(
            data_width=64,
            address_width=28,
            id_width=4,
            version="axi4",
        )

        # Video output - AXI-Stream master (RGB888 + SOF marker).
        self.video = stream.Endpoint([
            ("data", 24),
            ("user", 1),  # start-of-frame
        ])

        # Status/sideband useful for tests and drivers.
        self.irq = Signal()
        self.msi_pulse = Signal()
        self.frame_done = Signal()
        self.core_busy = Signal()

        # ------------------------------------------------------------------
        # RTL instance: voxel_axi_core
        # ------------------------------------------------------------------

        self.specials += Instance(
            "voxel_axi_core",
            # Parameters.
            p_SCREEN_WIDTH=screen_width,
            p_SCREEN_HEIGHT=screen_height,
            p_VOXEL_GRID_SIZE=voxel_grid_size,
            p_TEST_FORCE_WORLD_READY=test_force_world_ready,
            p_AUTO_START_FRAMES=auto_start_frames,

            # Clock / reset: share the LiteX "sys" domain.
            i_clk=ClockSignal("sys"),
            i_rst_n=~ResetSignal("sys"),

            # AXI-Lite CSR slave (BAR0-style window).
            i_s_axil_awaddr=self.csr_bus.aw.addr,
            i_s_axil_awvalid=self.csr_bus.aw.valid,
            o_s_axil_awready=self.csr_bus.aw.ready,
            i_s_axil_wdata=self.csr_bus.w.data,
            i_s_axil_wstrb=self.csr_bus.w.strb,
            i_s_axil_wvalid=self.csr_bus.w.valid,
            o_s_axil_wready=self.csr_bus.w.ready,
            o_s_axil_bresp=self.csr_bus.b.resp,
            o_s_axil_bvalid=self.csr_bus.b.valid,
            i_s_axil_bready=self.csr_bus.b.ready,
            i_s_axil_araddr=self.csr_bus.ar.addr,
            i_s_axil_arvalid=self.csr_bus.ar.valid,
            o_s_axil_arready=self.csr_bus.ar.ready,
            o_s_axil_rdata=self.csr_bus.r.data,
            o_s_axil_rresp=self.csr_bus.r.resp,
            o_s_axil_rvalid=self.csr_bus.r.valid,
            i_s_axil_rready=self.csr_bus.r.ready,

            # AXI4 framebuffer write master (to DRAM).
            o_m_axi_awid=self.fb_master.aw.id,
            o_m_axi_awaddr=self.fb_master.aw.addr,
            o_m_axi_awlen=self.fb_master.aw.len,
            o_m_axi_awsize=self.fb_master.aw.size,
            o_m_axi_awburst=self.fb_master.aw.burst,
            o_m_axi_awvalid=self.fb_master.aw.valid,
            i_m_axi_awready=self.fb_master.aw.ready,
            o_m_axi_wdata=self.fb_master.w.data,
            o_m_axi_wstrb=self.fb_master.w.strb,
            o_m_axi_wlast=self.fb_master.w.last,
            o_m_axi_wvalid=self.fb_master.w.valid,
            i_m_axi_wready=self.fb_master.w.ready,
            i_m_axi_bid=self.fb_master.b.id,
            i_m_axi_bresp=self.fb_master.b.resp,
            i_m_axi_bvalid=self.fb_master.b.valid,
            o_m_axi_bready=self.fb_master.b.ready,
            o_m_axi_arid=self.fb_master.ar.id,
            o_m_axi_araddr=self.fb_master.ar.addr,
            o_m_axi_arlen=self.fb_master.ar.len,
            o_m_axi_arsize=self.fb_master.ar.size,
            o_m_axi_arburst=self.fb_master.ar.burst,
            o_m_axi_arvalid=self.fb_master.ar.valid,
            i_m_axi_arready=self.fb_master.ar.ready,
            i_m_axi_rid=self.fb_master.r.id,
            i_m_axi_rdata=self.fb_master.r.data,
            i_m_axi_rresp=self.fb_master.r.resp,
            i_m_axi_rlast=self.fb_master.r.last,
            i_m_axi_rvalid=self.fb_master.r.valid,
            o_m_axi_rready=self.fb_master.r.ready,

            # AXI-Stream video master (to HDMI encoder).
            o_m_axis_tdata=self.video.data,
            o_m_axis_tvalid=self.video.valid,
            o_m_axis_tlast=self.video.last,
            o_m_axis_tuser=self.video.user,
            i_m_axis_tready=self.video.ready,

            # Interrupt and status outputs.
            o_irq_out=self.irq,
            o_msi_pulse=self.msi_pulse,
            o_frame_done=self.frame_done,
            o_core_busy=self.core_busy,
        )


__all__ = ["HydraCore"]
