---
phase: 03-item-management
plan: "03"
subsystem: ui
tags: [gdscript, godot, inventory, drop, pickup-hud, collectable, signals]

# Dependency graph
requires:
  - phase: 03-item-management 03-02
    provides: inventory_ui.gd with _use_selected(), set_player(), item_collected signal on player
provides:
  - Q-key drop action mapped in project.godot (physical_keycode=81)
  - _drop_selected() in inventory_ui.gd with capture-before-remove pattern
  - PickupLabel + PickupTimer nodes in world.tscn under CanvasLayer
  - item_collected signal wired from player to HUD in world.gd
affects:
  - future item management phases needing drop or pickup notification patterns

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "capture-before-remove: capture item_ref before inventory.remove() to safely hold reference after last-unit removal"
    - "replace-on-pickup: pickup_timer.start() restarts timer even when running, so rapid pickups show latest item only"
    - "PickupLabel mirrors RejectionLabel pattern: modulate.a=0 start, alpha set to 1 on event, fade tween on timer timeout"

key-files:
  created: []
  modified:
    - project.godot
    - scripts/inventory_ui.gd
    - scripts/world.gd
    - scenes/world.tscn

key-decisions:
  - "capture-before-remove pattern: item_ref captured before inventory.remove() call so the reference is safe even when the slot is cleared on last-unit removal"
  - "COLLECTABLE_SCENE preload at top of inventory_ui.gd keeps scene reference constant and avoids repeated runtime loads"
  - "PickupLabel positioned at bottom-center (anchor_top=1.0) to distinguish from RejectionLabel at top-center"

patterns-established:
  - "HUD notification pattern: Label with modulate.a=0 + sibling Timer (one_shot, wait_time=2.0) + fade tween on timeout — used for both rejection and pickup labels"

requirements-completed: [ITEM-02, ITEM-03]

# Metrics
duration: 5min
completed: 2026-03-11
---

# Phase 3 Plan 03: Item Drop + Pickup HUD Summary

**Q-key drop spawns Collectable nodes near player, and pickup notification label fades in/out mirroring the rejection label pattern**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-11T15:14:16Z
- **Completed:** 2026-03-11T15:19:29Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Registered `drop` input action (Q key, physical_keycode=81) in project.godot
- Implemented `_drop_selected()` in `inventory_ui.gd` with safe capture-before-remove pattern and random-offset collectable spawning
- Added PickupLabel + PickupTimer scene nodes under world.tscn CanvasLayer
- Wired `player.item_collected` signal to `_on_item_collected()` in world.gd showing `+ [Item Name]` notification with replace/restart behavior
- All 8 ITEM-01/02/03 unit tests GREEN, 87/87 total tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Register drop action + _drop_selected() in inventory_ui.gd** - `7add0db` (feat)
2. **Task 2: Add PickupLabel to world.tscn and wire pickup notification in world.gd** - `de953b9` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified
- `project.godot` - Added `drop` input action mapped to Q key (physical_keycode=81)
- `scripts/inventory_ui.gd` - COLLECTABLE_SCENE constant, Q-key handler in _input(), _drop_selected() with capture-before-remove
- `scenes/world.tscn` - PickupLabel (Label, modulate.a=0, bottom-center) + PickupTimer (Timer, one_shot, wait_time=2.0) under CanvasLayer
- `scripts/world.gd` - pickup_label + pickup_timer @onready refs, set_player() call, item_collected signal connected, _on_item_collected() + _on_pickup_timer_timeout() handlers

## Decisions Made
- capture-before-remove: `item_ref` is captured before `_inventory.remove()` so the reference remains valid even when the last unit is removed and `slot.item` becomes null
- PickupLabel placed at bottom-center (anchor_top/bottom=1.0, offset_top=-80, offset_bottom=-40) to distinguish visually from RejectionLabel at top-center
- COLLECTABLE_SCENE preloaded as class constant for efficiency — no runtime path lookups per drop

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- ITEM-02 (drop) and ITEM-03 (pickup HUD) are fully implemented and tested
- Phase 3 item management feature set is complete: slot selection (02-01), item use + rejection HUD (02-02/03-02), item drop + pickup notification (03-03)
- All 87 unit tests pass with zero regressions

---
*Phase: 03-item-management*
*Completed: 2026-03-11*
