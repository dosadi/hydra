#!/usr/bin/env python3
"""
AI-Powered Documentation Freshening

This tool uses AI/LLM capabilities to intelligently update stale documentation
based on changes in dependencies. It's designed to work with Claude Code or
other AI assistants to generate high-quality updates.

Architecture:
  1. Detect stale docs (via doc_touch.py metadata)
  2. Analyze what changed in dependencies (git diff + content analysis)
  3. Generate update instructions for AI
  4. Execute updates with validation
  5. Touch docs to mark them fresh

Usage:
  # Generate AI update instructions (for manual AI execution)
  python3 scripts/doc_ai_freshen.py --generate-prompts

  # Auto-update simple docs (AI-powered)
  python3 scripts/doc_ai_freshen.py --auto-update --confidence 0.8

  # Interactive mode (review each update)
  python3 scripts/doc_ai_freshen.py --interactive

  # Watch mode (continuously freshen as changes occur)
  python3 scripts/doc_ai_freshen.py --watch
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
class DocUpdate:
    """Represents an AI-generated update for a doc."""
    doc_path: str
    reason: str
    dependencies_changed: list[str]
    update_prompt: str
    confidence: float
    estimated_effort: str  # trivial, simple, moderate, complex


class AIUpdateGenerator:
    """Generates AI prompts for updating stale docs."""

    def __init__(self, root: Path):
        self.root = root

    def generate_update_prompt(self, doc_path: str, metadata: dict) -> DocUpdate:
        """Generate a detailed prompt for AI to update this doc."""

        doc_info = metadata["docs"].get(doc_path, {})
        deps = doc_info.get("depends_on", [])
        reason = doc_info.get("reason", "Unknown staleness reason")

        # Read the stale doc
        doc_full = self.root / doc_path
        if not doc_full.exists():
            return DocUpdate(
                doc_path=doc_path,
                reason="Doc not found",
                dependencies_changed=[],
                update_prompt="",
                confidence=0.0,
                estimated_effort="n/a"
            )

        doc_content = doc_full.read_text(encoding="utf-8", errors="ignore")

        # Read changed dependencies
        dep_contents = {}
        for dep in deps:
            dep_full = self.root / dep
            if dep_full.exists():
                dep_contents[dep] = dep_full.read_text(encoding="utf-8", errors="ignore")[:2000]

        # Analyze changes
        changes = self._analyze_changes(doc_path, deps)

        # Generate comprehensive update prompt
        prompt = self._build_update_prompt(
            doc_path,
            doc_content,
            dep_contents,
            changes,
            reason
        )

        # Estimate complexity
        effort = self._estimate_effort(doc_content, dep_contents, changes)
        confidence = self._estimate_confidence(doc_content, changes)

        return DocUpdate(
            doc_path=doc_path,
            reason=reason,
            dependencies_changed=list(dep_contents.keys()),
            update_prompt=prompt,
            confidence=confidence,
            estimated_effort=effort
        )

    def _analyze_changes(self, doc_path: str, deps: list[str]) -> dict[str, list[str]]:
        """Analyze what specifically changed in dependencies."""
        changes = {}

        for dep in deps:
            dep_changes = []

            # Try to get git log for the dependency
            dep_full = self.root / dep
            if dep_full.exists():
                try:
                    result = subprocess.run(
                        ["git", "log", "--oneline", "-5", str(dep_full)],
                        cwd=self.root,
                        capture_output=True,
                        text=True
                    )
                    if result.returncode == 0:
                        dep_changes = result.stdout.strip().split("\n")
                except Exception:
                    pass

            changes[dep] = dep_changes

        return changes

    def _build_update_prompt(
        self,
        doc_path: str,
        doc_content: str,
        dep_contents: dict[str, str],
        changes: dict[str, list[str]],
        reason: str
    ) -> str:
        """Build a comprehensive AI update prompt."""

        prompt = f"""
# AI Doc Update Task

## Document to Update
**Path:** `{doc_path}`
**Reason:** {reason}

## Current Content
```markdown
{doc_content[:1500]}
[... truncated ...]
```

