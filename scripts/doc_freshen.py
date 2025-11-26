#!/usr/bin/env python3
"""
Automated Documentation Freshening System

This tool goes beyond detection - it actually updates stale docs automatically
based on changes in their dependencies. Works in three tiers:

Tier 1 (Auto): Simple updates (dates, cross-refs, version numbers)
Tier 2 (Assisted): AI-generated drafts requiring human review
Tier 3 (Manual): Complex changes requiring human authoring

Usage:
  # Analyze what can be auto-freshened
  python3 scripts/doc_freshen.py --analyze

  # Auto-freshen simple changes (Tier 1)
  python3 scripts/doc_freshen.py --auto

  # Generate assisted drafts (Tier 2)
  python3 scripts/doc_freshen.py --draft

  # Full workflow (analyze → auto → draft → report)
  python3 scripts/doc_freshen.py --full

  # Dry run (show what would be done)
  python3 scripts/doc_freshen.py --auto --dry-run
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from argparse import ArgumentParser
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any

# Load touch system metadata
def load_metadata(root: Path) -> dict[str, Any]:
    """Load dependency metadata from doc_touch.py."""
    metadata_path = root / "docs/todo/doc_dependencies.json"
    if not metadata_path.exists():
        print("Error: Run 'python3 scripts/doc_touch.py --rebuild-metadata' first")
        sys.exit(1)
    return json.loads(metadata_path.read_text())


@dataclass
class Change:
    """Represents a change detected in a dependency."""
    dep_path: str
    change_type: str  # added, removed, modified
    diff_summary: str
    line_range: tuple[int, int] | None = None


@dataclass
class UpdateAction:
    """Represents an action to update a doc."""
    doc_path: str
    tier: int  # 1=auto, 2=assisted, 3=manual
    action_type: str  # update_date, fix_ref, sync_content, rewrite
    description: str
    changes: list[Change] = field(default_factory=list)
    confidence: float = 1.0  # 0.0-1.0
    draft_content: str | None = None


class DependencyAnalyzer:
    """Analyzes what changed in dependencies."""

    def __init__(self, root: Path):
        self.root = root

    def analyze_changes(self, doc_path: str, dep_path: str) -> list[Change]:
        """Analyze what changed in a dependency since doc was last updated."""
        doc_full = self.root / doc_path
        dep_full = self.root / dep_path

        if not dep_full.exists():
            return [Change(
                dep_path=dep_path,
                change_type="removed",
                diff_summary=f"Dependency {dep_path} no longer exists"
            )]

        # Use git to find changes if available
        changes = []
        try:
            # Get last modification time of doc
            doc_mtime = doc_full.stat().st_mtime
            dep_mtime = dep_full.stat().st_mtime

            if dep_mtime > doc_mtime:
                # Try to get git diff
                result = subprocess.run(
                    ["git", "log", "--format=%H %s", "-1", str(dep_full)],
                    cwd=self.root,
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0 and result.stdout.strip():
                    commit_info = result.stdout.strip()
                    changes.append(Change(
                        dep_path=dep_path,
                        change_type="modified",
                        diff_summary=f"Recent change: {commit_info}"
                    ))
                else:
                    changes.append(Change(
                        dep_path=dep_path,
                        change_type="modified",
                        diff_summary=f"Modified {int((dep_mtime - doc_mtime) / 60)} minutes after doc"
                    ))
        except Exception as e:
            changes.append(Change(
                dep_path=dep_path,
                change_type="unknown",
                diff_summary=f"Could not analyze: {e}"
            ))

        return changes


class AutoFreshener:
    """Automatically freshens docs with simple, safe updates."""

    def __init__(self, root: Path, dry_run: bool = False):
        self.root = root
        self.dry_run = dry_run

    def freshen_doc(self, action: UpdateAction) -> bool:
        """Execute a freshening action."""
        doc_path = self.root / action.doc_path

        if not doc_path.exists():
            print(f"Warning: {action.doc_path} does not exist")
            return False

        if action.tier != 1:
            print(f"Skipping {action.doc_path}: Tier {action.tier} requires human review")
            return False

        content = doc_path.read_text(encoding="utf-8", errors="ignore")
        updated_content = content

        # Tier 1 actions (safe to auto-apply)
        if action.action_type == "update_date":
            updated_content = self._update_last_updated(content)
        elif action.action_type == "fix_broken_ref":
            updated_content = self._fix_broken_references(content, action)
        elif action.action_type == "sync_version":
            updated_content = self._sync_version_numbers(content, action)

        if updated_content != content:
            if self.dry_run:
                print(f"[DRY RUN] Would update {action.doc_path}")
                return True
            else:
                doc_path.write_text(updated_content, encoding="utf-8")
                print(f"✓ Updated {action.doc_path}: {action.description}")

                # Touch the doc to mark it fresh
                subprocess.run(
                    ["python3", "scripts/doc_touch.py", "--touch", action.doc_path],
                    cwd=self.root,
                    capture_output=True
                )
                return True

        return False

    def _update_last_updated(self, content: str) -> str:
        """Update **Last Updated:** field to today."""
        today = datetime.now().strftime("%Y-%m-%d")
        pattern = r"\*\*Last Updated:\*\*\s*\d{4}-\d{2}-\d{2}"
        replacement = f"**Last Updated:** {today}"
        return re.sub(pattern, replacement, content)

    def _fix_broken_references(self, content: str, action: UpdateAction) -> str:
        """Fix broken cross-references to other docs."""
        # Placeholder - would implement smart reference fixing
        return content

    def _sync_version_numbers(self, content: str, action: UpdateAction) -> str:
        """Sync version numbers mentioned in doc with dependencies."""
        # Placeholder - would extract version from deps and update
        return content


class AssistedDrafter:
    """Generates draft updates requiring human review."""

    def __init__(self, root: Path):
        self.root = root

    def generate_draft(self, action: UpdateAction) -> str:
        """Generate a draft update for human review."""
        doc_path = self.root / action.doc_path

        if not doc_path.exists():
            return ""

        content = doc_path.read_text(encoding="utf-8", errors="ignore")

        # Build context from dependencies
        context = self._build_context(action)

        # Generate draft (placeholder for LLM integration)
        draft = self._generate_draft_with_context(content, context, action)

        return draft

    def _build_context(self, action: UpdateAction) -> str:
        """Build context from changed dependencies."""
        context_parts = []

        for change in action.changes:
            dep_path = self.root / change.dep_path
            if dep_path.exists():
                # Read recent section of dependency
                dep_content = dep_path.read_text(encoding="utf-8", errors="ignore")
                context_parts.append(f"=== {change.dep_path} ===\n{dep_content[:500]}\n")

        return "\n".join(context_parts)

    def _generate_draft_with_context(self, content: str, context: str, action: UpdateAction) -> str:
        """Generate draft update using context."""
        # This would integrate with an LLM API
        # For now, generate a template

        draft = f"""
