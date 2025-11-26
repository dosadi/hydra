#!/usr/bin/env python3
"""
Documentation Touch System - Makefile-style dependency tracking for docs.

This tool implements a pervasive "touch" system where documentation files can
declare dependencies on other docs, and changes propagate through the dependency
tree to flag files that need reconsideration/updating.

Similar to how Makefiles track source->object dependencies, this tracks:
- Spec docs -> Implementation guides
- TODO trackers -> Related trackers
- Foundation docs -> Derived docs

Usage:
  # Check which docs are out of date
  python scripts/doc_touch.py --check

  # Mark a doc as "touched" (updated), propagate staleness
  python scripts/doc_touch.py --touch docs/hydra_spec.md

  # Show dependency tree
  python scripts/doc_touch.py --tree

  # Show what needs updating
  python scripts/doc_touch.py --needs-update

  # Auto-rebuild metadata
  python scripts/doc_touch.py --rebuild-metadata
"""

from __future__ import annotations

import json
import re
import sys
from argparse import ArgumentParser
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any

# Pattern to extract dependencies from doc headers
# Matches: **Depends:** `file1.md`, `file2.md`
# Matches: **Related Trackers:** `file1.md`, `file2.md`
# Matches: **Touches:** `file1.md` (explicit touch declaration)
DEPENDS_RE = re.compile(r"\*\*(Depends|Related Trackers|Touches):\*\*\s*(.+)", re.IGNORECASE)
FILE_REF_RE = re.compile(r"`([^`]+\.md)`")

# Pattern to extract last-updated timestamps
LAST_UPDATED_RE = re.compile(r"\*\*Last Updated:\*\*\s*(\d{4}-\d{2}-\d{2})")


@dataclass
class DocNode:
    """Represents a documentation file in the dependency graph."""
    path: Path
    mtime: float
    last_updated: str | None = None  # From **Last Updated:** header
    depends_on: list[str] = field(default_factory=list)  # Files this depends on
    touched_by: list[str] = field(default_factory=list)  # Files that touch this
    needs_update: bool = False
    reason: str = ""

    @property
    def is_stale(self) -> bool:
        """Check if this doc is stale (dependencies newer than it)."""
        return self.needs_update


