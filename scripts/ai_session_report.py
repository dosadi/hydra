#!/usr/bin/env python3
"""Generate an AI session report and append it to the agent bridge."""

from __future__ import annotations

import argparse
import json
import subprocess
from datetime import datetime
from pathlib import Path
from textwrap import shorten


def run_command(cmd: list[str]) -> tuple[int, list[str]]:
    result = subprocess.run(cmd, capture_output=True, text=True)
    lines = (result.stdout + result.stderr).splitlines()
    return result.returncode, lines


def run_probe(cmd: list[str]) -> tuple[str, int]:
    code, output = run_command(cmd)
    snippet = shorten("\n".join(output), width=160, placeholder="…")
    return snippet, code


def ensure_metadata(path: Path) -> dict:
    generator = Path(__file__).resolve().parent / "todo_metadata.py"
    if not path.exists():
        subprocess.run(["python3", str(generator), "--output", str(path)], check=True)
    return json.loads(path.read_text(encoding="utf-8"))


def summarize_priority(metadata: dict, field: str, top: int = 3) -> list[str]:
    trackers = [
        (name, data)
        for name, data in metadata.items()
        if name != "_aggregate"
    ]
    if field == "todo_lines":
        key = lambda item: item[1].get("todo_lines", 0)
    else:
        key = lambda item: item[1].get("priority", {}).get(field, 0)
    sorted_trackers = sorted(trackers, key=key, reverse=True)
    results: list[str] = []
    for name, data in sorted_trackers[:top]:
        if field == "todo_lines":
            results.append(f"{name} ({data.get('todo_lines', 0)} TODOs)")
        else:
            results.append(
                f"{name} ({data.get('priority', {}).get(field, 0)} {field} entries)"
            )
    return results


def append_bridge_entry(doc_path: Path, entry: str) -> None:
    doc_path.parent.mkdir(parents=True, exist_ok=True)
    with doc_path.open("a", encoding="utf-8") as f:
        f.write("\n\n" + entry.rstrip() + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run AI session probes and write a report."
    )
    parser.add_argument(
        "--output",
        "-o",
        default="out/ai_session_report.txt",
        help="Path to write the report (default: %(default)s).",
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    bridge_doc = root / "docs" / "agent_integration_bridge.md"
    report_path = root / args.output
    report_path.parent.mkdir(parents=True, exist_ok=True)

    general_snip, general_code = run_probe([
        "python3",
        str(root / "scripts" / "check_build_requirements.py"),
        "--component",
        "General host tooling",
    ])
    sim_snip, sim_code = run_probe([
        "python3",
        str(root / "scripts" / "check_build_requirements.py"),
        "--component",
        "Simulation",
    ])

    metadata = ensure_metadata(root / "docs" / "todo" / "todo_tracker_metadata.json")
    unknowns = summarize_priority(metadata, "unknown", top=3)
    todo_heavy = summarize_priority(metadata, "todo_lines", top=3)

    git_status_code, git_status = run_command(["git", "status", "-sb"])
    git_head_code, git_head = run_command(["git", "rev-parse", "HEAD"])

    timestamp = datetime.utcnow().isoformat() + "Z"
    lines = [
        f"### AI Session Report - {timestamp}",
        f"- Git HEAD: {git_head[0] if git_head else 'unknown'} (status {git_head_code})",
        f"- Git status exit {git_status_code}: {shorten(' '.join(git_status), width=120, placeholder='…')}",
        f"- Requirement (General host tooling): exit {general_code}; {general_snip or '(no output)'}",
        f"- Requirement (Simulation): exit {sim_code}; {sim_snip or '(no output)'}",
        f"- Top unknown-priority trackers: {', '.join(unknowns)}",
        f"- Top TODO-loaded trackers: {', '.join(todo_heavy)}",
    ]

    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    append_bridge_entry(bridge_doc, "\n".join(lines))
    print(f"Wrote AI session report to {report_path}")


if __name__ == "__main__":
    main()
