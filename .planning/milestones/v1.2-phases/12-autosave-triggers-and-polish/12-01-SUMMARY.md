---
phase: 12-autosave-triggers-and-polish
plan: "01"
subsystem: save
tags: [gdscript, save-manager, campfire, versioning, json]

# Dependency graph
requires:
  - phase: 11-full-round-trip-inventory-and-equipment
    provides: Player.to_dict/from_dict with inventory and equipment serialization
provides:
  - Version-stamped save files with "version": "1.0" key
  - Campfire sleep button triggers full game save via SaveManager.save_game
affects:
  - 12-02 (future autosave trigger plans building on save infrastructure)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Version constant in save file: SAVE_VERSION injected by save_data() for future migration support"
    - "Sleep-triggers-save: campfire sleep button mirrors save button pattern with push_error on failure"

key-files:
  created: []
  modified:
    - scripts/save_manager.gd
    - scripts/campfire_menu.gd
    - tests/unit/test_save_manager.gd

key-decisions:
  - "Version injected in save_data() rather than save_game() so all save paths (direct and via game) get versioning"
  - "Sleep button implementation mirrors _on_save_button_pressed() pattern exactly for consistency"

patterns-established:
  - "save_data() is the single point where version is stamped — callers need no awareness of versioning"

requirements-completed: [TRIG-01, TRIG-03]

# Metrics
duration: 10min
completed: 2026-03-31
---

# Phase 12 Plan 01: Autosave Triggers and Polish Summary

**Version-stamped save files (SAVE_VERSION "1.0" injected on every write) and campfire sleep button wired to SaveManager.save_game**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-31T08:15:00Z
- **Completed:** 2026-03-31T08:25:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- SaveManager now stamps every save with `"version": "1.0"` via SAVE_VERSION constant in save_data()
- Campfire sleep button replaced Phase 12 placeholder with real SaveManager.save_game(player) call
- Two new unit tests verify version key presence, correct type, and correct value
- 171 tests passing, lint clean, format clean

## Task Commits

Each task was committed atomically:

1. **Task 1: Add SAVE_VERSION constant and inject version key into save output** - `bb52e46` (feat)
2. **Task 2: Wire campfire sleep button to trigger save** - `d5021f4` (feat)

## Files Created/Modified

- `scripts/save_manager.gd` - Added SAVE_VERSION constant and version injection in save_data()
- `scripts/campfire_menu.gd` - Replaced placeholder print with SaveManager.save_game call and error handling
- `tests/unit/test_save_manager.gd` - Added test_save_includes_version and test_save_version_is_string

## Decisions Made

- Version is injected in `save_data()` rather than `save_game()` so that any direct caller of save_data also gets versioning automatically — single responsibility, single point of truth.
- Sleep button implementation mirrors the existing `_on_save_button_pressed()` pattern exactly (guard on player, save, push_error on failure, close menu) for code consistency.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None — all functionality is fully wired.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Save files now contain version key, ready for future migration support
- Both campfire triggers (Save button and Sleep button) call SaveManager.save_game
- Ready for phase 12-02 if applicable

---
*Phase: 12-autosave-triggers-and-polish*
*Completed: 2026-03-31*
