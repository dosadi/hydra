#!/usr/bin/env python3
"""
Build Tree Auto-Freshen System

Automatically rebuilds stale build artifacts based on build_touch.py metadata.

Three-tier approach (like doc freshening):
  Tier 1 (Auto): Safe rebuilds (single files, known good)
  Tier 2 (Assisted): Interactive rebuilds with confirmation
  Tier 3 (Manual): Complex rebuilds requiring attention

Usage:
  # Analyze what needs rebuilding
  python3 scripts/build_freshen.py --analyze

  # Auto-rebuild Tier 1 targets
  python3 scripts/build_freshen.py --auto

  # Interactive rebuild (Tier 2)
  python3 scripts/build_freshen.py --interactive

  # Full workflow
  python3 scripts/build_freshen.py --full

  # Dry run
  python3 scripts/build_freshen.py --auto --dry-run
"""

from __future__ import annotations

import json
import subprocess
import sys
from argparse import ArgumentParser
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any


@dataclass
class RebuildAction:
    """Represents a rebuild action for a stale artifact."""
    artifact: str
    tier: int  # 1=auto, 2=interactive, 3=manual
    action_type: str  # rebuild_single, rebuild_target, full_rebuild
    description: str
    command: str | None = None
    confidence: float = 1.0
    estimated_time: str = "unknown"  # seconds, minutes, hours


class BuildFreshener:
    """Auto-rebuilds stale build artifacts."""

    def __init__(self, root: Path, dry_run: bool = False):
        self.root = root
        self.dry_run = dry_run

    def rebuild(self, action: RebuildAction) -> bool:
        """Execute a rebuild action."""
        if not action.command:
            print(f"Skipping {action.artifact}: No rebuild command")
            return False

        if self.dry_run:
            print(f"[DRY RUN] Would rebuild: {action.artifact}")
            print(f"  Command: {action.command}")
            return True

        print(f"🔨 Rebuilding: {action.artifact}")
        print(f"   Command: {action.command}")

        try:
            result = subprocess.run(
                action.command,
                shell=True,
                cwd=self.root,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )

            if result.returncode == 0:
                print(f"   ✓ Success")
                return True
            else:
                print(f"   ✗ Failed: {result.stderr[:200]}")
                return False

        except subprocess.TimeoutExpired:
            print(f"   ✗ Timeout (>5min)")
            return False
        except Exception as e:
            print(f"   ✗ Error: {e}")
            return False


class BuildAnalysisEngine:
    """Analyzes stale artifacts and determines rebuild strategy."""

    def __init__(self, root: Path):
        self.root = root

    def analyze(self, metadata: dict[str, Any]) -> list[RebuildAction]:
        """Analyze metadata and generate rebuild actions."""
        actions = []

        for path, info in metadata["nodes"].items():
            if not info.get("needs_rebuild", False):
                continue

            action = self._classify_rebuild(path, info)
            if action:
                actions.append(action)

        return actions

    def _classify_rebuild(self, path: str, info: dict) -> RebuildAction | None:
        """Classify what kind of rebuild is needed."""

        node_type = info.get("type", "unknown")
        built_by = info.get("built_by")

        # Tier 1: Simple, safe rebuilds
        if node_type == "object_file":
            # Single .o file rebuild
            source = path.replace(".o", ".cpp").replace(".o", ".c")
            return RebuildAction(
                artifact=path,
                tier=1,
                action_type="rebuild_single",
                description="Rebuild single object file",
                command=f"make -C {Path(path).parent} {Path(path).name}",
                confidence=0.9,
                estimated_time="seconds"
            )

        elif node_type == "rtl_source" and built_by == "verilator":
            # Re-verilate single RTL file (if independent)
            return RebuildAction(
                artifact=path,
                tier=2,  # Verilator can be slow, make it interactive
                action_type="rebuild_target",
                description="Re-verilate RTL file",
                command="make -C sim clean && make -C sim",
                confidence=0.8,
                estimated_time="minutes"
            )

        elif node_type == "binary":
            # Rebuild binary - could be complex
            if "sim_voxel" in path:
                return RebuildAction(
                    artifact=path,
                    tier=2,
                    action_type="full_rebuild",
                    description="Rebuild sim binary",
                    command="make -C sim",
                    confidence=0.7,
                    estimated_time="minutes"
                )

        elif node_type == "test_result":
            # Re-run tests
            return RebuildAction(
                artifact=path,
                tier=1,
                action_type="rebuild_target",
                description="Re-run test",
                command="make -C sim test_frame",
                confidence=0.9,
                estimated_time="seconds"
            )

        # Default: Manual rebuild
        return RebuildAction(
            artifact=path,
            tier=3,
            action_type="manual",
            description=f"Manual rebuild required for {node_type}",
            command=None,
            confidence=0.3,
            estimated_time="unknown"
        )


