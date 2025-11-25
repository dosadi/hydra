#!/usr/bin/env python3
"""Nexys Video FPGA wrapper for the voxel engine using LiteX-family IP.

This is *not* a traditional CPU SoC. It is a flat shell that:
- exposes Hydra's voxel engine through HydraCore (AXI-Lite + AXI4 + AXI-Stream),
- terminates control on PCIe BAR0 (AXI-Lite),
- maps bulk data moves over PCIe DMA into external DDR3,
- and drives HDMI using LiteICLink/LiteVideo TMDS cores.

The goal is a high-speed IO-centric ASIC-style dataplane, prototyped on Nexys Video.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

# ---------------------------------------------------------------------------
# In-tree LiteX + Hydra imports
# ---------------------------------------------------------------------------

ROOT_DIR = Path(__file__).resolve().parents[1]
LITEX_ROOT = ROOT_DIR / "third_party" / "litex"
if str(LITEX_ROOT) not in sys.path:
    # Expect a checkout of https://github.com/enjoy-digital/litex under third_party/litex
    sys.path.insert(0, str(LITEX_ROOT))

# LiteX / Migen bits (vendored under third_party/litex).
from litex.gen import ClockDomain, Instance  # type: ignore
from litex.soc.integration.builder import Builder  # type: ignore
from litex.soc.integration.soc import SoCRegion  # type: ignore
from litex.soc.integration.soc_core import SoCCore  # type: ignore
from litex.soc.interconnect.axi.axi_lite import AXILiteInterface  # type: ignore
from litex.soc.interconnect.axi.axi_full import AXIInterface, AXIInterconnectShared  # type: ignore

# Board/platform: expect litex-boards to be available on PYTHONPATH.
try:
    from litex_boards.targets.digilent_nexys_video import BaseSoC as NexysVideoBaseSoC  # type: ignore
except ImportError as e:  # pragma: no cover - depends on external package
    NexysVideoBaseSoC = None  # type: ignore

# Hydra voxel shell (same repo, in scripts/).
SCRIPTS_ROOT = ROOT_DIR / "scripts"
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))
from hydra_litex_shell import HydraCore  # type: ignore


# ---------------------------------------------------------------------------
# SoC wrapper (CPU-less dataplane with HydraCore)
# ---------------------------------------------------------------------------

class HydraNexysVideoSoC(SoCCore):
    """CPU-less LiteX design that centers the Hydra voxel engine.

    - No CPU, no CSR buses beyond what PCIe BAR0 exposes.
    - LitePCIe terminates PCIe, providing BAR0 AXI-Lite + DMA streams.
    - LiteDRAM provides DDR3; an AXI port is given directly to HydraCore.
    - LiteICLink/LiteVideo provides HDMI TMDS and timing, fed by Hydra's AXI-Stream.
    """

    def __init__(
        self,
        sys_clk_freq: float = 100e6,
        with_pcie: bool = True,
        with_hdmi: bool = True,
        **kwargs,
    ) -> None:
        if NexysVideoBaseSoC is None:
            raise RuntimeError(
                "litex-boards package with digilent_nexys_video target is required "
                "to build HydraNexysVideoSoC. Install litex-boards on PYTHONPATH."
            )

        # BaseSoC gives us the platform, clocks, DDR3 + (optionally) PCIe/HDMI support.
        NexysVideoBaseSoC.__init__(  # type: ignore[misc]
            self,
            sys_clk_freq=int(sys_clk_freq),
            with_pcie=with_pcie,
            with_led_chaser=False,
            **kwargs,
        )

        # Drop CPU: this is a dataplane shell only.
        self.add_cpu(None)

        # ------------------------------------------------------------------
        # Hydra voxel shell (AXI-Lite + AXI4 + AXI-Stream)
        # ------------------------------------------------------------------

        self.submodules.hydra = HydraCore()

        # Map BAR0 AXI-Lite onto Hydra's control interface.
        if with_pcie and hasattr(self, "pcie_endpoint"):
            # litepcie exposes an AXI-Lite slave/bridge; use that as BAR0→Hydra.
            bar0_axil: AXILiteInterface = self.pcie_endpoint.bar0  # type: ignore[attr-defined]
            self.comb += [
                bar0_axil.aw.connect(self.hydra.csr_bus.aw),
                bar0_axil.w.connect(self.hydra.csr_bus.w),
                self.hydra.csr_bus.b.connect(bar0_axil.b),
                bar0_axil.ar.connect(self.hydra.csr_bus.ar),
                self.hydra.csr_bus.r.connect(bar0_axil.r),
            ]

        # Connect Hydra's framebuffer AXI master into LiteDRAM via a simple shared AXI interconnect.
        # If LitePCIe DMA is present, share the DRAM port between Hydra and the host DMA.
        fb_masters = [self.hydra.fb_master]
        pcie_dma_master = getattr(getattr(self, "pcie_endpoint", None), "dma", None)
        if pcie_dma_master is not None and hasattr(pcie_dma_master, "master"):
            fb_masters.append(pcie_dma_master.master)  # type: ignore[attr-defined]

        fb_slave_port = None
        if hasattr(self, "sdram") and hasattr(self.sdram, "crossbar"):
            # LiteDRAM crossbar can hand out an AXI port; only connect if the type matches.
            candidate_port = getattr(self.sdram.crossbar, "get_port", lambda: None)()
            if isinstance(candidate_port, AXIInterface):
                fb_slave_port = candidate_port

        if fb_slave_port is not None:
            self.submodules.hydra_fb_ic = AXIInterconnectShared(
                masters=fb_masters,
                slaves=[(lambda _: 1, fb_slave_port)],  # single flat DRAM region
            )
        else:
            self.logger.info(
                "Hydra fb_master not connected to DRAM (AXI port unavailable); see docs/litex_crossbar_integration.md"
            )

        # HDMI/TMDS path: feed Hydra's AXI-Stream video into LiteVideo.
        if with_hdmi and hasattr(self, "video" ):
            # self.video is a LiteVideo core with a sink endpoint; connect streams.
            self.comb += [
                self.hydra.video.connect(self.video.source),  # type: ignore[attr-defined]
            ]


# ---------------------------------------------------------------------------
# CLI entrypoint
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Build Hydra Nexys Video bitstream")
    parser.add_argument("--build", action="store_true", help="Build the bitstream")
    parser.add_argument("--load", action="store_true", help="Load bitstream to board")
    parser.add_argument("--sys-clk-freq", type=float, default=100e6)
    args = parser.parse_args(argv)

    soc = HydraNexysVideoSoC(sys_clk_freq=args.sys_clk_freq)
    builder = Builder(soc, output_dir=str(ROOT_DIR / "build" / "nexys_video"))

    if args.build:
        builder.build(run=True)
    if args.load:
        prog = soc.platform.create_programmer()  # type: ignore[attr-defined]
        bitstream = builder.get_bitstream_filename(mode="sram")
        prog.load_bitstream(bitstream)

    return 0


if __name__ == "__main__":  # pragma: no cover - script entrypoint
    raise SystemExit(main())
