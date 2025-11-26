#!/usr/bin/env python3
"""Update the AI dashboard tracker with a live summary + follow-up guidance."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from collections import OrderedDict
from datetime import datetime
from pathlib import Path
from textwrap import shorten


def ensure_metadata(path: Path) -> dict:
    if not path.exists():
        generator = Path(__file__).resolve().parent / "todo_metadata.py"
        subprocess.run(["python3", str(generator), "--output", str(path)], check=True)
    return json.loads(path.read_text(encoding="utf-8"))


def summarize_metadata(metadata: dict) -> OrderedDict[str, int]:
    agg = metadata.get("_aggregate", {})
    priority = agg.get("priority", {})
    return OrderedDict(
        [
            ("trackers", agg.get("tracker_count", 0)),
            ("todo", agg.get("todo_lines", 0)),
            ("done", agg.get("done_lines", 0)),
            ("priority_tagged", sum(priority.get(p, 0) for p in ("P0", "P1", "P2", "P3"))),
            ("unknown", priority.get("unknown", 0)),
        ]
    )


def top_trackers(metadata: dict, key: str, top: int = 3) -> list[str]:
    entries = [
        (name, data)
        for name, data in metadata.items()
        if name != "_aggregate"
    ]
    if key == "todo":
        sorted_entries = sorted(entries, key=lambda item: item[1].get("todo_lines", 0), reverse=True)
        return [f"{name} ({data.get('todo_lines',0)} TODOs)" for name, data in sorted_entries[:top]]
    priority_key = key
    sorted_entries = sorted(
        entries,
        key=lambda item: item[1].get("priority", {}).get(priority_key, 0),
        reverse=True,
    )
    return [
        f"{name} ({data.get('priority', {}).get(priority_key, 0)} {priority_key})"
        for name, data in sorted_entries[:top]
    ]


def replace_section(
    text: str, header: str, next_header: str, body: str
) -> str:
    pattern = re.compile(
        rf"({re.escape(header)}\n)(.*?)(?=\n{re.escape(next_header)})",
        re.S,
    )
    replacement = f"{header}\n{body}\n"
    if pattern.search(text):
        return pattern.sub(replacement, text, count=1)
    # fallback: append header + body before next_header
    parts = text.split(f"\n{next_header}", 1)
    if len(parts) == 2:
        return f"{parts[0]}\n{replacement}\n{next_header}{parts[1]}"
    # no next header; append to end
    return f"{text.strip()}\n\n{header}\n{body}\n"


def append_followup(
    text: str, entry: str, follow_header: str
) -> str:
    if follow_header not in text:
        text = f"{text}\n\n{follow_header}\n"
    parts = text.split(f"\n{follow_header}", 1)
    prefix, rest = parts
    rest_parts = rest.split("\n## ", 1)
    follow_body = rest_parts[0].strip()
    remainder = f"\n## {rest_parts[1]}" if len(rest_parts) > 1 else ""
    if entry in follow_body:
        return text
    new_body = f"{follow_header}\n{entry}\n{follow_body}\n"
    return f"{prefix}\n{new_body}{remainder}".rstrip() + "\n"


def build_summary_lines(
    metadata: dict, top_unknowns: list[str], top_todos: list[str]
) -> str:
    stats = summarize_metadata(metadata)
    timestamp = datetime.utcnow().isoformat() + "Z"
    lines = [
        f"- Generated: {timestamp}",
        f"- Trackers: {stats['trackers']}",
        f"- TODO items: {stats['todo']}",
        f"- DONE items: {stats['done']}",
        f"- Priority-tagged items: {stats['priority_tagged']}",
        f"- Unknown-priority items: {stats['unknown']}",
        "- Top unknown-priority trackers:",
    ]
    lines += [f"  - {entry}" for entry in top_unknowns]
    lines.append("- Leading TODO-heavy trackers:")
    lines += [f"  - {entry}" for entry in top_todos]
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Update docs/todo/todo_ai_dashboard.md with a live briefing."
    )
    parser.add_argument(
        "--metadata",
        "-m",
        default="docs/todo/todo_tracker_metadata.json",
        help="Tracker metadata JSON path.",
    )
    parser.add_argument(
        "--doc",
        "-d",
        default="docs/todo/todo_ai_dashboard.md",
        help="Tracker doc to update.",
    )
    parser.add_argument(
        "--threshold",
        "-t",
        type=int,
        default=20,
        help="Unknown-priority threshold to trigger follow-up TODO entry.",
    )
    args = parser.parse_args()

    metadata = ensure_metadata(Path(args.metadata))
    top_unknowns = top_trackers(metadata, "unknown")
    top_todos = top_trackers(metadata, "todo")
    summary = build_summary_lines(metadata, top_unknowns, top_todos)

    doc_path = Path(args.doc)
    doc_text = doc_path.read_text(encoding="utf-8")

    doc_text = replace_section(
        doc_text,
        "## Live Briefing",
        "## Follow-up Actions",
        summary,
    )

    if top_unknowns:
        highest = int(top_unknowns[0].split("(")[1].split()[0])
        if highest >= args.threshold:
            entry = (
                f"- TODO [P2]: Investigate {top_unknowns[0]} now that it exceeds "
                f"{args.threshold} unknown entries (dashboard flagged it)."
            )
            doc_text = append_followup(doc_text, entry, "## Follow-up Actions")

    doc_path.write_text(doc_text, encoding="utf-8")
    print(f"Updated {doc_path} with live AI briefing.")


if __name__ == "__main__":
    main()