def main() -> int:
    parser = ArgumentParser(description="Build tree auto-freshen")
    parser.add_argument("--analyze", action="store_true",
                        help="Analyze what needs rebuilding")
    parser.add_argument("--auto", action="store_true",
                        help="Auto-rebuild Tier 1 artifacts")
    parser.add_argument("--interactive", action="store_true",
                        help="Interactive rebuild (Tier 2)")
    parser.add_argument("--full", action="store_true",
                        help="Full workflow (analyze + auto)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would be rebuilt")
    parser.add_argument("--metadata", default="build/build_dependencies.json",
                        help="Build metadata path")
    parser.add_argument("--root", type=Path, default=Path.cwd(),
                        help="Repository root")

    args = parser.parse_args()

    root = args.root.resolve()
    metadata_path = root / args.metadata

    if not metadata_path.exists():
        print("Error: Run 'python3 scripts/build_touch.py --scan' first")
        return 1

    metadata = json.loads(metadata_path.read_text())

    # Analyze
    analyzer = BuildAnalysisEngine(root)
    actions = analyzer.analyze(metadata)

    if not actions:
        print("✓ Nothing needs rebuilding!")
        return 0

    # Report
    if args.analyze or args.full:
        tier_counts = {1: 0, 2: 0, 3: 0}
        for action in actions:
            tier_counts[action.tier] += 1

        print(f"\n🔍 Build Freshening Analysis")
        print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(f"Total stale artifacts: {len(actions)}\n")
        print(f"Breakdown by tier:")
        print(f"  Tier 1 (Auto):        {tier_counts[1]} artifacts")
        print(f"  Tier 2 (Interactive): {tier_counts[2]} artifacts")
        print(f"  Tier 3 (Manual):      {tier_counts[3]} artifacts\n")

        for action in actions:
            print(f"  {action.artifact} (Tier {action.tier})")
            print(f"    Action: {action.description}")
            if action.command:
                print(f"    Command: {action.command}")
            print(f"    Confidence: {action.confidence:.1%}")
            print()

    # Execute
    if args.auto or args.full:
        freshener = BuildFreshener(root, dry_run=args.dry_run)
        tier1_actions = [a for a in actions if a.tier == 1]

        print(f"\n🔨 Auto-rebuilding {len(tier1_actions)} artifacts (Tier 1)...")

        succeeded = 0
        for action in tier1_actions:
            if freshener.rebuild(action):
                succeeded += 1

        print(f"\n✓ Rebuilt {succeeded}/{len(tier1_actions)} artifacts")

    if args.interactive:
        freshener = BuildFreshener(root, dry_run=args.dry_run)
        tier2_actions = [a for a in actions if a.tier == 2]

        print(f"\n🔨 Interactive rebuild ({len(tier2_actions)} artifacts)...")

        for action in tier2_actions:
            print(f"\nRebuild {action.artifact}?")
            print(f"  Command: {action.command}")
            print(f"  Estimated time: {action.estimated_time}")
            response = input("  Rebuild? [y/N]: ")

            if response.lower() == 'y':
                freshener.rebuild(action)

    return 0


if __name__ == "__main__":
    sys.exit(main())
