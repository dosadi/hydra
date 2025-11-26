# Documentation Touch System

**Last Updated:** 2025-11-26
**Status:** Active - Pervasive pattern for all docs

---

## Overview

The **Documentation Touch System** implements Makefile-style dependency tracking for documentation files. Just as Make rebuilds object files when source files change, this system flags documentation that needs reconsideration when its dependencies are updated.

This solves the problem of documentation "hanging around" without clear signals about what needs updating when foundational specs or related docs change.

## Core Concept: Touch Propagation

The system implements a **pervasive touch action** throughout the docs:

1. **Dependencies are declared** in doc headers using standardized metadata
2. **Changes propagate** through dependency chains automatically
3. **Staleness is tracked** by comparing modification times
4. **Updates are flagged** so you know what needs attention

### Analogy to Unix Make

```makefile
# Traditional Makefile dependency
driver_guide.html: driver_guide.md hydra_spec.md
    markdown driver_guide.md > driver_guide.html

# Doc touch system equivalent
# docs/driver_integration.md declares:
# **Depends:** `hydra_spec.md`
#
# When hydra_spec.md is touched:
# → driver_integration.md is flagged as needing update
```

---

## Dependency Declaration Format

Add these standardized headers to your markdown files:

### Basic Template

```markdown
# Document Title

**Last Updated:** YYYY-MM-DD
**Owner:** Team/Person Name
**Depends:** `file1.md`, `file2.md`
**Related Trackers:** `todo_area1.md`, `todo_area2.md`
**Touches:** `downstream_doc.md`

---

[Document content...]
```

### Metadata Fields

| Field | Purpose | Example |
|-------|---------|---------|
| `**Last Updated:**` | Manual timestamp for significant updates | `2025-11-26` |
| `**Owner:**` | Who maintains this doc | `Driver Team`, `AI Agent` |
| `**Depends:**` | Hard dependencies - this doc builds on these | `` `hydra_spec.md`, `driver_integration.md` `` |
| `**Related Trackers:**` | Soft dependencies - should stay in sync | `` `todo_dma_pcie.md`, `todo_testing_ci.md` `` |
| `**Touches:**` | Docs that should update when this changes | `` `downstream_guide.md` `` |

### Dependency Types

#### Hard Dependencies (`**Depends:**`)
Use for docs that directly build upon other docs:
- Implementation guides depend on specs
- Detailed TODOs depend on master plans
- Driver docs depend on register maps

```markdown
**Depends:** `hydra_spec.md`, `axi_integration.md`
```

When a dependency is touched, this doc is **immediately flagged as stale**.

#### Soft Dependencies (`**Related Trackers:**`)
Use for docs that should stay aligned:
- Related TODO trackers
- Cross-cutting concerns
- Parallel workstreams

```markdown
**Related Trackers:** `todo_dma_pcie.md`, `todo_testing_ci.md`
```

When a related tracker updates significantly, this doc is **suggested for review**.

#### Downstream Touches (`**Touches:**`)
Explicitly declare which docs downstream should update when this changes:

```markdown
**Touches:** `driver_integration.md`, `hardware_test_plan.md`
```

This is the **inverse dependency** - you're declaring "if I change, these need attention".

---

## Using the Touch System

### Installation

The touch system is implemented in `scripts/doc_touch.py`:

```bash
# Make it executable
chmod +x scripts/doc_touch.py

# Add to CI/dev loop
./scripts/hydra_dev_loop.sh  # Already includes doc touch checks
```

### Basic Operations

#### Check for Stale Docs

```bash
python3 scripts/doc_touch.py --check
```

Output:
```
Stale documentation files:

  docs/driver_integration.md:
    - hydra_spec.md updated 120min after this doc
    - todo_dma_pcie.md touched 45min after this doc

  docs/todo/todo_testing_ci.md:
    - Depends on docs/testing_overview.md which was updated
```

#### Touch a Document

When you update a doc, mark it as touched to propagate staleness:

```bash
python3 scripts/doc_touch.py --touch docs/hydra_spec.md
```

Output:
```
Touched: docs/hydra_spec.md

Marked 5 docs as needing updates:
  - docs/driver_integration.md
  - docs/hardware_test_plan.md
  - docs/todo/todo_dma_pcie.md
  - docs/testing_overview.md
  - docs/ip_integration.md
```

This creates a **dependency metadata file** at `docs/todo/doc_dependencies.json` that tracks the state.

#### View Dependency Tree

```bash
python3 scripts/doc_touch.py --tree
```

Output:
```
Documentation dependency tree:

docs/hydra_spec.md
  ⬆ docs/driver_integration.md depends on this
  ⬆ docs/hardware_test_plan.md depends on this
  ⬆ docs/ip_integration.md depends on this

docs/driver_integration.md
  └─ docs/hydra_spec.md
  └─ docs/todo/todo_dma_pcie.md [STALE]
```