class DocGraph:
    """Dependency graph for documentation files."""

    def __init__(self, root: Path):
        self.root = root
        self.nodes: dict[str, DocNode] = {}
        self.reverse_deps: dict[str, list[str]] = defaultdict(list)

    def scan_doc(self, path: Path) -> DocNode:
        """Scan a doc file and extract dependencies."""
        rel_path = str(path.relative_to(self.root))
        if rel_path in self.nodes:
            return self.nodes[rel_path]

        stat = path.stat()
        node = DocNode(
            path=path,
            mtime=stat.st_mtime,
        )

        try:
            content = path.read_text(encoding="utf-8", errors="ignore")
            # Extract last-updated timestamp
            last_updated_match = LAST_UPDATED_RE.search(content)
            if last_updated_match:
                node.last_updated = last_updated_match.group(1)

            # Extract dependencies from header section (first 50 lines)
            header_lines = content.splitlines()[:50]
            for line in header_lines:
                depends_match = DEPENDS_RE.search(line)
                if not depends_match:
                    continue

                dep_type = depends_match.group(1)
                dep_text = depends_match.group(2)

                # Extract all file references from the line
                for file_match in FILE_REF_RE.finditer(dep_text):
                    dep_file = file_match.group(1)
                    # Resolve relative to this doc's directory
                    dep_path = self._resolve_dep_path(path, dep_file)
                    if dep_path:
                        if dep_type.lower() in ("touches", "related trackers"):
                            node.touched_by.append(str(dep_path.relative_to(self.root)))
                        else:
                            node.depends_on.append(str(dep_path.relative_to(self.root)))

        except Exception as e:
            print(f"Warning: Failed to scan {path}: {e}", file=sys.stderr)

        self.nodes[rel_path] = node
        return node

    def _resolve_dep_path(self, doc_path: Path, dep_ref: str) -> Path | None:
        """Resolve a dependency reference to an absolute path."""
        # Try relative to doc directory
        candidates = [
            doc_path.parent / dep_ref,
            self.root / "docs" / dep_ref,
            self.root / "docs" / "todo" / dep_ref,
            self.root / dep_ref,
        ]
        for candidate in candidates:
            if candidate.exists():
                return candidate
        return None

    def build_graph(self, doc_paths: list[Path]) -> None:
        """Build the full dependency graph."""
        # First pass: scan all docs
        for path in doc_paths:
            self.scan_doc(path)

        # Second pass: build reverse dependencies
        for rel_path, node in self.nodes.items():
            for dep in node.depends_on:
                self.reverse_deps[dep].append(rel_path)
            for touched in node.touched_by:
                self.reverse_deps[touched].append(rel_path)

    def mark_stale(self, touched_file: str) -> list[str]:
        """
        Mark all docs that depend on touched_file as needing updates.
        Returns list of affected docs.
        """
        affected = []
        to_process = [touched_file]
        visited = set()

        while to_process:
            current = to_process.pop(0)
            if current in visited:
                continue
            visited.add(current)

            # Mark all reverse dependencies as stale
            for dependent in self.reverse_deps.get(current, []):
                if dependent not in self.nodes:
                    continue
                dep_node = self.nodes[dependent]
                if not dep_node.needs_update:
                    dep_node.needs_update = True
                    dep_node.reason = f"Depends on {current} which was updated"
                    affected.append(dependent)
                    to_process.append(dependent)

        return affected

    def check_staleness(self) -> dict[str, list[str]]:
        """
        Check all docs for staleness based on mtime comparisons.
        Returns dict of {doc: [reasons]} for stale docs.
        """
        stale: dict[str, list[str]] = defaultdict(list)

        for rel_path, node in self.nodes.items():
            # Check if any dependencies are newer
            for dep in node.depends_on:
                if dep not in self.nodes:
                    stale[rel_path].append(f"Missing dependency: {dep}")
                    continue

                dep_node = self.nodes[dep]
                if dep_node.mtime > node.mtime:
                    time_diff = int((dep_node.mtime - node.mtime) / 60)
                    stale[rel_path].append(
                        f"{dep} updated {time_diff}min after this doc"
                    )

            # Check if any "touching" docs are newer
            for touched in node.touched_by:
                if touched not in self.nodes:
                    continue
                touched_node = self.nodes[touched]
                if touched_node.mtime > node.mtime:
                    time_diff = int((touched_node.mtime - node.mtime) / 60)
                    stale[rel_path].append(
                        f"{touched} touched {time_diff}min after this doc"
                    )

        return stale

    def get_tree(self, root_file: str | None = None) -> str:
        """Generate a tree view of dependencies."""
        lines = []

        if root_file:
            if root_file not in self.nodes:
                return f"File not found: {root_file}"
            self._print_tree(root_file, lines, set(), 0)
        else:
            # Find root nodes (no dependencies)
            roots = [
                path for path, node in self.nodes.items()
                if not node.depends_on and not node.touched_by
            ]
            for root in sorted(roots):
                self._print_tree(root, lines, set(), 0)

        return "\n".join(lines)

    def _print_tree(self, path: str, lines: list[str], visited: set[str], depth: int) -> None:
        """Recursively print dependency tree."""
        indent = "  " * depth
        marker = "└─ " if depth > 0 else ""

        node = self.nodes.get(path)
        if not node:
            lines.append(f"{indent}{marker}{path} [MISSING]")
            return

        status = ""
        if node.needs_update:
            status = " [NEEDS UPDATE]"
        elif node.is_stale:
            status = " [STALE]"

        lines.append(f"{indent}{marker}{path}{status}")

        if path in visited:
            lines.append(f"{indent}  (circular dependency)")
            return
        visited.add(path)

        # Show what this depends on
        for dep in sorted(node.depends_on):
            self._print_tree(dep, lines, visited.copy(), depth + 1)

        # Show reverse deps if at depth 0
        if depth == 0 and path in self.reverse_deps:
            for rdep in sorted(self.reverse_deps[path]):
                lines.append(f"  ⬆ {rdep} depends on this")