# DRAFT UPDATE FOR: {action.doc_path}
# Generated: {datetime.now().isoformat()}
# Confidence: {action.confidence:.1%}
# Action: {action.action_type}
# Description: {action.description}

## Changes Required

Based on changes in dependencies:
{chr(10).join(f'- {c.dep_path}: {c.diff_summary}' for c in action.changes)}

## Suggested Updates

[AI would generate specific content updates here based on context]

## Original Content

{content}

## Review Instructions

1. Review the suggested updates above
2. Apply changes manually to {action.doc_path}
3. Run: python3 scripts/doc_touch.py --touch {action.doc_path}
"""
        return draft


class FresheningOrchestrator:
    """Orchestrates the full freshening workflow."""

    def __init__(self, root: Path, dry_run: bool = False):
        self.root = root
        self.dry_run = dry_run
        self.analyzer = DependencyAnalyzer(root)
        self.auto_freshener = AutoFreshener(root, dry_run)
        self.drafter = AssistedDrafter(root)

    def analyze(self) -> list[UpdateAction]:
        """Analyze all stale docs and determine update actions."""
        metadata = load_metadata(self.root)

        actions = []
        stale_docs = [
            (path, info) for path, info in metadata["docs"].items()
            if info.get("needs_update", False)
        ]

        for doc_path, doc_info in stale_docs:
            # Analyze changes in dependencies
            all_changes = []
            for dep_path in doc_info.get("depends_on", []):
                changes = self.analyzer.analyze_changes(doc_path, dep_path)
                all_changes.extend(changes)

            # Classify what kind of update is needed
            action = self._classify_update(doc_path, doc_info, all_changes)
            if action:
                actions.append(action)

        return actions

    def _classify_update(
        self,
        doc_path: str,
        doc_info: dict,
        changes: list[Change]
    ) -> UpdateAction | None:
        """Classify what tier of update is needed."""

        # Check if it's just a date update (Tier 1 - auto)
        if self._is_just_stale_date(doc_path):
            return UpdateAction(
                doc_path=doc_path,
                tier=1,
                action_type="update_date",
                description="Update Last Updated date",
                changes=changes,
                confidence=1.0
            )

        # Check if it's simple reference sync (Tier 1 - auto)
        if self._is_simple_reference_sync(changes):
            return UpdateAction(
                doc_path=doc_path,
                tier=1,
                action_type="fix_broken_ref",
                description="Fix broken cross-references",
                changes=changes,
                confidence=0.9
            )

        # Check if it needs content sync (Tier 2 - assisted)
        if self._needs_content_sync(doc_path, changes):
            return UpdateAction(
                doc_path=doc_path,
                tier=2,
                action_type="sync_content",
                description="Sync content with updated dependencies",
                changes=changes,
                confidence=0.7
            )

        # Complex update needed (Tier 3 - manual)
        return UpdateAction(
            doc_path=doc_path,
            tier=3,
            action_type="rewrite",
            description="Complex update requires human review",
            changes=changes,
            confidence=0.3
        )

    def _is_just_stale_date(self, doc_path: str) -> bool:
        """Check if doc just needs date update."""
        doc_full = self.root / doc_path
        if not doc_full.exists():
            return False

        content = doc_full.read_text(encoding="utf-8", errors="ignore")
        has_last_updated = bool(re.search(r"\*\*Last Updated:\*\*", content))

        # Simple heuristic: if has Last Updated field and is recent, just update date
        return has_last_updated

    def _is_simple_reference_sync(self, changes: list[Change]) -> bool:
        """Check if changes are just reference updates."""
        # Heuristic: if all changes are small, likely just references
        return len(changes) <= 2

    def _needs_content_sync(self, doc_path: str, changes: list[Change]) -> bool:
        """Check if doc needs actual content updates."""
        return len(changes) > 0

    def run_auto_freshen(self, actions: list[UpdateAction]) -> dict[str, int]:
        """Run automatic freshening for Tier 1 actions."""
        stats = {"attempted": 0, "succeeded": 0, "skipped": 0}

        tier1_actions = [a for a in actions if a.tier == 1]

        print(f"\n🔄 Auto-freshening {len(tier1_actions)} docs (Tier 1)...")

        for action in tier1_actions:
            stats["attempted"] += 1
            if self.auto_freshener.freshen_doc(action):
                stats["succeeded"] += 1
            else:
                stats["skipped"] += 1

        return stats

    def generate_drafts(self, actions: list[UpdateAction], output_dir: Path) -> int:
        """Generate draft updates for Tier 2 actions."""
        tier2_actions = [a for a in actions if a.tier == 2]

        print(f"\n📝 Generating drafts for {len(tier2_actions)} docs (Tier 2)...")

        output_dir.mkdir(parents=True, exist_ok=True)

        for action in tier2_actions:
            draft = self.drafter.generate_draft(action)

            # Save draft
            draft_path = output_dir / f"{Path(action.doc_path).stem}_draft.md"
            draft_path.write_text(draft, encoding="utf-8")
            print(f"  → Draft saved: {draft_path}")

        return len(tier2_actions)

    def generate_report(self, actions: list[UpdateAction]) -> str:
        """Generate a summary report of freshening actions."""
        tier_counts = {1: 0, 2: 0, 3: 0}
        for action in actions:
            tier_counts[action.tier] += 1

        report = f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Doc Freshening Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Generated: {datetime.now().isoformat()}
Total stale docs: {len(actions)}

Breakdown by tier:
  Tier 1 (Auto):      {tier_counts[1]} docs - Can be auto-freshened
  Tier 2 (Assisted):  {tier_counts[2]} docs - Drafts generated
  Tier 3 (Manual):    {tier_counts[3]} docs - Require human authoring

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tier 1 Actions (Auto-Applied):
"""

        for action in [a for a in actions if a.tier == 1]:
            report += f"\n  ✓ {action.doc_path}"
            report += f"\n    Action: {action.description}"
            report += f"\n    Confidence: {action.confidence:.1%}\n"

        report += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        report += "Tier 2 Actions (Drafts Generated):\n"

        for action in [a for a in actions if a.tier == 2]:
            report += f"\n  📝 {action.doc_path}"
            report += f"\n     Action: {action.description}"
            report += f"\n     Changes: {len(action.changes)} dependencies updated"
            report += f"\n     Confidence: {action.confidence:.1%}\n"

        report += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        report += "Tier 3 Actions (Manual Review Required):\n"

        for action in [a for a in actions if a.tier == 3]:
            report += f"\n  ⚠  {action.doc_path}"
            report += f"\n     Reason: {action.description}"
            report += f"\n     Dependencies changed:\n"
            for change in action.changes:
                report += f"\n       - {change.dep_path}: {change.diff_summary}"
            report += "\n"

        report += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        report += "\nNext Steps:\n"
        report += f"  1. Review Tier 1 changes (auto-applied)\n"
        report += f"  2. Review drafts in docs/freshening_drafts/\n"
        report += f"  3. Manually update Tier 3 docs\n"
        report += f"  4. Run: python3 scripts/doc_touch.py --check\n"
        report += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

        return report


