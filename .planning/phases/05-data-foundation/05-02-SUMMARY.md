---
phase: 05-data-foundation
plan: "02"
subsystem: ui
tags: [gdscript, inventory, popup-menu, signal, tdd, gut, context-menu]

# Dependency graph
requires:
  - phase: 05-01
    provides: "EquipmentData Resource for equipment_data export field"
provides:
  - "right_clicked(slot_node) signal on InventorySlotUI panels"
  - "Context-aware PopupMenu in InventoryUI: Equip+Drop for weapons, Consume+Drop for health items"
  - "equipment_data export field on Player node (Phase 6 ready)"
affects:
  - 06-equipment-transactions

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "right_clicked signal emitted from _gui_input on MOUSE_BUTTON_RIGHT press"
    - "PopupMenu with named const IDs (MENU_EQUIP=0, MENU_CONSUME=1, MENU_DROP=2) using id_pressed not index_pressed"
    - "_popup_menu.clear() before every add_item() call prevents stale menu entries"
    - "TDD via GUT: RED commit (failing tests) -> GREEN commit (all tests pass)"

key-files:
  created:
    - tests/unit/test_inventory_slot_ui.gd
    - tests/unit/test_inventory_ui_context_menu.gd
  modified:
    - scripts/inventory_slot_ui.gd
    - scripts/inventory_ui.gd
    - scenes/inventory_ui.tscn
    - scripts/player.gd

key-decisions:
  - "Use named const IDs with id_pressed (not index_pressed) to avoid positional shift when items are conditionally added — MENU_EQUIP/CONSUME/DROP are stable regardless of menu content"
  - "MENU_EQUIP handler is a pass stub — Phase 6 wires the equip flow; only MENU_CONSUME and MENU_DROP are functional"
  - "_popup_menu.hide() on inventory toggle close ensures no orphaned popup remains visible"
  - "_popup_menu.clear() before every add_item() call prevents stale entries from prior right-clicks"

patterns-established:
  - "right-click context menu pattern: emit signal from slot, resolve index in parent, build item-type-aware menu"

requirements-completed:
  - CTXMENU-01
  - CTXMENU-02
  - CTXMENU-04

# Metrics
duration: 10min
completed: "2026-03-18"
---

# Phase 5 Plan 02: Context Menu and Right-Click Signal Summary

**Right-click PopupMenu on bag slots with item-type-aware actions (Equip/Consume/Drop), plus equipment_data export field on Player for Phase 6**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-18T12:30:00Z
- **Completed:** 2026-03-18T12:40:00Z
- **Tasks:** 3 (2 auto TDD + 1 human-verify checkpoint — approved)
- **Files modified:** 4

## Accomplishments

- `right_clicked(slot_node: Panel)` signal added to `InventorySlotUI` alongside existing `slot_clicked`
- `_gui_input` refactored to dispatch both left-click and right-click to their respective signals
- `InventoryUI` wired with `MENU_EQUIP=0`, `MENU_CONSUME=1`, `MENU_DROP=2` const IDs, `PopupMenu` child, `_on_slot_right_clicked`, and `_on_context_menu_id_pressed`
- Inventory close via toggle now also hides any open `PopupMenu`
- `@export var equipment_data: EquipmentData` added to `scripts/player.gd` for Phase 6 Inspector assignment
- 7 new unit tests for slot right-click signal; 9 new unit tests for context menu wiring — all 125 pass

## Task Commits

TDD pattern — RED then GREEN per task:

1. **RED — Task 1 tests (right_clicked signal)** - `a683932` (test)
2. **GREEN — Task 1 implementation** - `2a78d37` (feat)
3. **RED — Task 2 tests (context menu wiring)** - `0508692` (test)
4. **GREEN — Task 2 implementation** - `a547551` (feat)

## Files Created/Modified

- `scripts/inventory_slot_ui.gd` — Added `right_clicked` signal; refactored `_gui_input` for both mouse buttons
- `scripts/inventory_ui.gd` — Added MENU consts, `_pending_context_index`, `@onready _popup_menu`, right-click handler, id_pressed handler, hide-on-close
- `scenes/inventory_ui.tscn` — Added `PopupMenu` child node
- `scripts/player.gd` — Added `@export var equipment_data: EquipmentData`
- `tests/unit/test_inventory_slot_ui.gd` — 7 GUT tests for right_clicked signal behaviour
- `tests/unit/test_inventory_ui_context_menu.gd` — 9 GUT tests for menu consts, PopupMenu child, pending index, slot connections

## Decisions Made

- Named const IDs with `id_pressed` rather than `index_pressed` — positional shift is avoided when weapon vs health item menus have different item counts
- `MENU_EQUIP` is a pass stub — Phase 6 implements the full equip flow; this plan only wires the signal path
- `_popup_menu.clear()` before every `add_item()` — prevents stale entries accumulating on repeated right-clicks
- `get_viewport().get_mouse_position()` cast to `Vector2i` for `popup()` rect — avoids type mismatch

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `right_clicked` signal path is fully wired: slot emits → InventoryUI receives → PopupMenu displays
- `MENU_EQUIP` handler is a pass stub ready for Phase 6 to fill with equip transaction logic
- `equipment_data` export field on Player is visible in the Inspector and ready for Phase 6 assignment
- Task 3 (human verification in Godot) is pending — see checkpoint below

## Human Verification (Task 3)

Approved. Automated checks (lint, format-check, test) all pass. Visual/functional verification confirmed in Godot:
- Right-click weapon slot shows "Equip" + "Drop"
- Right-click health item slot shows "Consume" + "Drop"
- Right-click empty slot shows nothing
- Closing inventory panel dismisses the popup
- Drop via context menu behaves the same as keyboard drop

Note: Inspector "Equipment Data" field could not be confirmed in-editor during this session but the `@export var equipment_data: EquipmentData` line is present in `scripts/player.gd` and will appear in Inspector when the project is opened in Godot.

---
*Phase: 05-data-foundation*
*Completed: 2026-03-18*
