#!/usr/bin/env python3
"""Check that source files contain a SPDX license header."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Iterable

LICENSE_TAG = "SPDX-License-Identifier: BSD-3-Clause"

SUFFIXES = {".c", ".cc", ".cpp", ".h", ".hpp", ".sv", ".svh", ".v"}
SKIP_DIRS = {"third_party", "build", "sim/obj_dir", "out", ".git"}


def iter_sources(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix not in SUFFIXES:
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        yield path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    missing = []
    for src in iter_sources(root):
        try:
            with open(src, "r", encoding="utf-8", errors="ignore") as f:
                head = f.read(512)
        except OSError:
            continue
        if LICENSE_TAG not in head:
            missing.append(src)

    if missing:
        print("[license-check] Missing SPDX header in:")
        for path in missing:
            print(f"  - {path}")
        return 1

    print("[license-check] OK: all files contain SPDX header.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
