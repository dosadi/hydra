#!/usr/bin/env python3
"""Sanity check: verify key repository files exist."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import List, Set
import re


REQUIRED_FILES: List[str] = [
    "README.md",
    "docs/toodo/todo_master.md",
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
    todo_missing = check_todo_files(root)
    if missing:
        print("[files-check] Missing required files:")
        for m in missing:
            print(f"  - {m}")
        return 1
    if todo_missing:
        print("[files-check] Missing TODO docs referenced in TODO_MASTER_INDEX:")
        for m in todo_missing:
            print(f"  - {m}")
        return 1
    print(f"[files-check] OK: all {len(REQUIRED_FILES)} required files present.")
    return 0


def check_todo_files(root: Path) -> List[str]:
    index_path = root / "docs" / "TODO_MASTER_INDEX.md"
    if not index_path.exists():
        return []
    text = index_path.read_text()
    todo_names: Set[str] = set(re.findall(r"todo_[\\w_]+\\.md", text))
    missing = []
    for name in sorted(todo_names):
        candidate = root / "docs" / "toodo" / name
        if not candidate.exists():
            missing.append(str(candidate))
    return missing


if __name__ == "__main__":
    sys.exit(main())