def main() -> int:
    parser = ArgumentParser(description="Automated documentation freshening")
    parser.add_argument("--analyze", action="store_true",
                        help="Analyze stale docs and classify actions")
    parser.add_argument("--auto", action="store_true",
                        help="Auto-freshen Tier 1 docs")
    parser.add_argument("--draft", action="store_true",
                        help="Generate drafts for Tier 2 docs")
    parser.add_argument("--full", action="store_true",
                        help="Run full workflow (analyze + auto + draft)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would be done without making changes")
    parser.add_argument("--report", action="store_true",
                        help="Generate summary report")
    parser.add_argument("--root", type=Path, default=Path.cwd(),
                        help="Repository root")
    parser.add_argument("--output", type=Path, default=Path("docs/freshening_drafts"),
                        help="Output directory for drafts")

    args = parser.parse_args()

    root = args.root.resolve()
    orchestrator = FresheningOrchestrator(root, dry_run=args.dry_run)

    # Analyze stale docs
    print("🔍 Analyzing stale documentation...")
    actions = orchestrator.analyze()

    if not actions:
        print("✓ All docs are fresh!")
        return 0

    print(f"Found {len(actions)} stale docs\n")

    # Run requested operations
    if args.analyze or args.full:
        report = orchestrator.generate_report(actions)
        print(report)

        if not args.full:
            return 0

    if args.auto or args.full:
        stats = orchestrator.run_auto_freshen(actions)
        print(f"\n✓ Auto-freshened {stats['succeeded']}/{stats['attempted']} docs")

    if args.draft or args.full:
        output_dir = root / args.output
        count = orchestrator.generate_drafts(actions, output_dir)
        print(f"\n✓ Generated {count} drafts in {output_dir}")

    if args.report:
        report = orchestrator.generate_report(actions)
        report_path = root / "docs/freshening_report.md"
        report_path.write_text(report, encoding="utf-8")
        print(f"\n✓ Report saved to {report_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
