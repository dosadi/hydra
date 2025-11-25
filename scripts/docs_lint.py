#!/usr/bin/env python3
"""Simple docs lint: verify local Markdown links point to existing files."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Iterable, Tuple


LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
SKIP_PREFIXES = ("http://", "https://", "mailto:", "#")


def find_markdown_files(root: Path) -> Iterable[Path]:
    for path in root.glob("**/*.md"):
        # Skip third_party and build artifacts
        if "third_party" in path.parts or "build" in path.parts or ".git" in path.parts:
            continue
        yield path


def resolve_link(base: Path, target: str) -> Path:
    target = target.split("#", 1)[0]  # drop anchor
    return (base.parent / target).resolve()


def check_links(files: Iterable[Path]) -> Tuple[int, list[str]]:
    missing: list[str] = []
    count = 0
    for md_file in files:
        text = md_file.read_text(encoding="utf-8")
        for match in LINK_RE.finditer(text):
            href = match.group(1).strip()
            if href.startswith(SKIP_PREFIXES):
                continue
            # Skip absolute paths (unlikely in repo)
            if href.startswith("/"):
                continue
            count += 1
            target_path = resolve_link(md_file, href)
            if not target_path.exists():
                missing.append(f"{md_file}: broken link -> {href} (resolved {target_path})")
    return count, missing


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    files = list(find_markdown_files(root))
    count, missing = check_links(files)
    print(f"[docs-lint] scanned {len(files)} markdown files, {count} links")
    if missing:
        print("[docs-lint] broken links found:")
        for m in missing:
            print(f"  - {m}")
        return 1
    print("[docs-lint] OK: no broken local links")
    return 0


if __name__ == "__main__":
    sys.exit(main())
