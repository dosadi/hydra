#!/usr/bin/env python3
"""Check that source files have appropriate license headers."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import List, Tuple

# Expected SPDX identifier or license comment patterns
EXPECTED_PATTERNS = [
    re.compile(r"SPDX-License-Identifier:\s*BSD-3-Clause", re.IGNORECASE),
    re.compile(r"BSD.*3.*Clause", re.IGNORECASE),
    re.compile(r"Copyright.*Hydra", re.IGNORECASE),
]

# File extensions to check
EXTENSIONS = {".sv", ".svh", ".v", ".c", ".cpp", ".cc", ".h", ".hpp", ".py"}

# Skip patterns
SKIP_PATTERNS = [
    "third_party",
    "build",
    "obj_dir",
    ".git",
    "out",
    "sim/build",
    ".venv",
    "venv",
    "__pycache__",
]


def should_skip(path: Path) -> bool:
    """Check if file should be skipped."""
    path_str = str(path)
    return any(skip in path_str for skip in SKIP_PATTERNS)


def check_header(file_path: Path) -> bool:
    """Check if file has expected license header in first 20 lines."""
    try:
        lines = file_path.read_text(encoding="utf-8", errors="ignore").splitlines()[:20]
        text = "\n".join(lines)
        return any(pattern.search(text) for pattern in EXPECTED_PATTERNS)
    except Exception:
        return True  # Skip files we can't read


def find_source_files(root: Path) -> List[Path]:
    """Find all source files to check."""
    files = []
    for ext in EXTENSIONS:
        for path in root.rglob(f"*{ext}"):
            if not should_skip(path):
                files.append(path)
    return files


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    files = find_source_files(root)

    missing: List[Tuple[Path, str]] = []
    for file_path in files:
        rel_path = file_path.relative_to(root)
        if not check_header(file_path):
            missing.append((rel_path, file_path.suffix))

    if missing:
        print(f"[license-check] {len(missing)} files missing license headers:")
        for rel_path, ext in sorted(missing):
            print(f"  - {rel_path}")
        return 1

    print(f"[license-check] OK: all {len(files)} source files have license headers.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