#### Show What Needs Updating

```bash
python3 scripts/doc_touch.py --needs-update
```

Output:
```
Docs needing updates (3):
  docs/driver_integration.md
    Reason: Depends on docs/hydra_spec.md which was updated
  docs/testing_overview.md
    Reason: Depends on docs/hydra_spec.md which was updated
  docs/todo/todo_testing_ci.md
    Reason: Related to docs/testing_overview.md which was updated
```

#### Rebuild Metadata

After adding dependency declarations to docs:

```bash
python3 scripts/doc_touch.py --rebuild-metadata
```

This scans all docs and regenerates `docs/todo/doc_dependencies.json`.

---

## Integration with Development Workflow

### In `hydra_dev_loop.sh`

The touch system is integrated into the main dev loop:

```bash
#!/bin/bash
# scripts/hydra_dev_loop.sh

# ... build sim, run tests ...

# Check doc dependencies
echo "Checking documentation dependencies..."
if python3 scripts/doc_touch.py --check; then
    echo "✓ Docs up to date"
else
    echo "⚠ Some docs are stale (see above)"
    echo "  Run: python3 scripts/doc_touch.py --needs-update"
fi

# ... continue with SDK build ...
```

### In CI

Add to `.github/workflows/ci.yml`:

```yaml
- name: Check doc dependencies
  run: |
    python3 scripts/doc_touch.py --check || true
    python3 scripts/doc_touch.py --rebuild-metadata

- name: Upload doc metadata
  uses: actions/upload-artifact@v3
  with:
    name: doc-dependencies
    path: docs/todo/doc_dependencies.json
```

### Manual Workflow

When you update a foundational doc:

```bash
# 1. Edit the spec
vim docs/hydra_spec.md

# 2. Touch it to propagate
python3 scripts/doc_touch.py --touch docs/hydra_spec.md

# 3. See what needs attention
python3 scripts/doc_touch.py --needs-update

# 4. Update affected docs
vim docs/driver_integration.md
vim docs/hardware_test_plan.md

# 5. Touch those when done
python3 scripts/doc_touch.py --touch docs/driver_integration.md
python3 scripts/doc_touch.py --touch docs/hardware_test_plan.md

# 6. Commit with metadata
git add docs/hydra_spec.md docs/driver_integration.md \
        docs/todo/doc_dependencies.json
git commit -m "Update spec and downstream integration docs"
```

---

## Dependency Patterns

### Pattern 1: Spec → Implementation Guides

Foundation specs touch all implementation guides:

```markdown
# docs/hydra_spec.md
**Touches:** `driver_integration.md`, `hardware_test_plan.md`, `ip_integration.md`
```

```markdown
# docs/driver_integration.md
**Depends:** `hydra_spec.md`
```

### Pattern 2: TODO Tracker Hierarchy

Master trackers touch detailed trackers:

```markdown
# docs/todo/todo_master.md
**Touches:** `todo_dma_pcie.md`, `todo_rendering.md`, `todo_testing_ci.md`
```

```markdown
# docs/todo/todo_dma_pcie.md
**Depends:** `todo_master.md`
**Related Trackers:** `todo_testing_ci.md`, `todo_ip_integration.md`
```

### Pattern 3: Cross-Cutting Concerns

Design docs touch multiple implementation areas:

```markdown
# docs/memory_architecture.md
**Touches:** `driver_integration.md`, `todo_dma_pcie.md`, `todo_dram_axi.md`
```

### Pattern 4: Test Plans

Test plans depend on specs and implementation docs:

```markdown
# docs/hardware_test_plan.md
**Depends:** `hydra_spec.md`, `driver_integration.md`, `ip_integration.md`
**Related Trackers:** `todo_testing_ci.md`, `todo_hardware_validation.md`
```

---

## Advanced: Automation Hooks

### Pre-Commit Hook

Check dependencies before committing:

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Get list of modified docs
MODIFIED_DOCS=$(git diff --cached --name-only | grep '\.md$')

if [ -n "$MODIFIED_DOCS" ]; then
    echo "Checking doc dependencies..."

    # Rebuild metadata
    python3 scripts/doc_touch.py --rebuild-metadata

    # Add metadata to commit
    git add docs/todo/doc_dependencies.json

    # Show what became stale
    python3 scripts/doc_touch.py --needs-update || true
fi
```

### Watch Mode (for AI Agents)

Continuously monitor docs for staleness:

```bash
#!/bin/bash
# scripts/doc_watch.sh

