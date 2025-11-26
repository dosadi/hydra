#!/usr/bin/env python3
"""Summarize meta tracker priorities for dashboards."""

from __future__ import annotations

import json
from pathlib import Path

METADATA_PATH = Path("docs/todo/todo_tracker_metadata.json")
OUTPUT_PATH = Path("out") / "meta_status.txt"


def summarize(metadata: dict) -> str:
    aggregate = metadata.get("_aggregate", {})
    lines = [
        f"Generated: {aggregate.get('generated', 'unknown')}",
        f"Trackers: {aggregate.get('tracker_count', 0)}",
        f"TODO lines: {aggregate.get('todo_lines', 0)}",
        "Priority counts:",
    ]
    prio = aggregate.get("priority", {})
    for level in ("P0", "P1", "P2", "P3", "unknown"):
        lines.append(f"  {level}: {prio.get(level, 0)}")
    top = sorted(
        (
            (
                name,
                stats.get("priority", {}).get("P0", 0),
            )
            for name, stats in metadata.items()
            if name != "_aggregate"
        ),
        key=lambda item: item[1],
        reverse=True,
    )[:5]
    lines.append("Top P0 trackers:")
    for name, count in top:
        lines.append(f"  {name}: {count}")
    return "\n".join(lines)


def main() -> None:
    metadata = json.loads(METADATA_PATH.read_text(encoding="utf-8"))
    report = summarize(metadata)
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(report + "\n")
    print(f"Meta status report written to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
