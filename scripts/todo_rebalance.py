#!/usr/bin/env python3
"""
Suggest TODO rebalance targets by identifying under-populated tracker files.

Usage:
    python scripts/todo_rebalance.py
"""

from __future__ import annotations

import textwrap
from collections import Counter
from pathlib import Path

def collect_counts(path: Path) -> Counter[str]:
    counts = Counter()
    data = path.read_text(errors="ignore")
    for line in data.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "TODO" not in line and "DONE" not in line:
            continue
        if line.count("TODO") > 0 or line.count("DONE") > 0:
            counts["total"] += 1
            if "TODO" in line and "[DONE" not in line:
                counts["todo"] += 1
            if "[P0" in line:
                counts["p0"] += 1
            elif "[P1" in line:
                counts["p1"] += 1
            elif "[P2" in line:
                counts["p2"] += 1
            elif "[P3" in line:
                counts["p3"] += 1
            else:
                counts["unprio"] += 1
    return counts


def main() -> None:
    tracker_files = sorted(Path("docs").glob("todo_*.md"))
    tracker_files += sorted(Path("docs").glob("TODO_*.md"))
    tracker_counts = {}
    total_todo = 0

    for path in tracker_files:
        if not path.is_file():
            continue
        stats = collect_counts(path)
        if stats["todo"] == 0:
            continue
        tracker_counts[path] = stats
        total_todo += stats["todo"]

    if not tracker_counts:
        print("No TODO trackers with TODO lines found.")
        return

    average = total_todo / len(tracker_counts)

    print("TODO rebalance report")
    print("=" * 40)
    print(f"Average TODOs per tracker: {average:.1f}")
    print()
    suggestions = []
    for path, stats in sorted(tracker_counts.items(), key=lambda item: item[0].name):
        todo = stats["todo"]
        ratio = todo / average if average else 0.0
        if ratio < 0.65:
            suggestions.append((path.name, todo, ratio))

    if not suggestions:
        print("All trackers meet the rebalance threshold (>=65% of average).")
        return

    print("Under-populated trackers (ratio < 0.65 of average):")
    for name, todo, ratio in suggestions:
        print(f"  - {name}: {todo} TODO lines ({ratio:.2f}x average)")
    print()
    print("Suggested actions:")
    print(textwrap.dedent("""\
        * Add one or two focus TODOs (P1/P2) to each listed file describing concrete steps
        * Reference neighboring trackers (e.g., cross-link site wiki updates from doc fixes)
        * Use these trackers as “micro-areas” for fast wins so big trackers stay manageable
    """))


if __name__ == "__main__":
    main()
