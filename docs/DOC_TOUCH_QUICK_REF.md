# Doc Touch System - Quick Reference

**Tool:** `scripts/doc_touch.py`
**Metadata:** `docs/todo/doc_dependencies.json`
**Guide:** `docs/doc_touch_system.md`

---

## Common Commands

### Daily Use

```bash
# Check which docs are stale
python3 scripts/doc_touch.py --check

# Mark a doc as updated after editing it
python3 scripts/doc_touch.py --touch docs/hydra_spec.md

# See what needs your attention
python3 scripts/doc_touch.py --needs-update

# Get current status
python3 scripts/doc_touch.py
```

### Visualization

```bash
# Show full dependency tree
python3 scripts/doc_touch.py --tree

# Rebuild metadata after adding dependency headers
python3 scripts/doc_touch.py --rebuild-metadata
```

---

## Dependency Header Template

Add to top of your markdown files:

```markdown
# Your Document Title

**Last Updated:** YYYY-MM-DD
**Owner:** Team/Person Name
**Depends:** `foundation.md`, `spec.md`
**Related Trackers:** `todo_area.md`
**Touches:** `downstream.md`

---

[Your content here...]
```

---

## Quick Workflow

### After Updating a Doc

```bash
# 1. Edit the doc
vim docs/hydra_spec.md

# 2. Touch it
python3 scripts/doc_touch.py --touch docs/hydra_spec.md

# 3. See what became stale
python3 scripts/doc_touch.py --check

# 4. Update affected docs
vim docs/driver_integration.md

# 5. Touch those too
python3 scripts/doc_touch.py --touch docs/driver_integration.md

# 6. Commit with metadata
git add docs/hydra_spec.md docs/driver_integration.md \
        docs/todo/doc_dependencies.json
git commit -m "Update spec and downstream docs"
```

---

## Current State

**As of 2025-11-26:**

- **173** docs tracked total
- **9** docs with dependency headers
- **20** docs in touch relationships
- **21** docs flagged in last propagation

**Hub docs (most impactful):**
1. `todo_testing_ci.md` - 12 dependents
2. `todo_hardware_validation.md` - 11 dependents
3. `todo_dma_pcie.md` - 10 dependents

---

## Integration Points

### In CI

```yaml
- name: Check doc dependencies
  run: python3 scripts/doc_touch.py --check || exit 1
```

### In Dev Loop

```bash
# Add to scripts/hydra_dev_loop.sh
python3 scripts/doc_touch.py --check || \
    echo "⚠ Some docs are stale"
```

### For AI Agents

```python
import json
metadata = json.loads(Path("docs/todo/doc_dependencies.json").read_text())
stale = [d for d, i in metadata["docs"].items() if i["needs_update"]]
# Process stale docs...
```

---

**For full documentation:** See `docs/doc_touch_system.md`

