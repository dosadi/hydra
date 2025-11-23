#!/usr/bin/env python3
"""LiteX shell around voxel_axil_shell.

This is a flat, CPU-less wrapper that exposes the voxel engine as:
- AXI-Lite for control (e.g. PCIe BAR0 CSRs),
- AXI full for external memory (e.g. LiteDRAM), and
- AXI-Stream for video out (e.g. HDMI/TMDS pipeline).

It is intended to be wired directly into LiteX/LitePCIe/LiteDRAM/LiteICLink
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
_THIRD_PARTY_ROOT = _REPO_ROOT / "third_party"
if str(_THIRD_PARTY_ROOT) not in sys.path:
    # Expect a "litex" Python package under third_party/.
    sys.path.insert(0, str(_THIRD_PARTY_ROOT))

from litex.gen import LiteXModule, Signal, ClockSignal, ResetSignal  # type: ignore
from litex.soc.interconnect.axi.axi_lite import AXILiteInterface  # type: ignore
from litex.soc.interconnect.axi.axi_full import AXIInterface  # type: ignore
from litex.soc.interconnect import stream  # type: ignore


class HydraVoxelShell(LiteXModule):
    """AXI-Lite + AXI + AXI-Stream wrapper around voxel_axil_shell.

    This intentionally stays very flat: no CPU, no peripheral bus hierarchy.
    Callers are expected to hook AXI-Lite to a PCIe BAR bridge, AXI to DRAM,
    and the AXI-Stream sink to an HDMI/TMDS pipeline or test sink.
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

        # Upstream control path (e.g. PCIe BAR0).
        self.axil = AXILiteInterface(data_width=32, address_width=16)

        # External memory port (e.g. LiteDRAM AXI port).
        self.axi = AXIInterface(
            data_width=64,
            address_width=28,
            id_width=4,
            version="axi4",
        )

        # HDMI-like pixel stream (RGB888 + user for start-of-frame).
        self.hdmi = stream.Endpoint([
            ("data", 24),
            ("user", 1),  # mapped from s_axis_tuser (start-of-frame)
        ])

        # Status/sideband useful for tests and drivers.
        self.irq = Signal()
        self.msi_pulse = Signal()
        self.hdmi_beat_count = Signal(32)
        self.hdmi_frame_count = Signal(32)
        self.hdmi_crc_last = Signal(32)
        self.hdmi_line_count = Signal(16)
        self.hdmi_pixel_in_line = Signal(16)

        # ------------------------------------------------------------------
        # RTL instance: voxel_axil_shell
        # ------------------------------------------------------------------

        self.specials += Instance(
            "voxel_axil_shell",
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
            i_s_axil_awaddr=self.axil.aw.addr,
            i_s_axil_awvalid=self.axil.aw.valid,
            o_s_axil_awready=self.axil.aw.ready,
            i_s_axil_wdata=self.axil.w.data,
            i_s_axil_wstrb=self.axil.w.strb,
            i_s_axil_wvalid=self.axil.w.valid,
            o_s_axil_wready=self.axil.w.ready,
            o_s_axil_bresp=self.axil.b.resp,
            o_s_axil_bvalid=self.axil.b.valid,
            i_s_axil_bready=self.axil.b.ready,
            i_s_axil_araddr=self.axil.ar.addr,
            i_s_axil_arvalid=self.axil.ar.valid,
            o_s_axil_arready=self.axil.ar.ready,
            o_s_axil_rdata=self.axil.r.data,
            o_s_axil_rresp=self.axil.r.resp,
            o_s_axil_rvalid=self.axil.r.valid,
            i_s_axil_rready=self.axil.r.ready,

            # AXI memory port (to DRAM or a memory crossbar).
            i_ext_axi_awid=self.axi.aw.id,
            i_ext_axi_awaddr=self.axi.aw.addr,
            i_ext_axi_awlen=self.axi.aw.len,
            i_ext_axi_awsize=self.axi.aw.size,
            i_ext_axi_awburst=self.axi.aw.burst,
            i_ext_axi_awvalid=self.axi.aw.valid,
            o_ext_axi_awready=self.axi.aw.ready,
            i_ext_axi_wdata=self.axi.w.data,
            i_ext_axi_wstrb=self.axi.w.strb,
            i_ext_axi_wlast=self.axi.w.last,
            i_ext_axi_wvalid=self.axi.w.valid,
            o_ext_axi_wready=self.axi.w.ready,
            o_ext_axi_bid=self.axi.b.id,
            o_ext_axi_bresp=self.axi.b.resp,
            o_ext_axi_bvalid=self.axi.b.valid,
            i_ext_axi_bready=self.axi.b.ready,
            i_ext_axi_arid=self.axi.ar.id,
            i_ext_axi_araddr=self.axi.ar.addr,
            i_ext_axi_arlen=self.axi.ar.len,
            i_ext_axi_arsize=self.axi.ar.size,
            i_ext_axi_arburst=self.axi.ar.burst,
            i_ext_axi_arvalid=self.axi.ar.valid,
            o_ext_axi_arready=self.axi.ar.ready,
            o_ext_axi_rid=self.axi.r.id,
            o_ext_axi_rdata=self.axi.r.data,
            o_ext_axi_rresp=self.axi.r.resp,
            o_ext_axi_rlast=self.axi.r.last,
            o_ext_axi_rvalid=self.axi.r.valid,
            i_ext_axi_rready=self.axi.r.ready,

            # AXI-Stream video out (HDMI-like timing).
            o_s_axis_tdata=self.hdmi.data,
            o_s_axis_tvalid=self.hdmi.valid,
            o_s_axis_tlast=self.hdmi.last,
            o_s_axis_tuser=self.hdmi.user,
            i_s_axis_tready=self.hdmi.ready,

            # HDMI counters/CRC, used heavily in tests.
            o_hdmi_beat_count=self.hdmi_beat_count,
            o_hdmi_frame_count=self.hdmi_frame_count,
            o_hdmi_crc_last=self.hdmi_crc_last,
            o_hdmi_line_count=self.hdmi_line_count,
            o_hdmi_pixel_in_line=self.hdmi_pixel_in_line,

            # Interrupt outputs.
            o_irq_out=self.irq,
            o_msi_pulse=self.msi_pulse,
        )


class HydraBoardShell(HydraVoxelShell):
    """Thin alias for board-level wrappers.

    Board integration (Arty, Nexys Video, etc.) is expected to:
    - attach self.axil to a PCIe BAR AXI-Lite bridge or other host control,
    - attach self.axi to DRAM or SRAM fabric, and
    - consume self.hdmi via LiteVideo/LiteICLink HDMI/TMDS cores.

    Kept as a subclass for future expansion (board-specific clock/reset,
    multiple clock domains, test-only IO, etc.).
    """

    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)


__all__ = ["HydraVoxelShell", "HydraBoardShell"]
