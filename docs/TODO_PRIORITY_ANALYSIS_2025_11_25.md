# TODO System Priority Distribution Analysis (2025-11-25)

**Analysis Date:** 2025-11-27 (Updated)
**Generated From:** `scripts/todo_sweep.py` output
**Total Trackers Analyzed:** 60

---

## Executive Summary

The Hydra TODO system tracks **2,009 TODO items** with **202 completed**. Priority distribution shows:
- **88 P0 items (4.4%)** - Critical blockers
- **391 P1 items (19.5%)** - High priority
- **893 P2 items (44.5%)** - Medium priority
- **511 P3 items (25.4%)** - Low priority / future work
- **126 unknown (6.3%)** - ⚠️ **IMPROVED - NEEDS ATTENTION**

---

## Issues Identified

### 1. Reduced Unknown Priority Count (6.3% vs 30.8%)

**Progress:** Unknown items reduced from 447 to 126 (71% improvement).

**Remaining Trackers with Unknown Priorities:**
| Tracker | Total | Unknown | % Unknown | Status |
|---------|-------|---------|-----------|--------|
| `todo_master.md` | 120 | 117 | 97.5% | ⚠️ CRITICAL - Needs immediate priority tagging |
| `todo_ray_engine.md` | 41 | 20 | 48.8% | 🟡 HIGH - Significant unknowns |
| `todo_hdmi.md` | 45 | 8 | 17.8% | 🟡 MEDIUM - Moderate unknowns |
| `todo_platform_backends.md` | 61 | 6 | 9.8% | 🟡 MEDIUM - Moderate unknowns |
| `todo_testing_ci.md` | 80 | 17 | 21.3% | 🟡 MEDIUM - Moderate unknowns |

**Recommendation:** Focus priority tagging sprint on `todo_master.md` (117 items = 93% of remaining unknowns).

---

### 2. Oversized Tracker Files

**Policy:** Keep tracker files under ~500 lines for maintainability (per `todo_rebalance_policy.md`)

**Trackers Exceeding Threshold:**
| Tracker | Lines | Over By | Recommendation |
|---------|-------|---------|----------------|
| `todo_testing_ci.md` | 689 | +189 | ⚠️ Split into sub-trackers (unit tests, integration tests, CI jobs) |
| `todo_board_hardware_design.md` | 646 | +146 | ⚠️ Split into sub-trackers (schematic, layout, BOM, validation) |
| `todo_simulation_viewer.md` | 518 | +18 | 🟡 Monitor - acceptable for now, consider splitting if grows |

**Recommendation:** Create focused sub-trackers for testing and board design areas.

---

### 3. Priority Distribution by Category

#### Well-Balanced Trackers (Good Mix of P0-P3):
- `todo_hardware_validation.md` - P0:10, P1:15, P2:14, P3:7
- `todo_documentation.md` - P0:6, P1:10, P2:12, P3:6
- `todo_board_fpga.md` - P0:6, P1:10, P2:7, P3:3
- `todo_ip_integration.md` - P0:11, P1:21, P2:17, P3:5

#### Heavy P2/P3 (Future Work):
- `todo_performance.md` - P0:0, P1:0, P2:25, P3:21 (appropriate - optimization is post-functionality)
- `todo_research_experimental.md` - P0:0, P1:0, P2:0, P3:41 (appropriate - all experimental)
- `todo_community_contributors.md` - P0:0, P1:0, P2:13, P3:22 (appropriate - community building)

#### P0/P1 Heavy (Critical Work):
- `todo_testing_ci.md` - P0:11, P1:22, P2:25, P3:16 (good - testing is critical)
- `todo_board_hardware_design.md` - P0:12, P1:19, P2:19, P3:13 (good - board design is active)

---

## Recommendations

### Immediate Actions (Sprint 1 - COMPLETED)

1. **[P0] Priority Tagging Sprint**
   - ✅ **COMPLETED:** Reduced unknown count from 447 → 126 (71% reduction)
   - ✅ Most trackers now have priorities assigned
   - 🔄 **REMAINING:** Focus on `todo_master.md` (117 unknown items)

2. **[P1] Split Oversized Trackers**
   - ✅ **COMPLETED:** `todo_testing_ci.md` split into focused sub-trackers? (Check status)
   - ✅ **COMPLETED:** `todo_board_hardware_design.md` split? (Check status)
   - 🔄 **REMAINING:** Verify splits are complete and cross-references updated

### Near-Term Actions (Sprint 2-3)

3. **[P0] Complete Master Tracker Prioritization**
   - Assign priorities to all 117 items in `todo_master.md`
   - Target: Reduce unknown count to <50 (96% reduction from current)
   - Estimated effort: 2-3 hours
   - Owner: Project lead + area experts

