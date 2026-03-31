---
phase: 11-full-round-trip-inventory-and-equipment
plan: "01"
subsystem: player-serialisation
tags: [save-load, inventory, equipment, gdscript]
dependency_graph:
  requires: []
  provides: [SAVE-03]
  affects: [scripts/player.gd, tests/unit/test_player_save_load.gd]
tech_stack:
  added: []
  patterns: [component-serialisation, null-guard, EQUIP-05-invariant]
key_files:
  created: []
  modified:
    - scripts/player.gd
    - tests/unit/test_player_save_load.gd
decisions:
  - "inventory.from_dict() called before equipment_data.from_dict() to preserve EQUIP-05 invariant"
  - "null-guard on equipment_data in both to_dict and from_dict to support test scenes with no equipment set"
metrics:
  duration: "~5 minutes"
  completed: "2026-03-31"
  tasks_completed: 2
  files_modified: 2
requirements: [SAVE-03]
---

# Phase 11 Plan 01: Wire Inventory and Equipment into Player Save/Load Round-Trip Summary

Extends Player.to_dict/from_dict to include inventory and equipment keys so that a full save/load cycle via SaveManager preserves all player-owned items and equipment slots exactly as they were. Completes SAVE-03.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Extend Player.to_dict and from_dict | 4a66ff2 | scripts/player.gd |
| 2 | Add inventory and equipment round-trip tests | 52cb938 | tests/unit/test_player_save_load.gd |

## Decisions Made

1. **EQUIP-05 ordering enforced:** `inventory.from_dict()` is called before `equipment_data.from_dict()` in `from_dict()`. This ensures that when equipment is restored via ItemRegistry lookup, no item ends up in both the bag and equipment slot simultaneously.

2. **Null-guard on equipment_data:** Both `to_dict` and `from_dict` null-guard `equipment_data` so test scenes that instantiate the player without a configured EquipmentData export don't crash.

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

```
make lint     -> Success: no problems found
make format-check -> 31 files would be left unchanged
make test     -> All 169 tests passed (including 3 new round-trip tests)
```

New tests passing:
- test_inventory_round_trip
- test_equipment_round_trip
- test_equip05_invariant_after_load

## Known Stubs

None.

## Self-Check: PASSED

Files created/modified:
- FOUND: /Users/nicce/projects/github.com/nicce/open-world/scripts/player.gd
- FOUND: /Users/nicce/projects/github.com/nicce/open-world/tests/unit/test_player_save_load.gd

Commits verified:
- FOUND: 4a66ff2 (feat(11-01): extend Player.to_dict/from_dict with inventory and equipment)
- FOUND: 52cb938 (test(11-01): add inventory and equipment round-trip tests)
