---
phase: 12-autosave-triggers-and-polish
plan: "02"
subsystem: save
tags: [autosave, timer, save-manager, player-state, gdscript]

requires:
  - phase: 12-01
    provides: SaveManager with save_game/load_game API and SAVE_VERSION

provides:
  - SaveManager.autosave_interval_seconds configurable property (default 300s)
  - SaveManager.start_autosave(player) and stop_autosave() API
  - Dead-player guard in SaveManager._should_autosave()
  - world.gd wired to start autosave after load_game in _ready()

affects: [world, save-manager, autosave, campfire-sleep]

tech-stack:
  added: []
  patterns:
    - "Timer as child of autoload singleton for periodic background operations"
    - "Guard function pattern: _should_autosave() centralises skip conditions"

key-files:
  created: []
  modified:
    - scripts/save_manager.gd
    - scripts/world.gd
    - tests/unit/test_save_manager.gd

key-decisions:
  - "Timer added as child of SaveManager autoload — owned by singleton, no scene lifecycle dependency"
  - "start_autosave() called after load_game() in world._ready() to avoid premature timer fire on stale state"
  - "Dead state guard prevents persisting zero-HP / mid-death-animation inconsistent state"

patterns-established:
  - "Autosave guard pattern: _should_autosave() checks player reference and state before every timer tick"

requirements-completed: [TRIG-02]

duration: 2min
completed: 2026-03-31
---

# Phase 12 Plan 02: Autosave Timer and Dead-Player Guard Summary

**Periodic autosave via configurable Timer in SaveManager (default 300s) with dead-player guard that skips saves when Player.current_state == DEAD**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-31T08:16:09Z
- **Completed:** 2026-03-31T08:18:04Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `autosave_interval_seconds` (default 300s) to SaveManager with full start/stop/guard API
- Autosave silently skips when player is DEAD, preventing corrupt save state at time of death
- world.gd wires `start_autosave(player)` as the final call in `_ready()`, after `load_game`
- 5 new unit tests cover interval configuration, null-player guard, dead guard, and alive-player positive case

## Task Commits

Each task was committed atomically:

1. **Task 1: Add autosave timer with configurable interval and dead-player guard** - `bf9ef20` (feat)
2. **Task 2: Wire autosave start in world.gd after scene ready** - `998dadb` (feat)

**Plan metadata:** (docs commit below)

_Note: Task 1 used TDD: RED tests written first (risky/no-assert), then GREEN implementation._

## Files Created/Modified

- `scripts/save_manager.gd` - Added `autosave_interval_seconds`, `_autosave_player`, `_autosave_timer`, `start_autosave()`, `stop_autosave()`, `_should_autosave()`, `_on_autosave_timeout()`
- `scripts/world.gd` - Added `SaveManager.start_autosave(player)` at end of `_ready()`
- `tests/unit/test_save_manager.gd` - Added 5 autosave unit tests

## Decisions Made

- Timer is added as a child of the SaveManager autoload node rather than the scene tree, so it persists across scene reloads without re-wiring.
- `start_autosave()` is called after `load_game()` in `world._ready()` to guarantee the player's state is fully restored before the first autosave could fire.
- `_should_autosave()` checks `Player.PlayerStates.DEAD` only (not HIT), since HIT is transient and the player remains alive — saving during HIT is fine.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - TDD cycle passed GREEN on first implementation attempt.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- TRIG-02 complete: autosave fires every 5 minutes by default, skipping on player death.
- Phase 12 (autosave-triggers-and-polish) is fully complete with both plans executed.
- v1.2 milestone is ready to be reviewed and closed.

---
*Phase: 12-autosave-triggers-and-polish*
*Completed: 2026-03-31*