while true; do
    python3 scripts/doc_touch.py --check > /tmp/doc_status.txt

    if [ $? -ne 0 ]; then
        echo "📝 Stale docs detected:"
        cat /tmp/doc_status.txt

        # Could trigger AI agent here
        # python3 scripts/ai_update_stale_docs.py
    fi

    sleep 300  # Check every 5 minutes
done
```

### AI Integration

The touch system provides clear signals for AI agents:

```python
# scripts/ai_update_stale_docs.py
import json
from pathlib import Path

# Load dependency metadata
metadata = json.loads(Path("docs/todo/doc_dependencies.json").read_text())

# Find stale docs
stale_docs = [
    doc for doc, info in metadata["docs"].items()
    if info["needs_update"]
]

# Prioritize by dependency depth
for doc in stale_docs:
    print(f"AI: Reconsidering {doc}")
    # Trigger AI agent to review and update
```

---

## Metadata Format

The generated `docs/todo/doc_dependencies.json` has this structure:

```json
{
  "generated": "2025-11-26T10:30:00",
  "docs": {
    "docs/hydra_spec.md": {
      "mtime": 1732615800.0,
      "mtime_iso": "2025-11-26T10:30:00",
      "last_updated": "2025-11-26",
      "depends_on": [],
      "touched_by": [],
      "needs_update": false,
      "reason": "",
      "dependents": [
        "docs/driver_integration.md",
        "docs/hardware_test_plan.md"
      ]
    },
    "docs/driver_integration.md": {
      "mtime": 1732612200.0,
      "mtime_iso": "2025-11-26T09:30:00",
      "last_updated": "2025-11-20",
      "depends_on": ["docs/hydra_spec.md"],
      "touched_by": [],
      "needs_update": true,
      "reason": "Depends on docs/hydra_spec.md which was updated",
      "dependents": []
    }
  }
}
```

This metadata can be consumed by:
- CI pipelines
- AI agents
- Developer dashboards
- Git hooks

---

## Benefits

### For Humans

1. **Clear signals** - Know exactly which docs need attention
2. **Reduced cognitive load** - No need to remember all interdependencies
3. **Better maintenance** - Docs don't "hang around" stale

### For AI Agents

1. **Structured input** - JSON metadata provides clear work queue
2. **Prioritization** - Dependency depth indicates importance
3. **Validation** - Can check if updates are complete

### For Projects

1. **Documentation quality** - Stays in sync with code/specs
2. **Onboarding** - New contributors see up-to-date docs
3. **Release confidence** - Verify all docs updated before release

---

## Migration Guide

To add the touch system to existing docs:

### Step 1: Add Headers

Update all key docs with dependency declarations:

```bash
# Find docs without headers
grep -L "Last Updated:" docs/*.md docs/todo/*.md

# Add template to each
```

### Step 2: Declare Dependencies

For each doc, identify:
- What specs/foundations it builds on (`**Depends:**`)
- What related areas it should sync with (`**Related Trackers:**`)
- What downstream docs it affects (`**Touches:**`)

### Step 3: Generate Initial Metadata

```bash
python3 scripts/doc_touch.py --rebuild-metadata
git add docs/todo/doc_dependencies.json
git commit -m "Add doc dependency tracking"
```

### Step 4: Integrate into Workflow

Add to `scripts/hydra_dev_loop.sh` and CI.

### Step 5: Maintain

When updating docs:
1. Edit the doc
2. Touch it with `--touch`
3. Review `--needs-update` output
4. Update affected docs
5. Commit metadata with changes

---

## FAQ

### Q: Do I need to touch every doc?

No - focus on:
- Foundation docs (specs, architecture)
- TODO trackers
- Integration guides

Tutorials and READMEs can opt out.

### Q: What if I create a circular dependency?

The tool detects cycles and shows them in `--tree` output:

```
docs/a.md
  └─ docs/b.md
    └─ docs/c.md
      └─ docs/a.md (circular dependency)
```

Fix by removing one of the dependency declarations.

### Q: How do I mark a doc as "up to date"?

Just touch it:

```bash
python3 scripts/doc_touch.py --touch docs/my_doc.md
```

This clears the `needs_update` flag.

### Q: Can I use this with `git touch`?

Yes! You can create a git alias:

```bash
git config alias.doc-touch '!python3 scripts/doc_touch.py --touch'
git doc-touch docs/hydra_spec.md
```

---

## See Also

- `docs/todo/todo_dependency_map.md` - Manual tracker dependencies
- `scripts/todo_metadata.py` - TODO tracker metadata
- `scripts/hydra_dev_loop.sh` - Main development loop
- `docs/todo/todo_documentation.md` - Documentation TODOs

---

**Next Actions:**
1. Add dependency declarations to all spec docs
2. Update TODO trackers with dependency metadata
3. Integrate `doc_touch.py` into CI
4. Create pre-commit hook for automatic metadata updates

