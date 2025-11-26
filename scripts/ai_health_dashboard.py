#!/usr/bin/env python3
"""Produce a simple AI health dashboard from the TODO metadata."""

from __future__ import annotations

import argparse
import json
from datetime import datetime
from pathlib import Path
import subprocess
import sys


def ensure_metadata(path: Path) -> None:
    if path.exists():
        return
    script_dir = Path(__file__).resolve().parent
    generator = script_dir / "todo_metadata.py"
    if not generator.exists():
        raise SystemExit(f"Metadata generator not found at {generator}")
    subprocess.run(
        [sys.executable, str(generator), "--output", str(path)],
        check=True,
    )


def summarize(metadata: dict, top_rank: int) -> list[str]:
    aggregate = metadata.get("_aggregate", {})
    total_todo = aggregate.get("todo_lines", 0)
    total_done = aggregate.get("done_lines", 0)
    unknown_total = aggregate.get("priority", {}).get("unknown", 0)
    prioritized = sum(
        aggregate.get("priority", {}).get(prio, 0) for prio in ("P0", "P1", "P2", "P3")
    )

    trackers = [
        (name, data)
        for name, data in metadata.items()
        if name != "_aggregate"
    ]
    sorted_unknown = sorted(
        trackers,
        key=lambda item: item[1].get("priority", {}).get("unknown", 0),
        reverse=True,
    )
    sorted_todo = sorted(
        trackers,
        key=lambda item: item[1].get("todo_lines", 0),
        reverse=True,
    )

    lines = [
        "# AI Health Dashboard",
        f"*Generated: {datetime.utcnow().isoformat()}Z*",
        "",
        "## Aggregate Snapshot",
        f"- Trackers: {aggregate.get('tracker_count', len(trackers))}",
        f"- TODO items: {total_todo}",
        f"- DONE items: {total_done}",
        f"- Priority-tagged items: {prioritized}",
        f"- Unknown-priority items: {unknown_total}",
        "",
        "## Top Unknown-priority Trackers",
    ]
    for name, data in sorted_unknown[:top_rank]:
        unknown = data.get("priority", {}).get("unknown", 0)
        todo = data.get("todo_lines", 0)
        lines.append(f"- {name} ({unknown} unknowns, {todo} TODOs)")

    lines.extend(
        [
            "",
            "## Highest TODO Counts",
        ]
    )
    for name, data in sorted_todo[:top_rank]:
        todo = data.get("todo_lines", 0)
        lines.append(f"- {name} ({todo} TODOs)")

    return lines


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Render an AI health dashboard from TODO metadata."
    )
    parser.add_argument(
        "--metadata",
        "-m",
        default="docs/todo/todo_tracker_metadata.json",
        help="Path to the metadata JSON file.",
    )
    parser.add_argument(
        "--output",
        "-o",
        default="out/ai_health_dashboard.txt",
        help="Path to write the dashboard text.",
    )
    parser.add_argument(
        "--top",
        "-t",
        type=int,
        default=5,
        help="How many top trackers to show.",
    )
    args = parser.parse_args()

    metadata_path = Path(args.metadata)
    ensure_metadata(metadata_path)
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    lines = summarize(metadata, args.top)

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(lines) + "\n")
    print(f"Wrote AI health dashboard to {output_path}")


if __name__ == "__main__":
    main()