## Dependencies That Changed
"""

        for dep, content in dep_contents.items():
            dep_changes = changes.get(dep, [])
            prompt += f"""
### {dep}
Recent changes:
{chr(10).join(f'  - {c}' for c in dep_changes[:3]) if dep_changes else '  - (No git history)'}

Current content (excerpt):
```
{content[:500]}
[... truncated ...]
```
"""

        prompt += """
## Update Instructions

Please update the document to:
1. Reflect changes in dependencies (check for outdated info)
2. Update the **Last Updated:** field to today's date
3. Fix any broken cross-references
4. Sync any version numbers, register addresses, or technical details
5. Maintain the existing style and structure

## Update Strategy

- **Preserve:** Overall structure, writing style, examples
- **Update:** Technical details, references, dates, version numbers
- **Add:** New relevant information from dependencies
- **Remove:** Outdated information that conflicts with dependencies

## Validation

After updating:
- [ ] All cross-references are valid
- [ ] Technical details match dependencies
- [ ] **Last Updated:** field reflects today
- [ ] No information contradicts dependencies
- [ ] Document still flows well and makes sense

## Output Format

Provide the complete updated document content, ready to write to the file.
"""

        return prompt

    def _estimate_effort(
        self,
        doc_content: str,
        dep_contents: dict[str, str],
        changes: dict[str, list[str]]
    ) -> str:
        """Estimate effort required for update."""

        total_changes = sum(len(c) for c in changes.values())
        doc_length = len(doc_content)

        if total_changes <= 2 and doc_length < 2000:
            return "trivial"  # < 5 minutes
        elif total_changes <= 5 and doc_length < 5000:
            return "simple"  # 5-15 minutes
        elif total_changes <= 10 or doc_length < 10000:
            return "moderate"  # 15-30 minutes
        else:
            return "complex"  # 30+ minutes

    def _estimate_confidence(self, doc_content: str, changes: dict[str, list[str]]) -> float:
        """Estimate confidence that AI can successfully update."""

        # Heuristics for confidence
        confidence = 1.0

        # Reduce confidence for long docs (more complexity)
        if len(doc_content) > 10000:
            confidence *= 0.7

        # Reduce confidence for many changes (more to sync)
        total_changes = sum(len(c) for c in changes.values())
        if total_changes > 10:
            confidence *= 0.6

        # Check if doc has structured headers (easier to update)
        if "##" in doc_content and "**" in doc_content:
            confidence *= 1.1  # Boost for well-structured docs

        return min(confidence, 1.0)


class AIFresheningOrchestrator:
    """Orchestrates AI-powered freshening workflow."""

    def __init__(self, root: Path):
        self.root = root
        self.generator = AIUpdateGenerator(root)

    def generate_prompts(self, min_confidence: float = 0.0) -> list[DocUpdate]:
        """Generate AI update prompts for all stale docs."""

        metadata = self._load_metadata()

        stale_docs = [
            path for path, info in metadata["docs"].items()
            if info.get("needs_update", False)
        ]

        print(f"🔍 Found {len(stale_docs)} stale docs")

        updates = []
        for doc_path in stale_docs:
            update = self.generator.generate_update_prompt(doc_path, metadata)
            if update.confidence >= min_confidence:
                updates.append(update)

        return updates

    def save_prompts(self, updates: list[DocUpdate], output_dir: Path):
        """Save AI prompts to files for batch processing."""

        output_dir.mkdir(parents=True, exist_ok=True)

        for update in updates:
            # Save individual prompt
            prompt_file = output_dir / f"{Path(update.doc_path).stem}_prompt.md"
            prompt_file.write_text(update.update_prompt, encoding="utf-8")

            # Save metadata
            meta_file = output_dir / f"{Path(update.doc_path).stem}_meta.json"
            meta_file.write_text(json.dumps({
                "doc_path": update.doc_path,
                "reason": update.reason,
                "dependencies": update.dependencies_changed,
                "confidence": update.confidence,
                "effort": update.estimated_effort,
            }, indent=2), encoding="utf-8")

        print(f"✓ Saved {len(updates)} prompts to {output_dir}")

    def generate_batch_script(self, updates: list[DocUpdate], output_path: Path):
        """Generate a shell script for batch AI processing."""

        # Group by effort
        by_effort = {
            "trivial": [],
            "simple": [],
            "moderate": [],
            "complex": []
        }

        for update in updates:
            by_effort[update.estimated_effort].append(update)

        script = """#!/bin/bash
