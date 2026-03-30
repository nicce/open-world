---
phase: 06-equip-unequip-flow
plan: "01"
subsystem: inventory
tags: [godot, gdscript, gut, inventory, equipment, context-menu, tdd]

requires:
  - phase: 05-data-foundation
    provides: EquipmentData resource with equip_weapon/unequip_weapon/equip_tool/unequip_tool, InventoryUI with PopupMenu and MENU_EQUIP stub
provides:
  - Atomic equip/unequip transaction flow in InventoryUI (weapon and tool)
  - set_equipment_data() setter on InventoryUI
  - _do_equip_weapon(), _do_equip_tool(), _do_unequip_weapon(), _do_unequip_tool() private methods
  - player_equipment_data.tres resource file for Player Inspector assignment
  - 8 GUT unit tests covering EQUIP-01 through EQUIP-04
affects:
  - 06-02 — player scene wiring (uses set_equipment_data and player_equipment_data.tres)
  - 07-hud-strip — reads equipment_data.weapon for display
  - 08-runtime-combat — reads equipment_data.weapon for hit() wiring

tech-stack:
  added: []
  patterns:
    - "Atomic equip transaction: inventory.remove() BEFORE equip_weapon(); return displaced item; inventory.insert(displaced) if non-null"
    - "Atomic unequip transaction: inventory.insert(weapon) FIRST; only call unequip_weapon() if remaining == 0 (bag had space)"
    - "Equip guard: if _equipment_data == null or _pending_context_index < 0: return at top of MENU_EQUIP handler"

key-files:
  created:
    - scripts/resources/player_equipment_data.tres
    - tests/unit/test_equip_flow.gd
  modified:
    - scripts/inventory_ui.gd

key-decisions:
  - "Remove-before-equip ordering enforced: inventory.remove() always precedes equip_weapon() to prevent item existing in both bag and slot simultaneously"
  - "Unequip-with-full-bag is a safe no-op: insert() called first; if remaining > 0 the weapon stays equipped without mutation"
  - "Tool equip uses item.category == Item.Category.TOOL check (not class check) because tools extend plain Item, not a subclass"

patterns-established:
  - "Transaction ordering: remove from source BEFORE placing in destination — never mutate destination first"
  - "_do_* private methods for equip/unequip operations, dispatched from MENU_EQUIP handler via type check"

requirements-completed: [EQUIP-01, EQUIP-02, EQUIP-03, EQUIP-04]

duration: 3min
completed: 2026-03-18
---

# Phase 06 Plan 01: Equip/Unequip Flow Summary

**Atomic equip/unequip transaction logic in InventoryUI — remove-before-equip ordering, displaced-weapon-return, and full-bag guard — with 8 GUT unit tests covering EQUIP-01 through EQUIP-04**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-18T13:42:20Z
- **Completed:** 2026-03-18T13:45:05Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Implemented `set_equipment_data()`, `_do_equip_weapon()`, `_do_equip_tool()`, `_do_unequip_weapon()`, `_do_unequip_tool()` in InventoryUI
- Replaced the `MENU_EQUIP: pass` stub with real dispatch logic (weapon vs tool type check)
- Added Equip context menu entry for TOOL category items (was only shown for WeaponItem before)
- Created `player_equipment_data.tres` empty resource for Plan 02 Inspector assignment
- Added 8 GUT tests exercising all four EQUIP requirement invariants, plus the no-dual-ownership invariant

## Task Commits

1. **Task 1: Wave 0 — Create player_equipment_data.tres and test scaffold** - `4f57d15` (test)
2. **Task 2: Implement atomic equip/unequip in InventoryUI (GREEN)** - `4833ccd` (feat)

## Files Created/Modified

- `scripts/resources/player_equipment_data.tres` - Empty EquipmentData resource for Inspector assignment in Plan 02
- `tests/unit/test_equip_flow.gd` - 8 GUT tests for EQUIP-01 through EQUIP-04 transaction invariants
- `scripts/inventory_ui.gd` - Added _equipment_data field, set_equipment_data(), four _do_* methods, MENU_EQUIP dispatch, tool Equip menu entry

## Decisions Made

- Tested the data-layer transaction directly (Inventory + EquipmentData) rather than instantiating the UI scene — cleaner pure-logic GUT tests with no scene tree dependency
- Tool equip uses `item.category == Item.Category.TOOL` instead of a class check because tool items extend plain `Item`, not a dedicated subclass

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02 (player scene wiring) can now assign `player_equipment_data.tres` to the Player node's `equipment_data` export and call `inventory_ui.set_equipment_data(equipment_data)` at runtime
- All four EQUIP requirements verified by unit tests; equip flow is complete and tested

## Self-Check: PASSED

All files and commits verified present.

---
*Phase: 06-equip-unequip-flow*
*Completed: 2026-03-18*
