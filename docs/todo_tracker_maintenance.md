# TODO Tracker Maintenance Guide

This guide explains how to properly maintain and update the Hydra TODO tracking system. Understanding these processes ensures the project roadmap stays accurate and actionable.

## TODO System Overview

### Structure
```
docs/todo/
├── todo_*.md              # Individual trackers (40+ files)
├── todo_master.md         # Master coordination tracker
└── todo_dependency_map.md # Cross-tracker dependencies
```

### Key Principles
1. **Single Source of Truth**: Each TODO item exists in exactly one tracker
2. **Priority-Driven**: P0 (critical) → P1 (high) → P2 (medium) → P3 (low/future)
3. **Status Tracking**: `[DONE]`, `[TODO]`, `[IN PROGRESS]`, `[BLOCKED]`
4. **Effort Estimation**: Realistic time estimates in days
5. **Validation**: Automated checks via `scripts/todo_sweep.py`

## Status Tags

### Status Format
```markdown
- **[DONE] [P1]:** Task description (completed items)
- **[TODO] [P2]:** Task description (pending items)
- **[IN PROGRESS] [P0]:** Task description (actively worked on)
- **[BLOCKED] [P1]:** Task description (waiting on dependencies)
```

### When to Use Each Status

#### `[DONE]`
- Task fully completed and validated
- Code merged, tests passing, documentation updated
- Example: `**[DONE] [P1]:** Add comprehensive keybindings reference`

#### `[TODO]`
- Task identified but not started
- Ready to be worked on
- Example: `**[TODO] [P2]:** Create performance tuning guide`

#### `[IN PROGRESS]`
- Actively being worked on
- Code in progress, partial implementation
- Example: `**[IN PROGRESS] [P0]:** Implement DMA descriptor validation`

#### `[BLOCKED]`
- Cannot proceed due to dependencies
- Waiting on other teams, external factors, or decisions
- Example: `**[BLOCKED] [P1]:** Add Windows driver (waiting on UAPI freeze)`

## Priority Guidelines

### P0 - Critical (Release Blockers)
**Criteria:**
- Blocks current release or critical functionality
- Security or correctness issues
- Hardware compatibility requirements
- API stability requirements

**Examples:**
- Fix CI test failures
- Update spec before hardware integration
- Resolve critical bugs in production code

**Effort:** Usually < 1 week total
**Timeline:** Complete within current sprint

### P1 - High Priority (Next Sprint)
**Criteria:**
- Significant user/developer experience improvements
- Important but not blocking features
- Infrastructure improvements with high ROI
- Cross-cutting concerns (security, performance)

**Examples:**
- Add comprehensive documentation
- Improve build system reliability
- Enhance testing coverage
- FreeBSD driver parity

**Effort:** 1-4 weeks total
**Timeline:** Complete within 1-2 sprints

### P2 - Medium Priority (Backlog)
**Criteria:**
- Nice-to-have improvements
- Future features not immediately needed
- Technical debt reduction
- Advanced optimizations

**Examples:**
- Performance tuning guides
- Additional platform support
- Extended testing coverage
- Advanced rendering features

**Effort:** 1-12 weeks total
**Timeline:** When resources available

### P3 - Low Priority (Future/Icebox)
**Criteria:**
- Research projects
- Very advanced features
- Nice-to-have enhancements
- Speculative work

**Examples:**
- macOS driver support
- Advanced formal verification
- Research rendering techniques

**Effort:** Months to years
**Timeline:** Future releases only

## Adding New TODO Items

### Step 1: Choose Appropriate Tracker
Find the most specific tracker for your item:

| Area | Tracker File |
|------|--------------|
| RTL/Hardware | `todo_rtl_*.md`, `todo_fpga.md` |
| Drivers | `todo_drivers.md`, `todo_mesa_drivers.md` |
| Documentation | `todo_documentation.md` |
| Build/CI | `todo_build_tooling.md` |
| Testing | `todo_testing_ci.md` |
| Performance | `todo_performance.md` |

### Step 2: Check for Duplicates
```bash
# Search for similar items
grep -r "similar task" docs/todo/

# Check master index
grep -i "keyword" docs/TODO_MASTER_INDEX.md
```

### Step 3: Format the Item
```markdown
- **[TODO] [P2]:** [Clear, actionable description]
  - **Effort:** [X] days
  - **Priority:** P2 - [Brief justification]
  - **Dependencies:** [What must be done first]
  - **Validation:** [How to verify completion]
  - **Deliverable:** [Specific output files or results]
  - **Notes:** [Additional context]
```

### Step 4: Update Dependencies
If your item depends on or blocks others:
- Add to `docs/todo/todo_dependency_map.md`
- Update blocking items' status to `[BLOCKED]` if needed

## Updating Existing Items

### Status Changes
```markdown
# Change from TODO to IN PROGRESS
- **[IN PROGRESS] [P1]:** Task description (started 2025-11-26)

# Mark as completed
- **[DONE] [P1]:** Task description (completed 2025-11-26)
```

### Priority Changes
Only change priority with justification:
```markdown
- **[TODO] [P1]:** Task description (promoted from P2 - blocking release)
```

