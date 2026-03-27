---
phase: 08-integration-polish
plan: "01"
subsystem: hud-strip-context-menu
tags: [hud, popup-menu, context-menu, equipment, unequip, drop]
dependency_graph:
  requires: [scripts/resources/equipment_data.gd, scenes/collectable.tscn, scripts/resources/inventory.gd]
  provides: [hud-strip right-click context menu with Unequip and Drop actions]
  affects: [scripts/hud_strip.gd, scenes/hud_strip.tscn]
tech_stack:
  added: []
  patterns: [PopupMenu with id_pressed signal, viewport-clamped popup position, gui_input signal on Panel nodes]
key_files:
  created: [tests/unit/test_hud_strip_context_menu.gd]
  modified: [scripts/hud_strip.gd, scenes/hud_strip.tscn]
decisions:
  - "SlotType enum before consts in class body to satisfy gdlint class-definitions-order rule"
  - "MENU_UNEQUIP=0, MENU_DROP=1 as named const IDs with id_pressed (not index_pressed) to avoid positional shift"
  - "Unequip: insert to bag first, only call unequip_weapon/unequip_tool if remaining==0 (safe no-op when bag full)"
  - "Drop: bypass bag entirely, spawn Collectable at random offset from player position"
  - "Viewport clamping uses get_contents_minimum_size() with Vector2(120,60) fallback for zero-size guard"
metrics:
  duration: "3 minutes"
  completed_date: "2026-03-27"
  tasks_completed: 2
  files_changed: 3
---

# Phase 8 Plan 01: HUD Strip Context Menu Summary

HUD right-click context menu with Unequip and Drop actions using PopupMenu with viewport-clamped positioning.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Unit tests for HUD strip context menu (RED) | e9240db | tests/unit/test_hud_strip_context_menu.gd |
| 2 | Implement HudStrip context menu with Unequip and Drop (GREEN) | 901ae8f | scripts/hud_strip.gd, scenes/hud_strip.tscn |

## What Was Built

Right-clicking an occupied weapon or tool HUD slot now shows a popup menu with "Unequip" and "Drop" options:

- **Unequip**: Inserts item into bag first; if bag is full (`remaining > 0`), item stays equipped (safe no-op)
- **Drop**: Bypasses bag entirely, calls `unequip_weapon()`/`unequip_tool()` and spawns a Collectable at the player position with a random offset (16–32 pixels)
- **Empty slots**: No popup shown (returns early when `item == null`)
- **Popup position**: Viewport-clamped using `clampf` so menu never appears off-screen

Key scene changes to `hud_strip.tscn`:
- Added `PopupMenu` child node directly under root Control
- Changed `mouse_filter` on `WeaponSlot` and `ToolSlot` Panel nodes from `2` (IGNORE) to `0` (STOP) so they receive mouse input
- All parent containers remain at `mouse_filter = 2` per locked decision

## Decisions Made

1. **SlotType enum ordering**: Placed before consts to satisfy gdlint `class-definitions-order` rule (enums before consts)
2. **Named const IDs**: `MENU_UNEQUIP=0`, `MENU_DROP=1` with `id_pressed` signal (not `index_pressed`) — consistent with existing `inventory_ui.gd` pattern
3. **Unequip no-op contract**: `_inventory.insert()` called first; `unequip_weapon()/unequip_tool()` only called when `remaining == 0`
4. **Drop bypasses bag**: No `_inventory.insert()` in drop path per locked Phase 8 decision
5. **Popup size guard**: `get_contents_minimum_size()` returns `Vector2.ZERO` before popup is shown; fallback `Vector2(120, 60)` prevents clamping to wrong position

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed gdlint class-definitions-order violation**
- **Found during:** Task 2 verification (make lint)
- **Issue:** `enum SlotType` placed after `const` declarations violated gdlint ordering rule (enums must precede consts)
- **Fix:** Moved `enum SlotType { NONE, WEAPON, TOOL }` before the `const` block in `hud_strip.gd`
- **Files modified:** scripts/hud_strip.gd
- **Commit:** 901ae8f (fix applied inline before committing Task 2)

## Test Results

All 144 tests passed (7 new HUD strip context menu tests all GREEN):

- `test_menu_unequip_id_is_zero` — PASS
- `test_menu_drop_id_is_one` — PASS
- `test_pending_slot_type_starts_at_none` — PASS
- `test_popup_menu_child_exists` — PASS
- `test_popup_menu_child_is_popup_menu_type` — PASS
- `test_weapon_slot_gui_input_connected` — PASS
- `test_tool_slot_gui_input_connected` — PASS

## Self-Check: PASSED

- tests/unit/test_hud_strip_context_menu.gd: FOUND
- scripts/hud_strip.gd: FOUND
- scenes/hud_strip.tscn: FOUND
- Commit e9240db: FOUND
- Commit 901ae8f: FOUND
