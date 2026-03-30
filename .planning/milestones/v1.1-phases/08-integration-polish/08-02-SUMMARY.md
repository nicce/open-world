---
phase: 08-integration-polish
plan: 02
subsystem: ui
tags: [godot, gdscript, hud, inventory, popup, viewport-clamping]

# Dependency graph
requires:
  - phase: 08-01
    provides: hud_strip.gd with set_inventory and set_player methods, and viewport-safe popup in HudStrip
provides:
  - world.gd wires hud_strip with player and inventory references so Drop and Unequip actions are functional
  - inventory_ui.gd popup call is viewport-safe using clamped positioning algorithm
affects:
  - 08-03

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Viewport-safe popup positioning: clamp pos using get_visible_rect().size and get_contents_minimum_size() with fallback"
    - "world.gd as single wiring point: all set_* calls for UI nodes live in _ready()"

key-files:
  created: []
  modified:
    - scripts/world.gd
    - scripts/inventory_ui.gd

key-decisions:
  - "world.gd is the single wiring point for all scene-graph injection — both hud_strip and inventory_ui receive player and inventory refs from _ready()"
  - "Viewport-safe clamping uses get_contents_minimum_size() with Vector2(120.0, 60.0) fallback for zero-size guard before popup() call"

patterns-established:
  - "Popup safety pattern: always clamp mouse position against viewport rect before calling PopupMenu.popup()"

requirements-completed:
  - CTXMENU-03

# Metrics
duration: 2min
completed: 2026-03-27
---

# Phase 08 Plan 02: HudStrip Wiring and InventoryUI Viewport-Safe Popup Summary

**world.gd wires hud_strip with player and inventory refs; InventoryUI popup replaced with viewport-clamped algorithm preventing off-screen overflow**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-27T09:19:57Z
- **Completed:** 2026-03-27T09:21:14Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- HudStrip now receives `player` and `inventory` injected from `world.gd._ready()`, making Drop (spawns collectable at player position) and Unequip (returns item to bag) actions fully functional
- InventoryUI right-click popup no longer overflows viewport edges — replaced bare `popup(get_mouse_position())` call with clamped algorithm using `get_contents_minimum_size()` and fallback size guard
- All 144 existing unit tests continue passing; lint and format-check clean

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire HudStrip player and inventory in world.gd** - `f135106` (feat)
2. **Task 2: Apply viewport-safe clamping to InventoryUI popup call** - `de50de9` (feat)

**Plan metadata:** (docs commit — see final commit)

## Files Created/Modified

- `scripts/world.gd` - Added `hud_strip.set_inventory(player.inventory)` and `hud_strip.set_player(player)` in `_ready()` after existing `set_equipment_data` call
- `scripts/inventory_ui.gd` - Replaced bare `_popup_menu.popup(Rect2i(get_viewport().get_mouse_position(), Vector2i.ZERO))` with 7-line clamped block

## Decisions Made

- No new decisions — followed the plan exactly as specified. The viewport-safe clamping algorithm was already specified in 08-UI-SPEC.md; this plan applied it to the InventoryUI call site (HudStrip call site was handled in 08-01).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- HudStrip is fully wired: equipment display, context menu, unequip-to-bag, and drop-to-world all functional
- InventoryUI popup is viewport-safe, consistent with HudStrip popup (both now use identical clamping algorithm)
- Ready for 08-03 (final polish and integration verification)

## Self-Check: PASSED

- `scripts/world.gd`: FOUND (contains `hud_strip.set_inventory` and `hud_strip.set_player`)
- `scripts/inventory_ui.gd`: FOUND (contains `clampf(pos.x, 0.0, vp.x - popup_min.x)`)
- `.planning/phases/08-integration-polish/08-02-SUMMARY.md`: FOUND
- Commit `f135106`: FOUND (Task 1)
- Commit `de50de9`: FOUND (Task 2)

---
*Phase: 08-integration-polish*
*Completed: 2026-03-27*
