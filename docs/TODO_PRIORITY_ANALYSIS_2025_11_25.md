# TODO System Priority Distribution Analysis (2025-11-25)

**Analysis Date:** 2025-11-25
**Generated From:** `scripts/todo_sweep.py` output
**Total Trackers Analyzed:** 60

---

## Executive Summary

The Hydra TODO system tracks **1,452 TODO items** with **192 completed**. Priority distribution shows:
- **70 P0 items (4.8%)** - Critical blockers
- **203 P1 items (14.0%)** - High priority
- **396 P2 items (27.3%)** - Medium priority
- **336 P3 items (23.1%)** - Low priority / future work
- **447 unknown (30.8%)** - ⚠️ **NEEDS PRIORITIZATION**

---

## Issues Identified

### 1. High Unknown Priority Count (30.8%)

**Problem:** Nearly 1/3 of TODO items lack explicit priority tags.

**Affected Trackers (>50% unknown):**
| Tracker | Total | Unknown | % Unknown | Action Needed |
|---------|-------|---------|-----------|---------------|
| `todo_dram_axi.md` | 52 | 52 | 100% | ⚠️ HIGH - Add all priorities |
| `todo_hdmi.md` | 38 | 38 | 100% | ⚠️ HIGH - Add all priorities |
| `todo_ray_engine.md` | 38 | 38 | 100% | ⚠️ HIGH - Add all priorities |
| `todo_master.md` | 117 | 117 | 100% | ⚠️ HIGH - Add all priorities |
| `todo_platform_backends.md` | 56 | 55 | 98% | ⚠️ HIGH - Add all priorities |
| `todo_dma_pcie.md` | 48 | 38 | 79% | 🟡 MEDIUM - Review and tag |

**Recommendation:** Schedule priority tagging sprint for these 6 trackers (contributes 358 unknown items = 80% of all unknown).

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

### Immediate Actions (Sprint 1)

1. **[P0] Priority Tagging Sprint**
   - Assign priorities to all items in the 6 trackers with >50% unknown
   - Target: Reduce unknown count from 447 → <100 (78% reduction)
   - Estimated effort: 4-6 hours
   - Owner: Project lead + area experts

2. **[P1] Split Oversized Trackers**
   - Create `todo_testing_unit.md`, `todo_testing_integration.md`, `todo_testing_ci_jobs.md`
   - Create `todo_board_schematic.md`, `todo_board_layout.md`, `todo_board_validation.md`
   - Update master index and cross-references
   - Estimated effort: 2-3 hours

### Near-Term Actions (Sprint 2-3)

3. **[P1] Add Priority Justifications**
   - Document why each P0/P1 item is high priority
   - Add effort estimates (Small/Medium/Large)
   - Cross-reference dependencies

4. **[P2] Priority Distribution Review**
   - Review P0 items - can any be demoted to P1?
   - Review P1 items - are any blocking 0.0.7 release?
   - Ensure balanced distribution per tracker

---

## Metrics for Success

**Target State for 0.0.7 Release:**
- ✅ P0 items: 70 → Complete all
- ✅ P1 items: 203 → Complete 80% (162 items)
- ✅ Unknown items: 447 → <50 (89% reduction)
- ✅ Oversized trackers: 3 → 0 (split into sub-trackers)

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

---

**Next Review:** After Sprint 1 (2 weeks)
**Owner:** Project maintainer
**Related:** `docs/TODO_MASTER_INDEX.md`, `docs/todo/todo_rebalance_policy.md`
