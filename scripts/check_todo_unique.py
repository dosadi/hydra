#!/usr/bin/env python3
"""Detect duplicate TODO entries in docs/todo_master.md."""

from __future__ import annotations

import re
import sys
from pathlib import Path

TODO_RE = re.compile(r"^- (TODO|DONE|IN-PROGRESS|WONTFIX-[^:]+):\s*(.*)")


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    todo_path = root / "docs" / "todo_master.md"
    if not todo_path.exists():
        print("[todo-unique] docs/todo_master.md not found", file=sys.stderr)
        return 1

    seen = {}
    duplicates = []
    for idx, line in enumerate(todo_path.read_text(encoding="utf-8").splitlines(), 1):
        m = TODO_RE.match(line.strip())
        if not m:
            continue
        key = m.group(2).strip()
        if key in seen:
            duplicates.append((key, seen[key], idx))
        else:
            seen[key] = idx

    if duplicates:
        print("[todo-unique] Duplicate TODO entries found:")
        for key, first, dup in duplicates:
            print(f"  - lines {first} and {dup}: {key}")
        return 1

    print("[todo-unique] OK: no duplicate TODO entries.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