def collect_docs(root: Path) -> list[Path]:
    """Collect all markdown docs to analyze."""
    docs = []
    for pattern in [
        "docs/*.md",
        "docs/todo/*.md",
        "docs/rfc/*.md",
        "*.md",  # Root-level docs
    ]:
        docs.extend(root.glob(pattern))
    return sorted(set(docs))


def save_metadata(graph: DocGraph, output_path: Path) -> None:
    """Save dependency metadata to JSON."""
    metadata: dict[str, Any] = {
        "generated": datetime.now().isoformat(),
        "docs": {},
    }

    for rel_path, node in sorted(graph.nodes.items()):
        metadata["docs"][rel_path] = {
            "mtime": node.mtime,
            "mtime_iso": datetime.fromtimestamp(node.mtime).isoformat(),
            "last_updated": node.last_updated,
            "depends_on": node.depends_on,
            "touched_by": node.touched_by,
            "needs_update": node.needs_update,
            "reason": node.reason,
            "dependents": sorted(graph.reverse_deps.get(rel_path, [])),
        }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(metadata, indent=2, sort_keys=True))
    print(f"Saved metadata to {output_path}")


def main() -> int:
    parser = ArgumentParser(description="Documentation touch system")
    parser.add_argument("--check", action="store_true",
                        help="Check for stale docs")
    parser.add_argument("--touch", metavar="FILE",
                        help="Mark a file as touched and propagate")
    parser.add_argument("--tree", action="store_true",
                        help="Show dependency tree")
    parser.add_argument("--needs-update", action="store_true",
                        help="Show docs that need updating")
    parser.add_argument("--rebuild-metadata", action="store_true",
                        help="Rebuild and save dependency metadata")
    parser.add_argument("--output", default="docs/todo/doc_dependencies.json",
                        help="Output path for metadata")
    parser.add_argument("--root", type=Path, default=Path.cwd(),
                        help="Repository root")

    args = parser.parse_args()

    root = args.root.resolve()
    docs = collect_docs(root)
    graph = DocGraph(root)
    graph.build_graph(docs)

    if args.rebuild_metadata:
        save_metadata(graph, root / args.output)
        return 0

    if args.check:
        stale = graph.check_staleness()
        if stale:
            print("Stale documentation files:")
            for doc, reasons in sorted(stale.items()):
                print(f"\n  {doc}:")
                for reason in reasons:
                    print(f"    - {reason}")
            return 1
        else:
            print("All docs up to date!")
            return 0

    if args.touch:
        touch_path = Path(args.touch)
        if not touch_path.is_absolute():
            touch_path = root / touch_path
        touched_rel = str(touch_path.relative_to(root))
        affected = graph.mark_stale(touched_rel)
        print(f"Touched: {touched_rel}")
        if affected:
            print(f"\nMarked {len(affected)} docs as needing updates:")
            for doc in sorted(affected):
                print(f"  - {doc}")
        save_metadata(graph, root / args.output)
        return 0

    if args.tree:
        print("Documentation dependency tree:")
        print(graph.get_tree())
        return 0

    if args.needs_update:
        needs_update = [
            path for path, node in graph.nodes.items()
            if node.needs_update
        ]
        if needs_update:
            print(f"Docs needing updates ({len(needs_update)}):")
            for doc in sorted(needs_update):
                node = graph.nodes[doc]
                print(f"  {doc}")
                print(f"    Reason: {node.reason}")
            return 1
        else:
            print("No docs need updating!")
            return 0

    # Default: show summary
    print(f"Documentation dependency graph summary:")
    print(f"  Total docs: {len(graph.nodes)}")
    print(f"  With dependencies: {sum(1 for n in graph.nodes.values() if n.depends_on)}")
    print(f"  Touched by others: {sum(1 for n in graph.nodes.values() if n.touched_by)}")
    print(f"\nUse --check, --tree, --touch, or --needs-update for more info")
    return 0


if __name__ == "__main__":
    sys.exit(main())