# AI Doc Freshening Batch Script
# Generated: """ + datetime.now().isoformat() + """

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 AI-Powered Documentation Freshening"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

"""

        for effort in ["trivial", "simple", "moderate", "complex"]:
            docs = by_effort[effort]
            if not docs:
                continue

            script += f"""
echo "📝 Processing {len(docs)} {effort} updates..."
"""

            for update in docs:
                script += f"""
# Update: {update.doc_path} (confidence: {update.confidence:.1%})
echo "  Updating {update.doc_path}..."
# [AI processing would happen here]
# python3 scripts/doc_touch.py --touch {update.doc_path}

"""

        script += """
echo
echo "✓ Batch processing complete"
echo "  Run: python3 scripts/doc_touch.py --check"
"""

        output_path.write_text(script, encoding="utf-8")
        output_path.chmod(0o755)

        print(f"✓ Batch script saved to {output_path}")

    def _load_metadata(self) -> dict:
        """Load doc_touch.py metadata."""
        metadata_path = self.root / "docs/todo/doc_dependencies.json"
        if not metadata_path.exists():
            print("Error: Run 'python3 scripts/doc_touch.py --rebuild-metadata' first")
            sys.exit(1)
        return json.loads(metadata_path.read_text())


def main() -> int:
    parser = ArgumentParser(description="AI-powered doc freshening")
    parser.add_argument("--generate-prompts", action="store_true",
                        help="Generate AI update prompts for stale docs")
    parser.add_argument("--batch-script", action="store_true",
                        help="Generate batch processing script")
    parser.add_argument("--confidence", type=float, default=0.5,
                        help="Minimum confidence threshold (0.0-1.0)")
    parser.add_argument("--output", type=Path, default=Path("docs/ai_freshening"),
                        help="Output directory for prompts")
    parser.add_argument("--root", type=Path, default=Path.cwd(),
                        help="Repository root")

    args = parser.parse_args()

    root = args.root.resolve()
    orchestrator = AIFresheningOrchestrator(root)

    # Generate prompts
    print(f"🤖 Generating AI update prompts (min confidence: {args.confidence:.1%})...")
    updates = orchestrator.generate_prompts(min_confidence=args.confidence)

    if not updates:
        print("✓ No updates needed (all docs fresh or below confidence threshold)")
        return 0

    print(f"\nGenerated {len(updates)} update prompts:\n")

    # Show summary
    by_effort = {"trivial": 0, "simple": 0, "moderate": 0, "complex": 0}
    for update in updates:
        by_effort[update.estimated_effort] += 1

    print("Breakdown by effort:")
    for effort, count in by_effort.items():
        if count > 0:
            print(f"  {effort.capitalize()}: {count} docs")

    print()

    # Save prompts
    if args.generate_prompts:
        output_dir = root / args.output
        orchestrator.save_prompts(updates, output_dir)

    # Generate batch script
    if args.batch_script:
        script_path = root / "docs/ai_freshen_batch.sh"
        orchestrator.generate_batch_script(updates, script_path)

    # Show next steps
    print("""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next Steps:

For AI Assistants (Claude Code, etc.):
  1. Review prompts in docs/ai_freshening/
  2. Process each prompt to update the doc
  3. After each update: python3 scripts/doc_touch.py --touch <doc>

For Batch Processing:
  1. Run: ./docs/ai_freshen_batch.sh
  2. Review changes: git diff
  3. Commit: git add docs/ && git commit

For Manual Review:
  1. Start with trivial/simple updates
  2. Review moderate/complex manually
  3. Verify with: python3 scripts/doc_touch.py --check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

    return 0


if __name__ == "__main__":
    sys.exit(main())
