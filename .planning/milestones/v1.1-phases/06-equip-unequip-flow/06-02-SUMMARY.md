---
phase: 06-equip-unequip-flow
plan: "02"
subsystem: ui
tags: [gdscript, inventory, equipment, context-menu, godot]

# Dependency graph
requires:
  - phase: 06-equip-unequip-flow/06-01
    provides: atomic equip/unequip transaction logic in InventoryUI and EquipmentData
provides:
  - runtime wiring of InventoryUI to EquipmentData via world.gd
  - player_equipment_data.tres assigned to Player scene Inspector field
  - fully functional MENU_EQUIP context menu path end-to-end
affects:
  - 07-weapon-attack-wiring
  - 08-unequip-ui

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "world.gd acts as wiring hub — calls set_equipment_data() in _ready() alongside existing set_inventory() and set_player()"
    - "Inspector resource assignment in .tscn via ext_resource entry for shared .tres files"

key-files:
  created: []
  modified:
    - scripts/world.gd
    - scenes/player.tscn

key-decisions:
  - "world.gd is the single wiring point — it calls set_equipment_data(player.equipment_data) immediately after set_player() in _ready(), keeping all scene-graph wiring in one place"

patterns-established:
  - "Wiring pattern: world._ready() is the canonical place to connect UI nodes to player resource nodes"

requirements-completed: [EQUIP-01, EQUIP-02, EQUIP-03, EQUIP-04]

# Metrics
duration: ~10min
completed: 2026-03-19
---

# Phase 6 Plan 02: Equip/Unequip Flow Wiring Summary

**Runtime wiring of InventoryUI to EquipmentData via world.gd, enabling weapon equip and swap from the context menu with human-verified in-game confirmation**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-19
- **Completed:** 2026-03-19
- **Tasks:** 2 (1 auto + 1 human-verify checkpoint)
- **Files modified:** 2

## Accomplishments

- Added `inventory_ui.set_equipment_data(player.equipment_data)` to `world.gd._ready()`, closing the null-reference gap that would have crashed on equip
- Assigned `player_equipment_data.tres` to the Player scene's `equipment_data` Inspector field in `scenes/player.tscn`
- Human confirmed EQUIP-01 (weapon moves from bag to equipment slot) and EQUIP-02 (old weapon returns to bag on swap) work correctly in-game

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire set_equipment_data in world.gd and assign Player Inspector field** - `12bbb15` (feat)
2. **Task 2: Human verify — full equip flow in-game** - checkpoint approved, no commit (verification only)

## Files Created/Modified

- `scripts/world.gd` - Added `inventory_ui.set_equipment_data(player.equipment_data)` call in `_ready()`
- `scenes/player.tscn` - Added `ext_resource` entry for `player_equipment_data.tres` and assigned it to the Player root node's `equipment_data` property

## Decisions Made

- `world.gd` is the single wiring point — all scene-graph wiring (`set_inventory`, `set_player`, `set_equipment_data`) lives in `_ready()` in one place, keeping wiring discoverable and co-located.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The full MENU_EQUIP context menu path is live end-to-end: pick up weapon, open inventory, right-click, select Equip — weapon moves atomically from bag to equipment slot
- Weapon swap (EQUIP-02) verified: equipping a second weapon returns the first to the bag
- Phase 7 (weapon attack wiring) can now read from `player.equipment_data.weapon` at hit time — the slot is populated and stable
- Remaining concern: Phase 7 timing — `HitboxComponent` must read the mutated `attack.damage` value before the hitbox fires; fallback is swapping the entire `Attack` node reference on equip (documented in STATE.md blockers)

---
*Phase: 06-equip-unequip-flow*
*Completed: 2026-03-19*
