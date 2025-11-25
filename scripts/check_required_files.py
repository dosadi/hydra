#!/usr/bin/env python3
"""Sanity check: verify key repository files exist."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import List


REQUIRED_FILES: List[str] = [
    "README.md",
    "docs/todo_master.md",
    "sim/Makefile",
    "Makefile",
    "CMakeLists.txt",
    "sim/tests/golden_frame.ppm",
    "scripts/check_frame.py",
]


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    missing = []
    for rel in REQUIRED_FILES:
        path = root / rel
        if not path.exists():
            missing.append(rel)
    if missing:
        print("[files-check] Missing required files:")
        for m in missing:
            print(f"  - {m}")
        return 1
    print(f"[files-check] OK: all {len(REQUIRED_FILES)} required files present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