### Content Updates
Keep descriptions current:
```markdown
- **[TODO] [P2]:** Create performance tuning guide (updated: now includes memory usage)
```

## Tracker Maintenance Tasks

### Weekly Tasks
1. **Review priorities**: Ensure P0 items are still critical
2. **Update status**: Mark completed items as `[DONE]`
3. **Check blockers**: See if blocked items can now proceed
4. **Validate estimates**: Update effort estimates based on progress

### Monthly Tasks
1. **Run sweeps**: `python3 scripts/todo_sweep.py`
2. **Check dependencies**: Update `todo_dependency_map.md`
3. **Archive old items**: Move completed items to archive if tracker becomes too long
4. **Rebalance priorities**: Move items up/down based on new information

### Quarterly Tasks
1. **Audit trackers**: Ensure all trackers are still relevant
2. **Split large trackers**: Break up trackers >500 lines
3. **Update master index**: Refresh `TODO_MASTER_INDEX.md`
4. **Review process**: Improve workflow based on experience

## Validation and Automation

### Automated Checks
```bash
# Validate tracker integrity
python3 scripts/todo_sweep.py

# Check for required files
python3 scripts/check_required_files.py

# Find duplicate TODOs
python3 scripts/check_todo_unique.py
```

### Manual Validation
- [ ] All P0 items have owners and timelines
- [ ] No duplicate items across trackers
- [ ] Effort estimates are realistic
- [ ] Dependencies are clearly stated
- [ ] Status tags are consistent

## Best Practices

### Writing Good TODO Items
✅ **Good:**
```
**[TODO] [P1]:** Add input validation for all ioctl parameters
- **Effort:** 2 days
- **Priority:** P1 - Security hardening
- **Dependencies:** UAPI finalized
- **Validation:** All ioctls reject invalid parameters
- **Deliverable:** Updated driver code with validation
```

❌ **Poor:**
```
**[TODO] [P2]:** Improve security
- **Effort:** ??? days
- **Priority:** P2
```

### Avoiding Common Mistakes
1. **Vague descriptions**: "Fix bugs" → "Fix DMA timeout handling"
2. **Missing effort estimates**: Always estimate time
3. **No validation criteria**: How do you know it's done?
4. **Cross-tracker duplicates**: Search before adding
5. **Stale priorities**: Reassess regularly

### Collaboration Guidelines
1. **Discuss major changes**: Talk to team before reprioritizing
2. **Document decisions**: Add notes for priority changes
3. **Share progress**: Update status when starting/completing
4. **Ask for help**: If blocked, seek unblockers

## Tracker File Organization

### File Naming
- `todo_{area}.md` - Area-specific trackers
- `todo_{area}_{subarea}.md` - Sub-area specialization
- `todo_master.md` - Coordination and high-level items

### File Structure
```markdown
# {Area} TODO Tracker

**Last Updated:** YYYY-MM-DD
**Owner:** {Team/Individual}
**Related Trackers:** {Cross-references}

**Session Reference:** See docs/{session_file}.md

---

## Overview
{Brief description of tracker's scope}

**Priority Distribution:**
- **P0:** X items (~X days) - {Description}
- **P1:** X items (~X days) - {Description}
- **P2:** X items (~X days) - {Description}
- **P3:** X items (~X days) - {Description}

---

## P0 - Critical
{Items}

## P1 - High Priority
{Items}

## P2 - Medium Priority
{Items}

## P3 - Low Priority
{Items}

---

## Cross-References
{Links to related trackers/docs}

---

**Document Version:** 1.0
**Created:** YYYY-MM-DD
**Last Updated:** YYYY-MM-DD
```

## Emergency Procedures

### If Tracker Corruption Occurs
1. **Stop all changes**: Don't modify corrupted files
2. **Run diagnostics**: `python3 scripts/todo_sweep.py --verbose`
3. **Restore from backup**: Use git to revert problematic changes
4. **Rebuild manually**: Recreate corrupted trackers from master index

### If Priorities Become Unmanageable
1. **Freeze new items**: Temporarily stop adding TODOs
2. **Audit existing**: Review and reprioritize current items
3. **Split trackers**: Break large trackers into focused ones
4. **Get team consensus**: Discuss priority changes as a group

## Getting Help

### Resources
- **Master Index**: `docs/TODO_MASTER_INDEX.md`
- **Dependency Map**: `docs/todo/todo_dependency_map.md`
- **Quick Start**: `docs/TODO_README.md`
- **Scripts**: `scripts/todo_sweep.py`, `scripts/check_required_files.py`

### When to Ask for Help
- Unsure about priority level
- Item spans multiple trackers
- Dependencies are complex
- Need validation criteria

### Escalation Path
1. **Team discussion**: Bring up in standup/meeting
2. **Maintainer review**: For priority or structural changes
3. **Architecture decision**: For major scope changes

---

**Document Version:** 1.0
**Last Updated:** 2025-11-26
**Related Documents:**
- `docs/TODO_README.md` - Quick start guide
- `docs/TODO_MASTER_INDEX.md` - Complete tracker reference
- `docs/todo/todo_dependency_map.md` - Cross-tracker dependencies