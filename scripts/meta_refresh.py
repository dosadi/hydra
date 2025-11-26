#!/usr/bin/env python3
"""Run the meta refresh job: metadata generation plus summary export."""

from __future__ import annotations

import json
import subprocess
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
METADATA_SCRIPT = ROOT / "scripts" / "todo_metadata.py"
METADATA_OUTPUT = ROOT / "docs" / "todo" / "todo_tracker_metadata.json"
SUMMARY_OUTPUT = ROOT / "out" / "todo_tracker_metadata_summary.json"


def run_metadata() -> None:
    subprocess.run(
        ["python3", str(METADATA_SCRIPT), "--output", str(METADATA_OUTPUT)],
        check=True,
        cwd=ROOT,
    )


def write_summary() -> None:
    metadata = json.loads(METADATA_OUTPUT.read_text(encoding="utf-8"))
    aggregate = metadata.get("_aggregate", {})
    summary = {
        "generated": datetime.utcnow().isoformat() + "Z",
        "tracker_count": aggregate.get("tracker_count", 0),
        "todo_lines": aggregate.get("todo_lines", 0),
        "done_lines": aggregate.get("done_lines", 0),
        "priority_counts": aggregate.get("priority", {}),
        "source": str(METADATA_OUTPUT),
    }
    SUMMARY_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    SUMMARY_OUTPUT.write_text(json.dumps(summary, indent=2, sort_keys=True))
    print(f"[meta-refresh] summary written: {SUMMARY_OUTPUT}")


def main() -> None:
    print("[meta-refresh] regenerating tracker metadata")
    run_metadata()
    write_summary()
    print("[meta-refresh] meta data refresh complete")


if __name__ == "__main__":
    main()