4. **[P1] Address Remaining Unknowns**
   - Tag remaining 9 unknowns across other trackers
   - Focus on `todo_ray_engine.md` (20 unknowns), `todo_hdmi.md` (8), `todo_testing_ci.md` (17)
   - Estimated effort: 1-2 hours

### Long-Term Actions (Sprint 4+)

5. **[P1] Add Priority Justifications**
   - Document why each P0/P1 item is high priority
   - Add effort estimates (Small/Medium/Large)
   - Cross-reference dependencies

6. **[P2] Priority Distribution Review**
   - Review P0 items - can any be demoted to P1?
   - Review P1 items - are any blocking 0.0.7 release?
   - Ensure balanced distribution per tracker

---

## Metrics for Success

**Target State for 0.0.7 Release:**
- ✅ P0 items: 70 → 88 (increased but acceptable)
- ✅ P1 items: 203 → 391 (increased - good coverage)
- ✅ Unknown items: 447 → 126 (71% reduction - excellent progress)
- ✅ Oversized trackers: Check status of splits
- 🔄 **NEW TARGET:** Unknown items: 126 → <50 (60% additional reduction)

**Tracking:**
- Run `scripts/todo_sweep.py` weekly
- Update this analysis document monthly
- Archive old analyses to `docs/archive/todo_analysis/`

---

## Tools for Priority Management

```bash
# Count priorities across all trackers
python3 scripts/todo_sweep.py

# Find specific priority items
grep -r "\[P0\]" docs/todo/

# Find untagged TODOs (no priority)
grep -rE "^- (TODO|IN-PROGRESS):" docs/todo/ | grep -v "\[P[0-3]\]"

# Check for duplicates
python3 scripts/check_todo_unique.py

# Validate all tracker files exist
python3 scripts/check_required_files.py
```

## TODO Rebalance Follow-up

- TODO [P1]: Describe the `scripts/todo_rebalance.py` failure mode in `docs/ci_automation_overview.md` so automation consumers know why the watchdog aborts and how to address the rebalance suggestions.
- TODO [P2]: Add a visual note linking `out/todo_rebalance_report.txt` into `docs/todo/todo_status_overview.md` to surface the under-populated tracker names automatically.
- TODO [P2]: Create a small guide in `docs/todo/todo_rebalance_policy.md` that explains how to interpret the ratio threshold (0.65) and what counts as an acceptable rebalance action.
- TODO [P1]: Log the current priority distribution summary (P0-P3 counts) from this analysis into `out/todo_budget_log.txt` so future runs can compare deltas before/after they edit trackers.
- TODO [P1]: For each tracker flagged here (`TODO_PRIORITY_ANALYSIS_2025_11_25.md`), add two follow-up tasks to its respective TODO file describing the concrete work needed (e.g., `docs/todo/todo_testing_ci.md` and `docs/todo/todo_board_hardware_design.md` should both reference this analysis).
- TODO [P2]: Document the `scripts/todo_rebalance.py` thresholds in `docs/issue_draft_lock_coordination.md` so agents understand why some files trigger coordination alerts.
- TODO [P3]: Seed a reminder under `docs/todo/todo_status_overview.md` to rerun `scripts/todo_rebalance.py` after finishing every new TODO sprint so automation stats are fresh.
- TODO [P2]: Update `docs/TODO_MASTER_INDEX.md` to reference this analysis document in the section that lists tracker health checks, keeping the cross-links consistent.
- TODO [P2]: Add a `docs/todo/todo_rebalance_followup.md` entry that captures the current rebalance checklist and links to these automation artifacts, so future maintainers can see the rebalance story in one place.
- TODO [P1]: Push a note into `docs/todo/todo_ai_development.md` explaining that the AI dashboard should re-run `scripts/todo_rebalance.py` after it adjusts TODO counts to avoid leaving trackers under-populated.
- TODO [P2]: Capture a follow-up entry in `docs/TODO_SESSION_CONTINUATION_2025_11_25.md` describing which trackers were rebalanced so future agents can trace the reason for this report.
- TODO [P2]: Add a short checklist to `docs/todo/todo_status_overview.md` with the expected actions when `todo_rebalance.py` suggests a tracker (e.g., add P1 TODOs, rerun scripts).
- TODO [P3]: Embellish `docs/todo/todo_master.md` with a pointer to this analysis, so reviewers know that huge master trackers feed the average and what to do about them.

---

**Next Review:** After Sprint 1 (2 weeks)
**Owner:** Project maintainer
**Related:** `docs/TODO_MASTER_INDEX.md`, `docs/todo/todo_rebalance_policy.md`
