#!/usr/bin/env python3
"""Output structured metadata describing each TODO tracker."""

from __future__ import annotations

import json
import re
from argparse import ArgumentParser
from collections import Counter
from datetime import datetime
from pathlib import Path

PRIORITY_RE = re.compile(r"\[(P[0-3])\]")
TODO_RE = re.compile(r"\b(TODO|DONE)\b")


def scan_tracker(path: Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    counts: Counter[str] = Counter()
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
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
    counts["line_count"] = len(text.splitlines())
    return counts


def build_metadata(trackers: list[Path]) -> dict[str, dict]:
    metadata: dict[str, dict] = {}
    aggregate: Counter[str] = Counter()
    for path in sorted(trackers):
        stats = scan_tracker(path)
        aggregate.update(stats)
        metadata[path.name] = {
            "path": str(path),
            "todo_lines": stats.get("todo_lines", 0),
            "done_lines": stats.get("done_lines", 0),
            "priority": {
                prio: stats.get(f"prio_{prio}", 0) for prio in ("P0", "P1", "P2", "P3", "unknown")
            },
            "line_count": stats.get("line_count", 0),
            "last_updated": datetime.fromtimestamp(path.stat().st_mtime).isoformat(),
        }
    metadata["_aggregate"] = {
        "todo_lines": aggregate.get("todo_lines", 0),
        "done_lines": aggregate.get("done_lines", 0),
        "priority": {
            prio: aggregate.get(f"prio_{prio}", 0) for prio in ("P0", "P1", "P2", "P3", "unknown")
        },
        "tracker_count": len(trackers),
    }
    return metadata


def collect_trackers() -> list[Path]:
    tracker_dirs = [Path("docs"), Path("docs/todo")]
    trackers: list[Path] = []
    for base in tracker_dirs:
        trackers.extend(sorted(base.glob("todo_*.md")))
    # also include tracked TODO_*.md at docs root
    trackers.extend(sorted(Path("docs").glob("TODO*.md")))
    return sorted(set(trackers))


def main() -> None:
    parser = ArgumentParser(description="Generate TODO tracker metadata.")
    parser.add_argument(
        "--output",
        "-o",
        default="docs/todo/todo_tracker_metadata.json",
        help="Path to write metadata (default: %(default)s)",
    )
    parser.add_argument(
        "--print",
        action="store_true",
        help="Print the metadata to stdout in addition to writing it.",
    )
    args = parser.parse_args()

    trackers = collect_trackers()
    metadata = build_metadata(trackers)
    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(metadata, indent=2, sort_keys=True))
    if args.print:
        print(json.dumps(metadata, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
