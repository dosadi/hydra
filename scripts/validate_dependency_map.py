#!/usr/bin/env python3
"""Validate tracker references listed in docs/todo/todo_dependency_map.md."""

from __future__ import annotations

import argparse
from pathlib import Path
import re

TRACKER_DIRS = [Path("docs/todo"), Path("docs"), Path("scripts"), Path(".")]


def parse_dependency_rows(path: Path) -> list[tuple[str, list[str]]]:
    rows = []
    in_table = False
    table_line = re.compile(r"^\|")
    with path.open(encoding="utf-8") as f:
        for line in f:
            if line.strip().startswith("| Dependent Tracker"):
                in_table = True
                continue
            if not in_table:
                continue
            if not table_line.match(line):
                break
            if line.strip().startswith("|---"):
                continue
            columns = [col.strip() for col in line.strip().split("|")[1:-1]]
            if len(columns) < 2:
                continue
            dependent = columns[0]
            depends = [
                dep.strip()
                for dep in columns[1].split(",")
                if dep.strip()
            ]
            rows.append((dependent, depends))
    return rows


def normalize_name(text: str) -> str:
    return text.strip().strip("`").strip()


def resolve_path(name: str) -> Path | None:
    name = normalize_name(name)
    if not name:
        return None
    if "*" in name or "?" in name:
        for base in TRACKER_DIRS:
            matches = list(base.glob(name))
            if matches:
                return matches[0]
        return None
    path = Path(name)
    if path.exists():
        return path
    if path.is_absolute():
        return path if path.exists() else None
    # try case-insensitive search for path name
    target = path.name
    for candidate in Path(".").rglob("*"):
        if candidate.name.lower() == target.lower():
            return candidate
    for base in TRACKER_DIRS:
        candidate = base / name
        if candidate.exists():
            return candidate
    return None


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Check that dependency map entries point to real trackers."
    )
    parser.add_argument(
        "--path",
        "-p",
        default="docs/todo/todo_dependency_map.md",
        help="Path to the dependency map document.",
    )
    parser.add_argument(
        "--fail-on-missing",
        action="store_true",
        help="Exit with 1 if missing tracker references are found.",
    )
    args = parser.parse_args()

    dep_path = Path(args.path)
    if not dep_path.exists():
        raise SystemExit(f"Dependency map not found at {dep_path}")

    rows = parse_dependency_rows(dep_path)
    missing = []
    for dependent, deps in rows:
        dep_path = resolve_path(dependent)
        if not dep_path:
            missing.append(f"Dependent tracker missing: {dependent}")
        for dep in deps:
            dep_path = resolve_path(dep)
            if not dep_path:
                missing.append(f"Depends-on missing: {dep} (referenced by {dependent})")

    if missing:
        print("Dependency map validation failed:")
        for item in missing:
            print(f" - {item}")
        if args.fail_on_missing:
            raise SystemExit(1)
    else:
        print("Dependency map validated successfully.")


if __name__ == "__main__":
    main()
