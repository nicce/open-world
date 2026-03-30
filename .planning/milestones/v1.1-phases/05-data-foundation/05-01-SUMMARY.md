---
phase: 05-data-foundation
plan: "01"
subsystem: inventory
tags: [gdscript, resource, equipment, signal, tdd, gut]

# Dependency graph
requires: []
provides:
  - "EquipmentData Resource with weapon and tool slots, equip/unequip API, equipment_changed signal"
affects:
  - 06-equipment-transactions
  - 07-hud-strip

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Resource subclass with typed @export fields and signal-after-mutate pattern"
    - "TDD via GUT: RED commit (parse-error failures) -> GREEN commit (all tests pass)"

key-files:
  created:
    - scripts/resources/equipment_data.gd
    - tests/unit/test_equipment_data.gd
  modified: []

key-decisions:
  - "Mutate field first, then emit equipment_changed — listeners always read the updated value"
  - "Return displaced item from equip methods (not void) so Phase 6 can implement atomic bag-slot swaps without data loss"
  - "unequip on empty slot still emits equipment_changed — consistent contract, callers need not guard"

patterns-established:
  - "equip/unequip pattern: store previous, assign new, emit signal, return previous"

requirements-completed:
  - EQUIP-05

# Metrics
duration: 2min
completed: "2026-03-18"
---

# Phase 5 Plan 01: EquipmentData Resource Summary

**EquipmentData Resource with typed weapon/tool slots, displaced-item return contract, and equipment_changed signal — pure Resource testable without scene tree**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-18T12:23:46Z
- **Completed:** 2026-03-18T12:25:39Z
- **Tasks:** 2 (RED + GREEN)
- **Files modified:** 2

## Accomplishments

- `EquipmentData` Resource with `weapon: WeaponItem` and `tool: Item` typed export fields
- `equip_weapon` / `unequip_weapon` return displaced item, emit `equipment_changed` after field mutation
- `equip_tool` / `unequip_tool` mirror weapon behaviour for the tool slot
- 22 GUT unit tests covering all 8 behavior cases; 110 total suite passes with no regressions

## Task Commits

1. **RED — failing tests** - `8be08f8` (test)
2. **GREEN — EquipmentData implementation** - `a993ea0` (feat)

_Note: TDD plan — two atomic commits (test → feat)_

## Files Created/Modified

- `scripts/resources/equipment_data.gd` — EquipmentData Resource with four equip/unequip methods
- `tests/unit/test_equipment_data.gd` — 22 GUT unit tests covering all behavior contracts

## Decisions Made

- Mutate field first, then emit `equipment_changed` — listeners that read the field on signal receive the updated value, not stale state
- Return displaced item from `equip_weapon(item)` so Phase 6 can implement atomic bag-slot swaps: the old weapon is returned to the bag without an intermediate copy
- `unequip_*()` on an empty slot emits the signal and returns null — consistent API, callers need not guard against no-op

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `EquipmentData` API is stable and fully tested — Phase 6 can call `equip_weapon` / `unequip_weapon` atomically
- No blockers for Phase 6 (equipment transactions) or Phase 7 (HUD strip reads `equipment_data.weapon`)

---
*Phase: 05-data-foundation*
*Completed: 2026-03-18*
