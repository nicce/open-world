---
phase: 04-inventory-slot-full-rejection
plan: 01
subsystem: inventory
tags: [gdscript, inventory, signals, tdd, gut]

# Dependency graph
requires:
  - phase: 02-grid-inventory-ui
    provides: insert_rejected signal and HUD label wiring in world.gd
  - phase: 03-item-management
    provides: inventory.gd insert() implementation with slot and weight logic
provides:
  - insert_rejected emitted on slot-full failures (not just weight-blocked)
  - unit test confirming INV-02 gap closure
affects: [future inventory plans, any feature using insert_rejected signal]

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - tests/unit/test_inventory.gd
    - scripts/resources/inventory.gd

key-decisions:
  - "Remove weight_budget guard from elif branch — any complete failure (inserted == 0, remaining > 0) emits insert_rejected unconditionally; weight check was over-engineering that missed slot-full path"

patterns-established: []

requirements-completed: [INV-02]

# Metrics
duration: 2min
completed: 2026-03-13
---

# Phase 04 Plan 01: Inventory Slot-Full Rejection Summary

**insert_rejected now fires on slot-full failures via a one-line elif simplification in inventory.gd:insert(), closing INV-02 so the HUD rejection label appears when all slots are occupied**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-13T10:02:43Z
- **Completed:** 2026-03-13T10:04:56Z
- **Tasks:** 2 (TDD: RED + GREEN)
- **Files modified:** 2

## Accomplishments

- Added failing test `test_insert_rejected_emitted_when_slots_full_but_weight_allows` that confirmed INV-02 gap (RED)
- Removed redundant `weight_budget <= 0` guard so any complete insert failure emits `insert_rejected` (GREEN)
- All 88 unit tests pass; weight-blocked and slot-full rejection paths both covered

## Task Commits

Each task was committed atomically:

1. **Task 1: RED — add failing test for slot-full rejection** - `1f807d6` (test)
2. **Task 2: GREEN — simplify insert() rejection branch** - `7da2a8d` (fix)

_Note: TDD tasks — test commit (RED) then fix commit (GREEN)_

## Files Created/Modified

- `tests/unit/test_inventory.gd` - Added `test_insert_rejected_emitted_when_slots_full_but_weight_allows`
- `scripts/resources/inventory.gd` - Removed 3-line weight_budget guard; elif now emits insert_rejected unconditionally

## Decisions Made

- Remove weight_budget guard from elif branch: the guard was over-engineering. The elif is only reached when `inserted == 0` (nothing went in), which means the insert failed completely whether due to weight or slot exhaustion. Emitting insert_rejected unconditionally in this branch is correct by construction.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- INV-02 closed; HUD rejection label now shows for both slot-full and weight-blocked cases
- No blockers or concerns

---
*Phase: 04-inventory-slot-full-rejection*
*Completed: 2026-03-13*

## Self-Check: PASSED

- FOUND: `.planning/phases/04-inventory-slot-full-rejection/04-01-SUMMARY.md`
- FOUND: `tests/unit/test_inventory.gd`
- FOUND: `scripts/resources/inventory.gd`
- FOUND: commit `1f807d6` (test RED)
- FOUND: commit `7da2a8d` (fix GREEN)
