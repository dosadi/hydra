#!/usr/bin/env python3
"""Quick environment probe for Hydra build-time tooling."""

from __future__ import annotations

import argparse
import importlib
import shutil
import subprocess
import sys
from collections import OrderedDict
from dataclasses import dataclass


@dataclass(frozen=True)
class Requirement:
    label: str
    # type: 'cmd', 'module', 'pkg-config'
    kind: str
    names: tuple[str, ...]
    hint: str


REQUIREMENTS: OrderedDict[str, list[Requirement]] = OrderedDict(
    [
        (
            "General host tooling",
            [
                Requirement(
                    label="C compiler (gcc or clang)",
                    kind="cmd",
                    names=("gcc", "clang"),
                    hint="Install build-essential (Linux) or Xcode command-line tools (macOS).",
                ),
                Requirement(
                    label="Make",
                    kind="cmd",
                    names=("make",),
                    hint="Install build-essential / Xcode command-line tools.",
                ),
                Requirement(
                    label="CMake (>=3.20)",
                    kind="cmd",
                    names=("cmake",),
                    hint="Install CMake or use the packaged `cmake`/`cmake3` binary.",
                ),
                Requirement(
                    label="Ninja (optional but recommended)",
                    kind="cmd",
                    names=("ninja",),
                    hint="Install Ninja (`ninja-build` on Debian/Ubuntu or `brew install ninja`).",
                ),
                Requirement(
                    label="Python 3",
                    kind="cmd",
                    names=("python3",),
                    hint="Install Python 3.x (`python` on Windows / `brew install python@3.12`).",
                ),
                Requirement(
                    label="pip3",
                    kind="cmd",
                    names=("pip3",),
                    hint="Install pip (`python3 -m ensurepip`).",
                ),
                Requirement(
                    label="Git",
                    kind="cmd",
                    names=("git",),
                    hint="Install git from your platform package manager.",
                ),
                Requirement(
                    label="pkg-config",
                    kind="cmd",
                    names=("pkg-config",),
                    hint="Install pkg-config so SDL2/Vulkan libs can be discovered.",
                ),
            ],
        ),
        (
            "Simulation (Verilator + SDL2)",
            [
                Requirement(
                    label="Verilator (5.x)",
                    kind="cmd",
                    names=("verilator",),
                    hint="Install Verilator 5.x (Linux: `sudo apt install verilator`).",
                ),
                Requirement(
                    label="SDL2 runtime (`sdl2-config`)",
                    kind="cmd",
                    names=("sdl2-config",),
                    hint="Install SDL2 dev package (Linux: `libsdl2-dev`).",
                ),
                Requirement(
                    label="SDL2_ttf via pkg-config",
                    kind="pkg-config",
                    names=("SDL2_ttf",),
                    hint="Install SDL2_ttf dev package (Linux: `libsdl2-ttf-dev`).",
                ),
            ],
        ),
        (
            "Test toolchain",
            [
                Requirement(
                    label="Icarus Verilog (`iverilog`)",
                    kind="cmd",
                    names=("iverilog",),
                    hint="Install `iverilog` for cocotb smoke tests.",
                ),
                Requirement(
                    label="GTKWave (optional)",
                    kind="cmd",
                    names=("gtkwave",),
                    hint="Install `gtkwave` or skip if you prefer other waveform viewers.",
                ),
            ],
        ),
        (
            "Driver tooling",
            [
                Requirement(
                    label="Linux kernel headers (build tree)",
                    kind="cmd",
                    names=("uname",),
                    hint="Install `linux-headers-$(uname -r)` and configure `KERNEL_DIR` if needed.",
                ),
                Requirement(
                    label="DKMS-aware build (optional)",
                    kind="cmd",
                    names=("dkms",),
                    hint="Install `dkms` to build drivers with automatic rebuilds.",
                ),
            ],
        ),
        (
            "Mix signal / FPGA tooling (best effort)",
            [
                Requirement(
                    label="LiteX Python stack",
                    kind="module",
                    names=("litex",),
                    hint="Install via `python3 -m pip install litex migen`.",
                ),
                Requirement(
                    label="Yosys",
                    kind="cmd",
                    names=("yosys",),
                    hint="Install `yosys` (Debian/Ubuntu package or custom build).",
                ),
                Requirement(
                    label="nextpnr",
                    kind="cmd",
                    names=("nextpnr", "nextpnr-xilinx"),
                    hint="Install `nextpnr` for FPGA synthesis flows.",
                ),
            ],
        ),
    ]
)


def check_cmd(names: tuple[str, ...]) -> bool:
    for name in names:
        if shutil.which(name):
            return True
    return False


def check_module(name: str) -> bool:
    try:
        importlib.import_module(name)
    except ImportError:
        return False
    return True


def check_pkg_config(names: tuple[str, ...]) -> bool:
    for pkg in names:
        if shutil.which("pkg-config") is None:
            return False
        result = subprocess.run(
            ["pkg-config", "--exists", pkg],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if result.returncode != 0:
            return False
    return True


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Verify Hydra build-time tooling and dependencies."
    )
    parser.add_argument(
        "--component",
        "-c",
        action="append",
        help="Check a specific component name (case-insensitive).",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List all available components.",
    )
    args = parser.parse_args()

    if args.list:
        print("Available components:")
        for comp in REQUIREMENTS:
            print(f"- {comp}")
        return

    selected_components = (
        [name for name in REQUIREMENTS if not args.component]
        if not args.component
        else [
            comp
            for comp in REQUIREMENTS
            if any(args_comp.lower() in comp.lower() for args_comp in args.component)
        ]
    )

    if not selected_components:
        print("No matching components selected.", file=sys.stderr)
        parser.print_help()
        raise SystemExit(1)

    missing = 0
    for comp in selected_components:
        requirements = REQUIREMENTS[comp]
        print(f"{comp}")
        for req in requirements:
            if req.kind == "cmd":
                ok = check_cmd(req.names)
            elif req.kind == "module":
                ok = any(check_module(name) for name in req.names)
            elif req.kind == "pkg-config":
                ok = check_pkg_config(req.names)
            else:
                ok = False
            symbol = "✅" if ok else "⚠️"
            print(f"  {symbol} {req.label}")
            if not ok:
                missing += 1
                print(f"    Hint: {req.hint}")
        print()
    if missing:
        print(f"Missing {missing} requirement(s).", file=sys.stderr)
        raise SystemExit(2)
    print("All checked requirements present.")


if __name__ == "__main__":
    main()
