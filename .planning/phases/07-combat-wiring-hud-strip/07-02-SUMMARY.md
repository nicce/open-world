---
phase: 07-combat-wiring-hud-strip
plan: "02"
subsystem: ui
tags: [godot, gdscript, hud, equipment, control-nodes, signal]

# Dependency graph
requires:
  - phase: 07-combat-wiring-hud-strip-01
    provides: EquipmentData resource with equipment_changed signal, player.equipment_data field
  - phase: 06-equip-unequip-flow
    provides: Equip/unequip wiring in inventory_ui; equipment_data field on player
provides:
  - HUD strip scene (scenes/hud_strip.tscn) with two 48x48 slots anchored bottom center
  - HUD strip script (scripts/hud_strip.gd) with set_equipment_data() and equipment_changed subscription
  - HudStrip node wired in world.tscn and world.gd _ready()
affects: [phase-08-slot-interaction, any phase that modifies world.tscn CanvasLayer]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "texture-or-label: show TextureRect when item.texture exists, fallback to Label with item.name"
    - "modulate.a dimming: modulate.a=0.4 for empty slot, 1.0 for occupied — zero shader cost"
    - "stylebox duplicate-and-override: duplicate() existing StyleBoxFlat before mutating to avoid shared state"

key-files:
  created:
    - scripts/hud_strip.gd
    - scenes/hud_strip.tscn
  modified:
    - scenes/world.tscn
    - scripts/world.gd

key-decisions:
  - "HudStrip is a sibling of InventoryUI in CanvasLayer (not a child) so it stays visible when inventory is closed"
  - "set_equipment_data() calls _on_equipment_changed() immediately after signal connect to paint initial state"
  - "mouse_filter = MOUSE_FILTER_IGNORE (2) on all HUD nodes to prevent click capture"
  - "StyleBoxFlat duplicated before override to prevent shared-resource mutation across slot panels"

patterns-established:
  - "Slot border: _set_slot_border() duplicates theme stylebox and sets border_width_* to 2 (occupied) or 0 (empty)"
  - "HUD wiring follows world.gd _ready() pattern: set_equipment_data() call after inventory_ui wiring"

requirements-completed: [HUD-01, HUD-02]

# Metrics
duration: 3min
completed: 2026-03-19
---

# Phase 7 Plan 02: HUD Strip Summary

**Always-visible equipment HUD strip with two 48x48 slots (W/T) anchored bottom center, subscribing to equipment_changed signal and showing dimmed empty / gold-bordered occupied states**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-19T09:15:04Z
- **Completed:** 2026-03-19T09:17:32Z
- **Tasks:** 1 of 2 (Task 2 is human-verify checkpoint)
- **Files modified:** 4

## Accomplishments
- Created scripts/hud_strip.gd: extends Control, set_equipment_data() subscribes to equipment_changed, _refresh_slot() implements texture-or-label pattern with modulate.a dimming, _set_slot_border() applies 2px gold border on occupied
- Created scenes/hud_strip.tscn: HudStrip Control anchored bottom center with two VBoxContainers (WeaponSlotGroup, ToolSlotGroup), each containing a 48x48 Panel with StyleBoxFlat dark background, TextureRect, NameLabel, and "W"/"T" slot label
- Wired HudStrip as sibling of InventoryUI in world.tscn CanvasLayer; added hud_strip @onready and set_equipment_data() call in world.gd _ready()
- All 137 unit tests pass, lint clean, format-check clean

## Task Commits

Each task was committed atomically:

1. **Task 1: Create HUD strip scene and script, wire in world** - `c5228f0` (feat)

## Files Created/Modified
- `scripts/hud_strip.gd` - HUD strip Control script: set_equipment_data(), _on_equipment_changed(), _refresh_slot(), _set_slot_border()
- `scenes/hud_strip.tscn` - HUD strip scene: two 48x48 Panel slots anchored bottom center, StyleBoxFlat dark bg, TextureRect + Label per slot
- `scenes/world.tscn` - Added HudStrip node (instance of hud_strip.tscn) as child of CanvasLayer, sibling of InventoryUI
- `scripts/world.gd` - Added hud_strip @onready var and hud_strip.set_equipment_data(player.equipment_data) in _ready()

## Decisions Made
- HudStrip placed as sibling of InventoryUI in CanvasLayer per locked Phase 7 decision — ensures strip remains visible when inventory panel is hidden
- set_equipment_data() immediately calls _on_equipment_changed() to render initial state on scene load
- All HUD Control nodes use mouse_filter = MOUSE_FILTER_IGNORE (2) — HUD is display-only in Phase 7, no click interaction until Phase 8
- StyleBoxFlat duplicated via .duplicate() before property mutation — prevents shared resource modification affecting both slot panels

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Format-check failure on hud_strip.gd**
- **Found during:** Task 1 verification
- **Issue:** gdformat wanted to collapse multi-line _refresh_slot() signature to single line
- **Fix:** Ran gdformat to auto-reformat; verified format-check now passes
- **Files modified:** scripts/hud_strip.gd
- **Verification:** make format-check exits 0
- **Committed in:** c5228f0 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking — format compliance)
**Impact on plan:** Minor reformatting only, no logic change.

## Issues Encountered
None beyond the format-check auto-fix above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- HUD strip complete and wired; awaiting human in-game verification (Task 2 checkpoint)
- After verification approves all 5 requirements (CMBT-03, CMBT-04, CMBT-05, HUD-01, HUD-02), Phase 7 is fully complete
- Phase 8 can wire click interaction on HUD slots for equip/unequip from HUD

---
*Phase: 07-combat-wiring-hud-strip*
*Completed: 2026-03-19*
