#!/usr/bin/env python3
"""
Brief utility to inspect docs/todo/todo_*.md trackers and summarize TODO counts.

Usage:
  python scripts/todo_sweep.py
Outputs a per-file table of TODO/DONE counts and aggregates across priorities.
"""

from __future__ import annotations

import re
import textwrap
from collections import Counter, defaultdict
from pathlib import Path

PRIORITY_RE = re.compile(r"\[(P[0-3])\]")
TODO_RE = re.compile(r"\b(TODO|DONE)\b")


def scan_file(path: Path) -> Counter[str]:
    counts: Counter[str] = Counter()
    text = path.read_text(encoding="utf-8", errors="ignore")
    for line in text.splitlines():
        if not line.strip():
            continue
        todo_match = TODO_RE.search(line)
        if not todo_match:
            continue
        kind = todo_match.group(1)
        if kind == "TODO":
            counts["todo_lines"] += 1
            if "[DONE" in line:
                counts["todo_as_done"] += 1
            priority = PRIORITY_RE.search(line)
            if priority:
                counts[f"prio_{priority.group(1)}"] += 1
            else:
                counts["prio_unknown"] += 1
        else:
            counts["done_lines"] += 1
    return counts


def main() -> None:
    docs = sorted(Path("docs").glob("TODO*.md")) \
        + sorted(Path("docs").glob("todo_*.md")) \
        + sorted(Path("docs/todo").glob("todo_*.md"))
    overall: Counter[str] = Counter()
    per_file = {}

    for doc in docs:
        if not doc.is_file():
            continue
        stats = scan_file(doc)
        if not stats:
            continue
        per_file[doc] = stats
        overall.update(stats)

    if not per_file:
        print("No TODO trackers found.")
        return

    print("Doc TODO sweep")
    print("=" * 40)
    header = ("File", "TODO", "DONE", "P0", "P1", "P2", "P3", "Unknown")
    print("{:<40} {:>5} {:>5} {:>4} {:>4} {:>4} {:>4} {:>7}".format(*header))
    print("-" * 80)
    for doc, stats in sorted(per_file.items(), key=lambda item: item[0].name):
        todo_count = stats["todo_lines"]
        done_count = stats["done_lines"]
        row = (
            doc.name,
            todo_count,
            done_count,
            stats["prio_P0"],
            stats["prio_P1"],
            stats["prio_P2"],
            stats["prio_P3"],
            stats["prio_unknown"],
        )
        print("{:<40} {:>5} {:>5} {:>4} {:>4} {:>4} {:>4} {:>7}".format(*row))

    print("\nAggregate totals:")
    print(f"  TODO lines : {overall['todo_lines']}")
    print(f"  DONE lines : {overall['done_lines']}")
    for prio in ("P0", "P1", "P2", "P3", "unknown"):
        print(f"  {prio} : {overall[f'prio_{prio}']}")


if __name__ == "__main__":
    main()
